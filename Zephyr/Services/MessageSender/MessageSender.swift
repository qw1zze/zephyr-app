//
//  MessageSender.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation
import os
import web3swift
import Web3Core
import CryptoKit
internal import CryptoSwift

struct SentMessage {
    let messageId: String
    let cid:       String
    let timestamp: Date
}

struct DecryptedMessage {
    let messageType: String
    let text: String?
    let imageData: Data?
    let fileName: String?
}

enum MessageSenderError: Error, LocalizedError {
    case recipientKeyNotFound
    case senderAddressCorrupted

    var errorDescription: String? {
        switch self {
        case .recipientKeyNotFound:
            return "Ключ получателя не найден в реестре"
        case .senderAddressCorrupted:
            return "Не удалось прочитать адрес отправителя"
        }
    }
}

actor MessageSender {
    private let keychain: KeychainService
    private let ethereum: BlockchainService
    private let storage: StorageService
    private let relay: RelayService
    private let crypto: CryptoService
    private let logger: Logger
    private var publicKeyCache: [String: Data] = [:]

    init(keychain: KeychainService, ethereum: BlockchainService, storage: StorageService,
         relay: RelayService, crypto: CryptoService, logger: Logger) {
        self.keychain = keychain
        self.ethereum = ethereum
        self.storage = storage
        self.relay = relay
        self.crypto = crypto
        self.logger = logger
    }

    func send(messageId: String, text: String, chatId: String, recipientAddresses: [String]) async throws -> SentMessage {
        let payload = await MessagePayload.makeText(text)
        return try await sendPayload(messageId: messageId, payload: payload, chatId: chatId, recipientAddresses: recipientAddresses)
    }

    func sendImage(messageId: String, imageData: Data, chatId: String, recipientAddresses: [String]) async throws -> SentMessage {
        let payload = await MessagePayload.makeImage(imageData)
        return try await sendPayload(messageId: messageId, payload: payload, chatId: chatId, recipientAddresses: recipientAddresses)
    }

    func sendFile(messageId: String, fileData: Data, fileName: String, chatId: String, recipientAddresses: [String]) async throws -> SentMessage {
        let payload = await MessagePayload.makeFile(fileData, fileName: fileName)
        return try await sendPayload(messageId: messageId, payload: payload, chatId: chatId, recipientAddresses: recipientAddresses)
    }

    func decrypt(envelope: Envelope) async throws -> DecryptedMessage {
        let privateKey = try await keychain.load(key: KeychainKeys.privateKey)
        let ciphertext = try await storage.download(cid: envelope.cid)

        let plainTextData: Data

        if envelope.recipientAddrs.count > 1 {
            let groupKey = Data(SHA256.hash(data: Data(envelope.chatId.utf8)))
            plainTextData = try await crypto.decrypt(ciphertext: ciphertext, sharedSecret: groupKey)
        } else {
            let recipientAddr = envelope.recipientAddrs.first ?? ""
            do {
                let recipientPublicKey = try await resolvePublicKey(address: recipientAddr)
                let sharedSecret = try await crypto.computeSharedSecret(myPrivateKey: privateKey, recipientPublicKey: recipientPublicKey)
                plainTextData = try await crypto.decrypt(ciphertext: ciphertext, sharedSecret: sharedSecret)
            } catch {
                do {
                    let senderPublicKey = try await resolvePublicKey(address: envelope.senderAddr)
                    let sharedSecret = try await crypto.computeSharedSecret(myPrivateKey: privateKey, recipientPublicKey: senderPublicKey)
                    plainTextData = try await crypto.decrypt(ciphertext: ciphertext, sharedSecret: sharedSecret)
                } catch {
                    // Last resort: try group key (for group chat messages recovered with single recipient)
                    let groupKey = Data(SHA256.hash(data: Data(envelope.chatId.utf8)))
                    plainTextData = try await crypto.decrypt(ciphertext: ciphertext, sharedSecret: groupKey)
                }
            }
        }

        logger.info("Decrypted message \(envelope.messageId)")
        return parseDecryptedData(plainTextData)
    }

    private func sendPayload(messageId: String, payload: MessagePayload, chatId: String, recipientAddresses: [String]) async throws -> SentMessage {
        let privateKey = try await keychain.load(key: KeychainKeys.privateKey)
        let addressData = try await keychain.load(key: KeychainKeys.address)

        guard let myAddress = String(data: addressData, encoding: .utf8) else {
            throw MessageSenderError.senderAddressCorrupted
        }

        let sharedSecret: Data
        if recipientAddresses.count > 1 {
            sharedSecret = Data(SHA256.hash(data: Data(chatId.utf8)))
        } else {
            let recipientPublicKey = try await resolvePublicKey(address: recipientAddresses[0])
            sharedSecret = try await crypto.computeSharedSecret(myPrivateKey: privateKey, recipientPublicKey: recipientPublicKey)
        }

        let payloadData = (try? JSONEncoder().encode(payload)) ?? Data()
        let ciphertext = try await crypto.encrypt(plaintext: payloadData, sharedSecret: sharedSecret)

        let cid = try await storage.upload(data: ciphertext)
        logger.info("Uploaded CID \(cid) for message \(messageId)")

        let timestamp = Date()
        let envelope = Envelope(
            messageId: messageId,
            chatId: chatId,
            senderAddr: myAddress,
            recipientAddrs: recipientAddresses,
            cid: cid,
            timestamp: Int64(timestamp.timeIntervalSince1970),
            encryptedPayload: nil,
            signature: nil
        )

        let envelopeHash = await envelope.hash()
        let signature = try signEIP191(message: envelopeHash, privateKey: privateKey)
        let signedEnvelope = await envelope.with(signature: signature)

        try await relay.send(envelope: signedEnvelope)
        logger.info("Sent envelope \(messageId) to relay")

        return SentMessage(messageId: messageId, cid: cid, timestamp: timestamp)
    }

    private func resolvePublicKey(address: String) async throws -> Data {
        if let cached = publicKeyCache[address] { return cached }
        guard let key = try await ethereum.getPublicKey(address: address) else {
            throw MessageSenderError.recipientKeyNotFound
        }
        publicKeyCache[address] = key
        return key
    }

    private func parseDecryptedData(_ data: Data) -> DecryptedMessage {
        if let payload = try? JSONDecoder().decode(MessagePayload.self, from: data) {
            switch payload.type {
            case "image":
                return DecryptedMessage(messageType: "image", text: nil, imageData: payload.imageData, fileName: nil)
            case "file":
                return DecryptedMessage(messageType: "file", text: nil, imageData: payload.fileData, fileName: payload.fileName)
            default:
                return DecryptedMessage(messageType: "text", text: payload.text, imageData: nil, fileName: nil)
            }
        }

        let text = String(data: data, encoding: .utf8) ?? ""
        return DecryptedMessage(messageType: "text", text: text, imageData: nil, fileName: nil)
    }

    private func signEIP191(message: String, privateKey: Data) throws -> String {
        let messageData = message.data(using: .utf8) ?? Data()

        guard let keystore = try? EthereumKeystoreV3(privateKey: privateKey, password: ""),
              let account = keystore.addresses?.first else {
            throw MessageSenderError.senderAddressCorrupted
        }

        guard let sig = try Web3Signer.signPersonalMessage(messageData, keystore: keystore, account: account, password: "") else {
            throw MessageSenderError.senderAddressCorrupted
        }

        return "0x" + sig.toHexString()
    }
}
