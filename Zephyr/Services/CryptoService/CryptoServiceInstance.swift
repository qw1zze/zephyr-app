//
//  CryptoServiceInstance.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation
import web3swift
import Web3Core
internal import CryptoSwift
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

    func computeSharedSecret(myPrivateKey: Data, recipientPublicKey: Data) throws -> Data {
        let privateKey = try secp256k1.KeyAgreement.PrivateKey(rawRepresentation: myPrivateKey)
        let publicKey = try secp256k1.KeyAgreement.PublicKey(rawRepresentation: recipientPublicKey, format: .uncompressed)
        let shared = try privateKey.sharedSecretFromKeyAgreement(with: publicKey)
        return shared.withUnsafeBytes { Data($0) }
    }

    func encrypt(plaintext: Data, sharedSecret: Data) throws -> Data {
        let nonce = AES.randomIV(12)
        let aes = try AES(key: sharedSecret.bytes, blockMode: GCM(iv: nonce, mode: .combined), padding: .noPadding)
        let encrypted = try aes.encrypt(plaintext.bytes)
        var result = Data(nonce)
        result.append(Data(encrypted))
        return result
    }

    func decrypt(ciphertext: Data, sharedSecret: Data) throws -> Data {
        guard ciphertext.count > 12 else { throw CryptoError.invalidCiphertext }
        
        let gcm = GCM(iv: Array(ciphertext.prefix(12)), mode: .combined)
        let aes = try AES(key: sharedSecret.bytes, blockMode: gcm, padding: .noPadding)
        let decrypted = try aes.decrypt(Array(ciphertext.dropFirst(12)))
        return Data(decrypted)
    }
}
