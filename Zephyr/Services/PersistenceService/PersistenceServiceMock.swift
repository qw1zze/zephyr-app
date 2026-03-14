//
//  PersistenceServiceMock.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation

final class PersistenceServiceMock: PersistenceService {
    private var chats: [ChatModel] = []

    func fetchChats() throws -> [ChatModel] {
        chats.sorted {
            let lhs = $0.lastMessageDate ?? $0.createdAt
            let rhs = $1.lastMessageDate ?? $1.createdAt
            return lhs > rhs
        }
    }

    func createChat(recipientAddress: String) throws -> ChatModel {
        if let existing = chats.first(where: { $0.recipientAddress == recipientAddress }) {
            return existing
        }
        let chat = ChatModel(recipientAddress: recipientAddress)
        chats.append(chat)
        return chat
    }

    func chat(forAddress address: String) throws -> ChatModel? {
        chats.first { $0.recipientAddress == address }
    }
}
