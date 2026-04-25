//
//  ChatListCoordinator.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import SwiftUI
import Combine

@MainActor
final class ChatListCoordinator: ObservableObject {
    @Published var path = NavigationPath()

    private let container: ServiceContainer
    private var chatCoordinators: [String: ChatCoordinator] = [:]

    enum Route: Hashable {
        case chat(chatId: String, recipientAddresses: [String], recipientNickname: String?)
    }

    init(container: ServiceContainer) {
        self.container = container
    }

    func navigate(to route: Route) {
        path.append(route)
    }

    lazy var chatListViewModel: ChatListViewModel = ChatListViewModel(
        container: container,
        onChatSelected: { [weak self] chatId, recipientAddresses, recipientNickname in
            self?.navigate(to: .chat(chatId: chatId, recipientAddresses: recipientAddresses, recipientNickname: recipientNickname))
        }
    )

    func makeChatListView() -> some View {
        ChatListView(viewModel: chatListViewModel)
    }

    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .chat(let chatId, let recipientAddresses, let recipientNickname):
            ChatView(viewModel: coordinator(for: chatId, recipientAddresses: recipientAddresses, recipientNickname: recipientNickname).viewModel)
                .preferredColorScheme(.dark)
        }
    }

    private func coordinator(for chatId: String, recipientAddresses: [String], recipientNickname: String?) -> ChatCoordinator {
        if let existing = chatCoordinators[chatId] {
            return existing
        }
        let coordinator = ChatCoordinator(
            chatId: chatId,
            recipientAddresses: recipientAddresses,
            recipientNickname: recipientNickname,
            container: container
        )
        chatCoordinators[chatId] = coordinator
        return coordinator
    }
}
