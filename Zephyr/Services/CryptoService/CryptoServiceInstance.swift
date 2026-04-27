//
//  CryptoServiceInstance.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation
import CryptoKit
import web3swift
import Web3Core
internal import secp256k1

final class CryptoServiceInstance: CryptoService {

    func generateMnemonic() throws -> [String] {
        guard let phrase = try? BIP39.generateMnemonics(bitsOfEntropy: 128) else {
            throw CryptoError.keyDerivationFailed
        }
        return phrase.components(separatedBy: " ").filter { !$0.isEmpty }
    }

    func deriveWallet(from words: [String]) throws -> WalletKeys {
        let phrase = words.joined(separator: " ")

        guard let seed = BIP39.seedFromMmemonics(phrase, password: "") else {
            throw CryptoError.keyDerivationFailed
        }

        guard let keystore = try? BIP32Keystore(seed: seed, password: "") else {
            throw CryptoError.keyDerivationFailed
        }

        guard let ethereumAddress = keystore.addresses?.first else {
            throw CryptoError.addressDerivationFailed
        }

        guard let privateKey = try? keystore.UNSAFE_getPrivateKeyData(
            password: "",
            account: ethereumAddress
        ) else {
            throw CryptoError.privateKeyExtractionFailed
        }

        guard let publicKey = Utilities.privateToPublic(privateKey, compressed: false) else {
            throw CryptoError.publicKeyDerivationFailed
        }

        return WalletKeys(address: ethereumAddress.address, privateKey: privateKey, publicKey:  publicKey)
    }

    func isValidWord(_ word: String) -> Bool {
        let normalized = word.lowercased().trimmingCharacters(in: .whitespaces)
        guard !normalized.isEmpty else { return false }
        return BIP39Language.english.words.contains(normalized)
    }

    func validateMnemonic(_ words: [String]) throws {
        let phrase = words.joined(separator: " ")
        guard BIP39.seedFromMmemonics(phrase) != nil else {
            throw CryptoError.invalidMnemonic
        }
    }

    func computeSharedSecret(myPrivateKey: Data, recipientPublicKey: Data) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let privateKey = try secp256k1.KeyAgreement.PrivateKey(rawRepresentation: myPrivateKey)
                    let publicKey = try secp256k1.KeyAgreement.PublicKey(rawRepresentation: recipientPublicKey, format: .uncompressed)
                    let shared = try privateKey.sharedSecretFromKeyAgreement(with: publicKey)
                    continuation.resume(returning: shared.withUnsafeBytes { Data($0) })
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func encrypt(plaintext: Data, sharedSecret: Data) async throws -> Data {
        let key = SymmetricKey(data: sharedSecret)
        let sealedBox = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealedBox.combined else {
            throw CryptoError.invalidCiphertext
        }
        return combined
    }

    func decrypt(ciphertext: Data, sharedSecret: Data) async throws -> Data {
        guard ciphertext.count > 12 else { throw CryptoError.invalidCiphertext }
        let key = SymmetricKey(data: sharedSecret)
        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(sealedBox, using: key)
    }
}
