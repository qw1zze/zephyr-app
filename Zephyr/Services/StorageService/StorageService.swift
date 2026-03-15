//
//  StorageService.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 15/3/26.
//

import Foundation

protocol StorageService: AnyObject {
    func upload(data: Data) async throws -> String
    func download(cid: String) async throws -> Data
}
