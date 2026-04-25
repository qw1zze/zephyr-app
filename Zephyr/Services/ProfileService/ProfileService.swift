//
//  ProfileService.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 24/4/26.
//

import Foundation
import os

struct ProfileData: Codable {
    let name: String
    let avatar: String
}

enum ProfileError: LocalizedError {
    case invalidResponse
    case emptyName
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:       
            return "Некорректный ответ сервера"
        case .emptyName:             
            return "Никнейм не может быть пустым"
        case .serverError(let code): 
            return "Ошибка сервера: \(code)"
        }
    }
}

protocol ProfileService: AnyObject {
    func saveProfile(name: String, avatar: String) async throws -> String
    func getProfile(cid: String) async throws -> ProfileData
}

actor ProfileServiceInstance: ProfileService {
    private let baseURL: URL
    private let httpClient: URLSession
    private let logger: Logger

    init(baseURL: URL, logger: Logger) {
        self.baseURL = baseURL
        self.httpClient = URLSession(configuration: .default)
        self.logger = logger
    }

    func saveProfile(name: String, avatar: String) async throws -> String {
        guard !name.isEmpty else { throw ProfileError.emptyName }

        var request = URLRequest(url: baseURL.appendingPathComponent("v1/profiles"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["name": name, "avatar": avatar])

        let (data, response) = try await httpClient.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ProfileError.invalidResponse }

        guard http.statusCode == 201 else { throw ProfileError.serverError(http.statusCode) }

        struct CIDResponse: Decodable { let cid: String }
        let result = try JSONDecoder().decode(CIDResponse.self, from: data)
        logger.info("Profile saved, CID: \(result.cid)")
        return result.cid
    }

    func getProfile(cid: String) async throws -> ProfileData {
        let url = baseURL.appendingPathComponent("v1/profiles/\(cid)")
        let (data, response) = try await httpClient.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw ProfileError.invalidResponse }
        guard http.statusCode == 200 else { throw ProfileError.serverError(http.statusCode) }
        return try JSONDecoder().decode(ProfileData.self, from: data)
    }
}

final class ProfileServiceMock: ProfileService {
    func saveProfile(name: String, avatar: String) async throws -> String {
        return "QmMockProfileCID123"
    }

    func getProfile(cid: String) async throws -> ProfileData {
        return ProfileData(name: "Mock User", avatar: "")
    }
}
