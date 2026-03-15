//
//  StorageServiceMock.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation

final class StorageServiceMock: StorageService {
    func upload(data: Data) async throws -> String {
        "QmMock\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
    }

    func download(cid: String) async throws -> Data {
        Data()
    }
}
