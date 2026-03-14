//
//  KeychainService.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation

protocol KeychainService: AnyObject {
    func save(key: String, data: Data) throws
    func load(key: String) throws -> Data
    func delete(key: String) throws
}

enum KeychainError: LocalizedError {
    case itemNotFound
    case duplicateItem
    case unexpectedData
    case unhandledError(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .itemNotFound:        
            return "Элемент не найден в Keychain"
        case .duplicateItem:       
            return "Элемент уже существует в Keychain"
        case .unexpectedData:      
            return "Неожиданный формат данных"
        case .unhandledError(let s): 
            return "Keychain error: \(s)"
        }
    }
}
