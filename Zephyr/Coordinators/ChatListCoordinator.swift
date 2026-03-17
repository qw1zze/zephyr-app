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
        case chat(chatId: String, recipientAddress: String)
    }

    init(container: ServiceContainer) {
        self.container = container
    }

    func navigate(to route: Route) {
        path.append(route)
    }

    lazy var chatListViewModel: ChatListViewModel = ChatListViewModel(container: container, onChatSelected: { [weak self] chatId, recipientAddress in
            self?.navigate(to: .chat(chatId: chatId, recipientAddress: recipientAddress))
        }
    )

    func makeChatListView() -> some View {
        ChatListView(viewModel: chatListViewModel)
    }

    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .chat(let chatId, let recipientAddress):
            ChatView(viewModel: coordinator(for: chatId, recipientAddress: recipientAddress).viewModel)
                .preferredColorScheme(.dark)
        }
    }

    private func coordinator(for chatId: String, recipientAddress: String) -> ChatCoordinator {
        if let existing = chatCoordinators[chatId] {
            return existing
        }
        let coordinator = ChatCoordinator(
            chatId: chatId,
            recipientAddress: recipientAddress,
            container: container
        )
        chatCoordinators[chatId] = coordinator
        return coordinator
    }
}
