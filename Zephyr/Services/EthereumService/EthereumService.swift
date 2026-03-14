//
//  EthereumService.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation

protocol EthereumService: AnyObject {
    func getPublicKey(address: String) async throws -> Data?

    func publishPublicKey(_ publicKey: Data) async throws -> String

    func waitForConfirmation(txHash: String) async throws
}

enum EthereumError: LocalizedError {
    case keystoreCreationFailed
    case contractLoadFailed
    case transactionFailed
    case keychainDataCorrupted
    case contractError(String)

    var errorDescription: String? {
        switch self {
        case .keystoreCreationFailed:    
            return "Ошибка создания keystore для подписи"
        case .contractLoadFailed:        
            return "Ошибка загрузки смарт-контракта"
        case .transactionFailed:         
            return "Транзакция отклонена сетью"
        case .keychainDataCorrupted:     
            return "Ошибка чтения ключей из Keychain"
        case .contractError(let msg):    
            return "Ошибка контракта: \(msg)"
        }
    }
}
