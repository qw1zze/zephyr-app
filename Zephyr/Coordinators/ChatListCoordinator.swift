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
    @Published private(set) var isRestoringHistory = false

    private let container: ServiceContainer
    private var chatCoordinators: [String: ChatCoordinator] = [:]
    private var cancellables = Set<AnyCancellable>()

    enum Route: Hashable {
        case chat(chatId: String, recipientAddresses: [String], recipientNickname: String?, localAlias: String?, recipientAvatarData: Data?, participantNicknames: [String: String])
    }

    init(container: ServiceContainer) {
        self.container = container
    }

    func navigate(to route: Route) {
        path.append(route)
    }

    lazy var chatListViewModel: ChatListViewModel = {
        let vm = ChatListViewModel(
            container: container,
            onChatSelected: { [weak self] chatId, recipientAddresses, recipientNickname, localAlias, avatarData, participantNicknames in
                self?.navigate(to: .chat(chatId: chatId, recipientAddresses: recipientAddresses, recipientNickname: recipientNickname, localAlias: localAlias, recipientAvatarData: avatarData, participantNicknames: participantNicknames))
            }
        )
        vm.$isRestoringHistory
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in self?.isRestoringHistory = value }
            .store(in: &cancellables)
        return vm
    }()

    func cancelRestore() {
        chatListViewModel.cancelRestore()
    }

    func makeChatListView() -> some View {
        ChatListView(viewModel: chatListViewModel)
    }

    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .chat(let chatId, let recipientAddresses, let recipientNickname, let localAlias, let avatarData, let participantNicknames):
            ChatView(viewModel: coordinator(for: chatId, recipientAddresses: recipientAddresses, recipientNickname: recipientNickname, localAlias: localAlias, recipientAvatarData: avatarData, participantNicknames: participantNicknames).viewModel)
                .preferredColorScheme(.dark)
        }
    }

    private func coordinator(for chatId: String, recipientAddresses: [String], recipientNickname: String?, localAlias: String?, recipientAvatarData: Data?, participantNicknames: [String: String]) -> ChatCoordinator {
        if let existing = chatCoordinators[chatId] {
            return existing
        }
        let coordinator = ChatCoordinator(
            chatId: chatId,
            recipientAddresses: recipientAddresses,
            recipientNickname: recipientNickname,
            localAlias: localAlias,
            recipientAvatarData: recipientAvatarData,
            participantNicknames: participantNicknames,
            container: container
        )
        chatCoordinators[chatId] = coordinator
        return coordinator
    }
}
