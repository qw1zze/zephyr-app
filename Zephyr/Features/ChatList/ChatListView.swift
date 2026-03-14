//
//  ChatListView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import SwiftUI

struct ChatListView: View {
    @ObservedObject var viewModel: ChatListViewModel
    @State private var showCreateChat = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.chats.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                chatList
            }
        }
        .navigationTitle("Чаты")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateChat = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $showCreateChat) {
            CreateChatSheet(viewModel: viewModel)
        }
        .task { await viewModel.loadChats() }
        .preferredColorScheme(.dark)
    }

    private var chatList: some View {
        List {
            ForEach(viewModel.chats, id: \.id) { chat in
                ChatRowView(chat: chat) {
                    viewModel.selectChat(chat)
                }
                .listRowBackground(Color.black)
                .listRowSeparatorTint(Color(white: 0.12))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.refresh() }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(Color(white: 0.2))
            Text("Нет чатов. Нажмите + чтобы начать")
                .font(.system(size: 15))
                .foregroundStyle(Color(white: 0.35))
                .multilineTextAlignment(.center)
        }
    }
}
