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
    func createChat(id: String, recipientAddress: String) throws -> ChatModel
    func createChat(id: String, participantAddresses: [String]) throws -> ChatModel
    func chat(forAddress address: String) throws -> ChatModel?
    func isChatRegisteredOnChain(chatId: String) throws -> Bool
    func markChatRegistered(chatId: String) throws
    func fetchMessages(chatId: String, limit: Int, before: Date?) async throws -> [MessageModel]
    func messageExists(id: String) throws -> Bool
    func saveMessage(_ message: MessageModel) async throws
    func updateChatLastMessage(chatId: String, text: String, date: Date) async throws
    func deleteChat(chatId: String) throws
    func deleteAllData() throws
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
