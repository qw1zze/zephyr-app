//
//  MessageBatchService.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 15/3/26.
//

import Foundation

actor MessageBatchService {
    struct Entry {
        let messageId: String
        let cid: String
        let timestamp: Int64
    }

    private var pending: [String: [Entry]] = [:]
    private let ethereum: BlockchainService
    private let batchSize: Int

    init(ethereum: BlockchainService, batchSize: Int = 3) {
        self.ethereum = ethereum
        self.batchSize = batchSize
    }

    func add(chatId: String, messageId: String, cid: String, timestamp: Int64) async {
        pending[chatId, default: []].append(Entry(messageId: messageId, cid: cid, timestamp: timestamp))
        if pending[chatId]!.count >= batchSize {
            await flush(chatId: chatId)
        }
    }

    private func flush(chatId: String) async {
        guard let entries = pending[chatId], !entries.isEmpty else { return }
        pending[chatId] = []

        let messageIds = entries.map { $0.messageId }
        let cids = entries.map { $0.cid }
        let timestamps = entries.map { $0.timestamp }

        do {
            let txHash = try await ethereum.anchorBatch(chatId: chatId, messageIds: messageIds, cids: cids, timestamps: timestamps)
            print("anchorBatch tx: \(txHash), chatId: \(chatId), count: \(entries.count)")
        } catch {
            print("anchorBatch failed: \(error.localizedDescription)")
            pending[chatId, default: []] = entries + (pending[chatId] ?? [])
        }
    }
}
