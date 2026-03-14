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

    enum Route: Hashable {
        case chat(chatId: String)
    }

    init(container: ServiceContainer) {
        self.container = container
    }

    func navigate(to route: Route) {
        path.append(route)
    }

    lazy var chatListViewModel: ChatListViewModel = ChatListViewModel(container: container, onChatSelected: { [weak self] chatId in
            self?.navigate(to: .chat(chatId: chatId))
        }
    )

    func makeChatListView() -> some View {
        ChatListView(viewModel: chatListViewModel)
    }

    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .chat(let chatId):
            Text("Chat \(chatId)")
                .preferredColorScheme(.dark)
        }
    }
}
