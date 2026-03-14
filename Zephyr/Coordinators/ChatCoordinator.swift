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
    private let recipientAddress: String

    private lazy var cachedViewModel: ChatViewModel = buildViewModel()

    var viewModel: ChatViewModel {
        cachedViewModel
    }

    init(chatId: String, recipientAddress: String, container: ServiceContainer) {
        self.chatId = chatId
        self.recipientAddress = recipientAddress
        self.container = container
    }

    private func buildViewModel() -> ChatViewModel {
        let address = (try? container.keychain.load(key: KeychainKeys.address))
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
        return ChatViewModel(
            chatId: chatId,
            recipientAddress: recipientAddress,
            myAddress: address,
            container: container
        )
    }
}
