//
//  PersistenceServiceMock.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation

final class PersistenceServiceMock: PersistenceService {
    private var chats: [ChatModel] = []
    private var messages: [MessageModel] = []

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
        let chat = ChatModel(id: UUID().uuidString, recipientAddress: recipientAddress)
        chats.append(chat)
        return chat
    }

    func createChat(id: String, recipientAddress: String) throws -> ChatModel {
        if let existing = chats.first(where: { $0.id == id }) {
            return existing
        }
        let chat = ChatModel(id: id, recipientAddress: recipientAddress)
        chats.append(chat)
        return chat
    }

    func createChat(id: String, participantAddresses: [String]) throws -> ChatModel {
        if let existing = chats.first(where: { $0.id == id }) {
            if existing.participantAddresses.count < 2 && participantAddresses.count >= 2 {
                existing.participantAddresses = participantAddresses
                existing.recipientAddress = participantAddresses.first ?? existing.recipientAddress
            }
            
            return existing
        }
        
        let primary = participantAddresses.first ?? ""
        let chat = ChatModel(id: id, recipientAddress: primary, participantAddresses: participantAddresses)
        chats.append(chat)
        
        return chat
    }

    func chat(forAddress address: String) throws -> ChatModel? {
        chats.first { $0.recipientAddress == address }
    }

    func isChatRegisteredOnChain(chatId: String) throws -> Bool {
        chats.first { $0.id == chatId }?.isRegisteredOnChain ?? false
    }

    func markChatRegistered(chatId: String) throws {
        chats.first { $0.id == chatId }?.isRegisteredOnChain = true
    }

    func messageExists(id: String) throws -> Bool {
        messages.contains { $0.id == id }
    }

    func fetchMessages(chatId: String, limit: Int, before: Date?) async throws -> [MessageModel] {
        let filtered = messages
            .filter { $0.chatId == chatId }
            .filter { before == nil || $0.timestamp < before! }
            .sorted { $0.timestamp < $1.timestamp }
        return Array(filtered.suffix(limit))
    }

    func saveMessage(_ message: MessageModel) async throws {
        messages.append(message)
    }

    func updateChatLastMessage(chatId: String, text: String, date: Date) async throws {
        guard let chat = chats.first(where: { $0.id == chatId }) else { return }
        chat.lastMessagePreview = text
        chat.lastMessageDate = date
    }

    func deleteChat(chatId: String) throws {
        chats.removeAll { $0.id == chatId }
        messages.removeAll { $0.chatId == chatId }
    }

    func deleteAllData() throws {
        chats.removeAll()
        messages.removeAll()
    }
}
