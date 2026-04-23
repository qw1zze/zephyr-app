//
//  BlockchainServiceMock.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation

final class BlockchainServiceMock: BlockchainService {

    func getPublicKey(address: String) async throws -> Data? {
        return nil
    }

    func publishPublicKey(_ publicKey: Data) async throws -> String {
        return "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
    }

    func createChat(chatId: String, recipientAddresses: [String]) async throws -> String {
        return "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
    }

    func getChatParticipants(chatId: String) async throws -> [String] {
        return []
    }

    func anchorBatch(chatId: String, messageIds: [String], cids: [String], timestamps: [Int64]) async throws -> String {
        return "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
    }

    func waitForConfirmation(txHash: String) async throws {
        try await Task.sleep(nanoseconds: 60_000_000)
    }

    func getChatCreatedAtBlock(chatId: String) async throws -> UInt64 {
        return 0
    }

    func getAnchoredBatches(chatId: String, fromBlock: UInt64, toBlock: UInt64) async throws -> [BatchAnchoredEvent] {
        return []
    }

    func getLatestBlock() async throws -> UInt64 {
        return 0
    }
    
    func getUserChats(userAddress: String) async throws -> [String] {
        return []
    }
}
