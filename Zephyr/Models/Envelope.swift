//
//  Envelope.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation
internal import CryptoSwift

struct Envelope: Codable, Sendable {
    let messageId: String
    let chatId: String
    let senderAddr: String
    let recipientAddrs: [String]
    let cid: String
    let timestamp: Int64
    let encryptedPayload: String?
    let signature: String?

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case chatId = "chat_id"
        case senderAddr = "sender_addr"
        case recipientAddrs = "recipient_addrs"
        case cid, timestamp, encryptedPayload, signature
    }

    func hash() -> String {
        let combined = messageId + chatId + senderAddr + recipientAddrs.sorted().joined() + cid + String(timestamp)
        return combined.data(using: .utf8)!.sha3(.keccak256).toHexString()
    }

    func with(signature: String) -> Envelope {
        Envelope(
            messageId: messageId,
            chatId: chatId,
            senderAddr: senderAddr,
            recipientAddrs: recipientAddrs,
            cid: cid,
            timestamp: timestamp,
            encryptedPayload: encryptedPayload,
            signature: signature
        )
    }
}
