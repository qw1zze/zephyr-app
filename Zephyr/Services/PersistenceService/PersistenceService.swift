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
}

enum PersistenceError: LocalizedError {
    case saveFailed(String)
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let msg):  
            return "Ошибка сохранения: \(msg)"
        case .fetchFailed(let msg): 
            return "Ошибка загрузки: \(msg)"
        }
    }
}
