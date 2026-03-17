//
//  StorageService.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation
import os

enum StorageError: Error, LocalizedError {
    case tooLarge
    case notFound
    case emptyCID
    case invalidResponse
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .tooLarge:              
            return "Сообщение слишком большое"
        case .notFound:              
            return "Контент не найден"
        case .emptyCID:              
            return "Получен пустой CID"
        case .invalidResponse:       
            return "Некорректный ответ сервера"
        case .serverError(let code): 
            return "Ошибка сервера: \(code)"
        }
    }
}

private struct UploadResponse: Decodable {
    let cid: String
}

actor StorageServiceInstance: StorageService {
    private let baseURL: URL
    private let httpClient: URLSession
    private let logger: Logger

    init(baseURL: URL, logger: Logger) {
        self.baseURL = baseURL
        self.httpClient = URLSession(configuration: .default)
        self.logger = logger
    }

    func upload(data: Data) async throws -> String {
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/blobs"))
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, response) = try await httpClient.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw StorageError.invalidResponse
        }

        switch http.statusCode {
        case 200, 201:
            let result = try JSONDecoder().decode(UploadResponse.self, from: responseData)
            guard !result.cid.isEmpty else { throw StorageError.emptyCID }
            logger.info("Storage upload OK, CID: \(result.cid)")
            
            return result.cid
        case 413:
            throw StorageError.tooLarge
        default:
            throw StorageError.serverError(http.statusCode)
        }
    }

    func download(cid: String) async throws -> Data {
        let url = baseURL.appendingPathComponent("v1/blobs/\(cid)")
        let (data, response) = try await httpClient.data(from: url)
        
        guard let http = response as? HTTPURLResponse else {
            throw StorageError.invalidResponse
        }
        
        switch http.statusCode {
        case 200:
            return data
        case 404:
            throw StorageError.notFound
        default:
            throw StorageError.serverError(http.statusCode)
        }
    }
}
