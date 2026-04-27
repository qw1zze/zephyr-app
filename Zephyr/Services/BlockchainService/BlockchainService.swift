//
//  BlockchainService.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation
import BigInt

struct BatchAnchoredEvent {
    let sender: String
    let messageIds: [String]
    let cids: [String]
    let timestamps: [Int64]
    let blockNumber: UInt64
}

protocol BlockchainService: AnyObject {
    func getPublicKey(address: String) async throws -> Data?
    func publishPublicKey(_ publicKey: Data) async throws -> String
    func waitForConfirmation(txHash: String) async throws
    func createChat(chatId: String, recipientAddresses: [String]) async throws -> String
    func getChatParticipants(chatId: String) async throws -> [String]
    func anchorBatch(chatId: String, messageIds: [String], cids: [String], timestamps: [Int64]) async throws -> String
    func getChatCreatedAtBlock(chatId: String) async throws -> UInt64
    func getAnchoredBatches(chatId: String, fromBlock: UInt64, toBlock: UInt64) async throws -> [BatchAnchoredEvent]
    func getLatestBlock() async throws -> UInt64
    func getUserChats(userAddress: String) async throws -> [String]
    func setProfileCID(_ cid: String) async throws -> String
    func getProfileCID(address: String) async throws -> String
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
