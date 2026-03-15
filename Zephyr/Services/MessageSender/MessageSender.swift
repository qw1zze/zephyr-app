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
internal import CryptoSwift

struct SentMessage {
    let messageId: String
    let cid:       String
    let timestamp: Date
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

    init(keychain: KeychainService, ethereum: BlockchainService, storage: StorageService,
         relay: RelayService, crypto: CryptoService, logger: Logger) {
        self.keychain = keychain
        self.ethereum = ethereum
        self.storage = storage
        self.relay = relay
        self.crypto = crypto
        self.logger = logger
    }

    func send(messageId: String, text: String, chatId: String, recipientAddress: String) async throws -> SentMessage {
        let privateKey = try await keychain.load(key: KeychainKeys.privateKey)
        let addressData  = try await keychain.load(key: KeychainKeys.address)
        
        guard let myAddress = String(data: addressData, encoding: .utf8) else {
            throw MessageSenderError.senderAddressCorrupted
        }

        guard let recipientPublicKey = try await ethereum.getPublicKey(address: recipientAddress) else {
            throw MessageSenderError.recipientKeyNotFound
        }

        let sharedSecret = try await crypto.computeSharedSecret(myPrivateKey: privateKey, recipientPublicKey: recipientPublicKey)

        let plaintext  = text.data(using: .utf8) ?? Data()
        let ciphertext = try await crypto.encrypt(plaintext: plaintext, sharedSecret: sharedSecret)

        let cid = try await storage.upload(data: ciphertext)
        logger.info("Uploaded CID \(cid) for message \(messageId)")

        let timestamp = Date()
        let envelope = Envelope(
            messageId: messageId,
            chatId: chatId,
            senderAddr: myAddress,
            recipientAddr: recipientAddress,
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

    func decrypt(envelope: Envelope) async throws -> String {
        let privateKey = try await keychain.load(key: KeychainKeys.privateKey)

        let ciphertext = try await storage.download(cid: envelope.cid)

        guard let senderPublicKey = try await ethereum.getPublicKey(address: envelope.recipientAddr) else {
            throw MessageSenderError.recipientKeyNotFound
        }

        var plainTextData = Data()
        do {
            let sharedSecret = try await crypto.computeSharedSecret(myPrivateKey: privateKey, recipientPublicKey: senderPublicKey)
            plainTextData = try await crypto.decrypt(ciphertext: ciphertext, sharedSecret: sharedSecret)
        } catch {
            do {
                guard let senderPublicKey = try await ethereum.getPublicKey(address: envelope.senderAddr) else {
                    throw MessageSenderError.recipientKeyNotFound
                }
                
                let sharedSecret = try await crypto.computeSharedSecret(myPrivateKey: privateKey, recipientPublicKey: senderPublicKey)
                plainTextData = try await crypto.decrypt(ciphertext: ciphertext, sharedSecret: sharedSecret)
            } catch {
                throw MessageSenderError.senderAddressCorrupted
            }
        }
        
        guard let text = String(data: plainTextData, encoding: .utf8) else {
            throw MessageSenderError.senderAddressCorrupted
        }

        logger.info("Decrypted message \(envelope.messageId)")
        return text
    }

    private func signEIP191(message: String, privateKey: Data) throws -> String {
        let messageData = message.data(using: .utf8) ?? Data()
        
        guard let keystore = try? EthereumKeystoreV3(privateKey: privateKey, password: ""), let account  = keystore.addresses?.first else {
            throw MessageSenderError.senderAddressCorrupted
        }
        
        guard let sig = try Web3Signer.signPersonalMessage(messageData, keystore: keystore, account:  account, password: "") else {
            throw MessageSenderError.senderAddressCorrupted
        }
        
        return "0x" + sig.toHexString()
    }
}
