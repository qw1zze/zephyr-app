//
//  ChatModel.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation
import SwiftData

@Model
final class ChatModel {
    var id: UUID
    var recipientAddress: String
    var createdAt: Date
    var lastMessageDate: Date?
    var lastMessagePreview: String?

    init(recipientAddress: String) {
        self.id = UUID()
        self.recipientAddress = recipientAddress
        self.createdAt = Date()
        self.lastMessageDate = nil
        self.lastMessagePreview = nil
    }
}
