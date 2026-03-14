//
//  CryptoService.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation

struct WalletKeys {
    let address:    String
    let privateKey: Data
    let publicKey:  Data
}

protocol CryptoService: AnyObject {
    func generateMnemonic() throws -> [String]

    func deriveWallet(from words: [String]) throws -> WalletKeys

    func isValidWord(_ word: String) -> Bool

    func validateMnemonic(_ words: [String]) throws
}

enum CryptoError: LocalizedError {
    case invalidMnemonic
    case keyDerivationFailed
    case addressDerivationFailed
    case privateKeyExtractionFailed
    case publicKeyDerivationFailed

    var errorDescription: String? {
        switch self {
        case .invalidMnemonic:            
            return "Неверная мнемоническая фраза"
        case .keyDerivationFailed:        
            return "Ошибка деривации ключа"
        case .addressDerivationFailed:    
            return "Ошибка деривации адреса"
        case .privateKeyExtractionFailed: 
            return "Ошибка извлечения приватного ключа"
        case .publicKeyDerivationFailed:  
            return "Ошибка деривации публичного ключа"
        }
    }
}
