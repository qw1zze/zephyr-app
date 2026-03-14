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
        modelContainer = try ModelContainer(for: ChatModel.self)
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
        let chat = ChatModel(recipientAddress: recipientAddress)
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
}
