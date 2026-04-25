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
    var id: String
    var recipientAddress: String
    var participantAddresses: [String]
    var createdAt: Date
    var lastMessageDate: Date?
    var lastMessagePreview: String?
    var isRegisteredOnChain: Bool
    var recipientNickname: String?
    var recipientAvatarData: Data?
    var localAlias: String?

    var isGroupChat: Bool {
        participantAddresses.count >= 2
    }

    init(id: String, recipientAddress: String, participantAddresses: [String] = []) {
        self.id = id
        self.recipientAddress = recipientAddress
        self.participantAddresses = participantAddresses
        self.createdAt = Date()
        self.lastMessageDate = nil
        self.lastMessagePreview = nil
        self.isRegisteredOnChain = false
    }
}
