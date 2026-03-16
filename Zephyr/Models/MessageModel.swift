//
//  MessageModel.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation
import SwiftData

@Model
final class MessageModel {
    var id: String
    var chatId: String
    var senderAddress: String
    var cid: String
    var timestamp: Date
    var isDecrypted: Bool
    var plaintext: String?
    var messageType: String?
    @Attribute(.externalStorage) var imageData: Data?
    var status: String

    init(id: String, chatId: String, senderAddress: String, cid: String, timestamp: Date,
         isDecrypted: Bool, plaintext: String?, messageType: String? = nil,
         imageData: Data? = nil, status: String) {
        self.id = id
        self.chatId = chatId
        self.senderAddress = senderAddress
        self.cid = cid
        self.timestamp = timestamp
        self.isDecrypted = isDecrypted
        self.plaintext = plaintext
        self.messageType = messageType
        self.imageData = imageData
        self.status = status
    }
}

extension MessageModel {
    
    enum MessageStatus {
        case pending
        case sent
        case delivered
    }
    
    var messageStatus: MessageStatus {
        switch status {
        case "sent":
            return .sent
        case "delivered":
            return .delivered
        default:
            return .pending
        }
    }
    
    var isImageMessage: Bool {
        messageType == "image"
    }
}
