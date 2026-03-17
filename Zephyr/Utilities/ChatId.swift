//
//  ChatId.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 15/3/26.
//

import Foundation
internal import CryptoSwift
internal import secp256k1

func generateChatId(address1: String, address2: String) -> String {
    let sorted = [address1.lowercased(), address2.lowercased()].sorted()
    let combined = sorted.joined()
    return combined.data(using: .utf8)!.bytes.sha3(.keccak256).toHexString()
}
