//
//  BlockchainRecoveryService.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 15/3/26.
//

import Foundation
import os

private struct MessageMeta {
    let messageId: String
    let cid: String
    let timestamp: Int64
    let sender: String
    let blockNumber: UInt64
}

actor BlockchainRecoveryService {
    private let ethereum: BlockchainService
    private let persistence: PersistenceService
    private let messageSender: MessageSender
    private let logger: Logger

    private let pageSize: UInt64 = 10000
    private let decryptBatch = 200

    init(ethereum: BlockchainService, persistence: PersistenceService, messageSender: MessageSender, logger: Logger) {
        self.ethereum = ethereum
        self.persistence = persistence
        self.messageSender = messageSender
        self.logger = logger
    }

    func recover(chatId: String, recipientAddress: String) async throws -> [MessageModel] {
        let startBlock = try await ethereum.getChatCreatedAtBlock(chatId: chatId)
        let latestBlock = try await ethereum.getLatestBlock()
        
        guard latestBlock >= startBlock else { return [] }

        logger.info("chatId=\(chatId) startBlock=\(startBlock) latestBlock=\(latestBlock)")

        var allEvents: [BatchAnchoredEvent] = []
        var from = startBlock
        while from <= latestBlock {
            let to = min(from + pageSize - 1, latestBlock)
            let page = try await ethereum.getAnchoredBatches(chatId: chatId, fromBlock: from, toBlock: to)
            allEvents.append(contentsOf: page)
            from = to + 1
        }

        logger.info("fetched \(allEvents.count) batch events")

        let allMessages: [MessageMeta] = allEvents.flatMap { event in
            zip(zip(event.messageIds, event.cids), event.timestamps).map { pair in
                let ((messageId, cid), timestamp) = pair
                return MessageMeta(messageId: messageId, cid: cid, timestamp: timestamp, sender: event.sender, blockNumber: event.blockNumber)
            }
        }

        let ordered = allMessages.sorted { a, b in
            if a.blockNumber != b.blockNumber { return a.blockNumber < b.blockNumber }
            return a.timestamp < b.timestamp
        }

        let newMessages = ordered.filter { msg in
            (try? persistence.messageExists(id: msg.messageId)) == false
        }

        logger.info("\(newMessages.count) new messages to download and decrypt")
        guard !newMessages.isEmpty else { return [] }

        var result: [MessageModel] = []
        for batch in newMessages.chunked(into: decryptBatch) {
            var batchModels = [MessageModel?](repeating: nil, count: batch.count)
            
            await withTaskGroup(of: (Int, MessageModel?).self) { group in
                for (index, meta) in batch.enumerated() {
                    group.addTask { [self] in
                        do {
                            let envelope = Envelope(messageId: meta.messageId, chatId: chatId, senderAddr: meta.sender,
                                                    recipientAddr: recipientAddress, cid: meta.cid, timestamp: meta.timestamp,
                                                    encryptedPayload: nil, signature: nil)
                            
                            let plaintext = try await self.messageSender.decrypt(envelope: envelope)
                            
                            let model = MessageModel(id: meta.messageId, chatId: chatId, senderAddress: meta.sender,
                                                     cid: meta.cid, timestamp: Date(timeIntervalSince1970: TimeInterval(meta.timestamp)),
                                                     isDecrypted: true, plaintext: plaintext, status: "delivered")
                            return (index, model)
                        } catch {
                            self.logger.error("failed msg \(meta.messageId): \(error.localizedDescription)")
                            return (index, nil)
                        }
                    }
                }
                for await (index, model) in group {
                    batchModels[index] = model
                }
            }
            result.append(contentsOf: batchModels.compactMap { $0 })
        }

        logger.info("decrypted \(result.count) messages")
        return result
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
