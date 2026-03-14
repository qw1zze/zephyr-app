//
//  EthereumServiceMock.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation

final class EthereumServiceMock: EthereumService {

    func getPublicKey(address: String) async throws -> Data? {
        return nil
    }

    func publishPublicKey(_ publicKey: Data) async throws -> String {
        return "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
    }

    func waitForConfirmation(txHash: String) async throws {
        try await Task.sleep(nanoseconds: 60_000_000)
    }
}
