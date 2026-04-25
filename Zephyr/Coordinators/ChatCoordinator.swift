//
//  ChatCoordinator.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation
import Combine

@MainActor
final class ChatCoordinator: ObservableObject {
    private let container: ServiceContainer
    private let chatId: String
    private let recipientAddresses: [String]
    private let recipientNickname: String?
    private let localAlias: String?
    private let recipientAvatarData: Data?

    private lazy var cachedViewModel: ChatViewModel = buildViewModel()

    var viewModel: ChatViewModel {
        cachedViewModel
    }

    init(chatId: String, recipientAddresses: [String], recipientNickname: String? = nil, localAlias: String? = nil, recipientAvatarData: Data? = nil, container: ServiceContainer) {
        self.chatId = chatId
        self.recipientAddresses = recipientAddresses
        self.recipientNickname = recipientNickname
        self.localAlias = localAlias
        self.recipientAvatarData = recipientAvatarData
        self.container = container
    }

    private func buildViewModel() -> ChatViewModel {
        let address = (try? container.keychain.load(key: KeychainKeys.address))
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
        return ChatViewModel(
            chatId: chatId,
            recipientAddresses: recipientAddresses,
            myAddress: address,
            recipientNickname: recipientNickname,
            localAlias: localAlias,
            recipientAvatarData: recipientAvatarData,
            container: container
        )
    }
}
