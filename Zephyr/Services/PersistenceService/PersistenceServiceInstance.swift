//
//  PersistenceServiceInstance.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation
import SwiftData

final class PersistenceServiceInstance: PersistenceService {
    private let modelContainer: ModelContainer

    private var context: ModelContext {
        modelContainer.mainContext
    }

    init() throws {
        do {
            modelContainer = try ModelContainer(for: ChatModel.self, MessageModel.self)
        } catch {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            if let storeDir = appSupport {
                try? FileManager.default.contentsOfDirectory(at: storeDir, includingPropertiesForKeys: nil)
                    .filter { $0.pathExtension == "store" || $0.lastPathComponent.contains("default") }
                    .forEach { try? FileManager.default.removeItem(at: $0) }
            }
            modelContainer = try ModelContainer(for: ChatModel.self, MessageModel.self)
        }
    }

    func fetchChats() throws -> [ChatModel] {
        let descriptor = FetchDescriptor<ChatModel>(
            sortBy: [
                SortDescriptor(\ChatModel.lastMessageDate, order: .reverse),
                SortDescriptor(\ChatModel.createdAt, order: .reverse)
            ]
        )
        return try context.fetch(descriptor)
    }

    func createChat(recipientAddress: String) throws -> ChatModel {
        if let existing = try chat(forAddress: recipientAddress) {
            return existing
        }
        let chat = ChatModel(id: UUID().uuidString, recipientAddress: recipientAddress)
        context.insert(chat)
        try context.save()
        return chat
    }

    func createChat(id: String, recipientAddress: String) throws -> ChatModel {
        var descriptor = FetchDescriptor<ChatModel>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        let chat = ChatModel(id: id, recipientAddress: recipientAddress)
        context.insert(chat)
        try context.save()

        return chat
    }

    func createChat(id: String, participantAddresses: [String]) throws -> ChatModel {
        var descriptor = FetchDescriptor<ChatModel>(
            predicate: #Predicate { $0.id == id }
        )
        
        descriptor.fetchLimit = 1
        
        if let existing = try context.fetch(descriptor).first {
            if existing.participantAddresses.count < 2 && participantAddresses.count >= 2 {
                existing.participantAddresses = participantAddresses
                existing.recipientAddress = participantAddresses.first ?? existing.recipientAddress
                try context.save()
            }
            return existing
        }

        let primary = participantAddresses.first ?? ""
        let chat = ChatModel(id: id, recipientAddress: primary, participantAddresses: participantAddresses)
        context.insert(chat)
        try context.save()

        return chat
    }

    func chat(forAddress address: String) throws -> ChatModel? {
        var descriptor = FetchDescriptor<ChatModel>(
            predicate: #Predicate { $0.recipientAddress == address }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func isChatRegisteredOnChain(chatId: String) throws -> Bool {
        var descriptor = FetchDescriptor<ChatModel>(
            predicate: #Predicate { $0.id == chatId }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.isRegisteredOnChain ?? false
    }

    func markChatRegistered(chatId: String) throws {
        var descriptor = FetchDescriptor<ChatModel>(
            predicate: #Predicate { $0.id == chatId }
        )
        descriptor.fetchLimit = 1
        guard let chat = try context.fetch(descriptor).first else { return }
        chat.isRegisteredOnChain = true
        try context.save()
    }

    func messageExists(id: String) throws -> Bool {
        var descriptor = FetchDescriptor<MessageModel>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
    }

    func fetchMessages(chatId: String, limit: Int, before: Date?) async throws -> [MessageModel] {
        let messages: [MessageModel]
        if let before {
            var descriptor = FetchDescriptor<MessageModel>(
                predicate: #Predicate { $0.chatId == chatId && $0.timestamp < before },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            descriptor.fetchLimit = limit
            messages = try context.fetch(descriptor)
        } else {
            var descriptor = FetchDescriptor<MessageModel>(
                predicate: #Predicate { $0.chatId == chatId },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            descriptor.fetchLimit = limit
            messages = try context.fetch(descriptor)
        }
        return messages.reversed()
    }

    func saveMessage(_ message: MessageModel) async throws {
        let messageId = message.id
        var descriptor = FetchDescriptor<MessageModel>(
            predicate: #Predicate { $0.id == messageId }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            existing.status = message.status
            existing.plaintext = message.plaintext ?? existing.plaintext
            existing.isDecrypted = message.isDecrypted || existing.isDecrypted
            existing.cid = message.cid.isEmpty ? existing.cid : message.cid
            if let type = message.messageType { existing.messageType = type }
            if let data = message.imageData { existing.imageData = data }
            if let name = message.fileName { existing.fileName = name }
        } else {
            context.insert(message)
        }
        try context.save()
    }

    func updateChatLastMessage(chatId: String, text: String, date: Date) async throws {
        var descriptor = FetchDescriptor<ChatModel>(
            predicate: #Predicate { $0.id == chatId }
        )
        descriptor.fetchLimit = 1
        guard let chat = try context.fetch(descriptor).first else { return }
        chat.lastMessagePreview = text
        chat.lastMessageDate = date
        try context.save()
    }

    func deleteChat(chatId: String) throws {
        let messagesDescriptor = FetchDescriptor<MessageModel>(
            predicate: #Predicate { $0.chatId == chatId }
        )
        let messages = try context.fetch(messagesDescriptor)
        for message in messages {
            context.delete(message)
        }

        var chatDescriptor = FetchDescriptor<ChatModel>(
            predicate: #Predicate { $0.id == chatId }
        )
        chatDescriptor.fetchLimit = 1
        if let chat = try context.fetch(chatDescriptor).first {
            context.delete(chat)
        }

        try context.save()
    }

    func deleteAllData() throws {
        try context.delete(model: MessageModel.self)
        try context.delete(model: ChatModel.self)
        try context.save()
    }
}
