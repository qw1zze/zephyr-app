//
//  KeychainServiceMock.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation

final class KeychainServiceMock: KeychainService {
    func save(key: String, data: Data) throws {
        
    }

    func load(key: String) throws -> Data {
        throw KeychainError.itemNotFound
    }

    func delete(key: String) throws {
        fatalError("")
    }
}
