//
//  CryptoServiceMock.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation

final class CryptoServiceMock: CryptoService {
    func generateMnemonic() throws -> [String] {
        return ["fortune", "cruise", "resemble", "attitude", "ginger", "elevator", "satoshi", "mad", "hamster", "auto", "skate", "captain"]
    }

    func deriveWallet(from words: [String]) throws -> WalletKeys {
        return .init(address: "0xdd6Ec42589282Ae5eC0Def432aC693EF3bE9C49a",
                     privateKey: "fd478cb5589e1a94181abe6c2f1e9bc0017f2f6c17e81b3e4a5f2280928cab91".data(using: .utf8)!,
                     publicKey: "03926414d375519100f6fd55fbe2704736573ec8a4e8367d019d0589ee8d23f054".data(using: .utf8)!
        )
    }

    func isValidWord(_ word: String) -> Bool {
        return true
    }

    func validateMnemonic(_ words: [String]) throws {
        
    }

    func computeSharedSecret(myPrivateKey: Data, recipientPublicKey: Data) async throws -> Data {
        Data(repeating: 0x42, count: 32)
    }

    func encrypt(plaintext: Data, sharedSecret: Data) async throws -> Data {
        plaintext
    }

    func decrypt(ciphertext: Data, sharedSecret: Data) async throws -> Data {
        ciphertext
    }
}
