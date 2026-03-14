//
//  PersistenceService.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation

protocol PersistenceService: AnyObject {
    func fetchChats() throws -> [ChatModel]
    func createChat(recipientAddress: String) throws -> ChatModel
    func chat(forAddress address: String) throws -> ChatModel?
    func fetchMessages(chatId: String, limit: Int, before: Date?) async throws -> [MessageModel]
    func saveMessage(_ message: MessageModel) async throws
    func updateChatLastMessage(chatId: String, text: String, date: Date) async throws
}

enum PersistenceError: LocalizedError {
    case saveFailed(String)
    case fetchFailed(String)
    case notFound

    var errorDescription: String? {
        switch self {
        case .saveFailed(let msg):  
            return "Ошибка сохранения: \(msg)"
        case .fetchFailed(let msg): 
            return "Ошибка загрузки: \(msg)"
        case .notFound:             
            return "Объект не найден"
        }
    }
}
