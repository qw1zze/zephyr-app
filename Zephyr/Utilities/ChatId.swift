//
//  ChatId.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 15/3/26.
//

import Foundation
internal import CryptoSwift
internal import secp256k1

func generateChatId(addresses: [String]) -> String {
    let sorted = addresses.map { $0.lowercased() }.sorted()
    let combined = sorted.joined()
    return combined.data(using: .utf8)!.bytes.sha3(.keccak256).toHexString()
}

func generateChatId(address1: String, address2: String) -> String {
    generateChatId(addresses: [address1, address2])
}
