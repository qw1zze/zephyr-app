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
    @State private var searchText = ""
    @State private var chatToRename: ChatModel? = nil
    @State private var renameText = ""

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                if viewModel.chats.isEmpty && !viewModel.isLoading {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    chatList
                }
            }
        }
        .navigationTitle("Чаты")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                restoreButton
            }
            ToolbarItem(placement: .primaryAction) {
                createButton
            }
        }
        .sheet(isPresented: $showCreateChat) {
            CreateChatSheet(viewModel: viewModel)
        }
        .task {
            await viewModel.loadChats()
            viewModel.startListen()
        }
        .preferredColorScheme(.dark)
        .alert("Переименовать", isPresented: Binding(
            get: { chatToRename != nil },
            set: { if !$0 { chatToRename = nil } }
        )) {
            TextField("Название", text: $renameText)
            Button("Сохранить") {
                if let chat = chatToRename {
                    viewModel.renameChat(chat, name: renameText)
                }
                chatToRename = nil
            }
            Button("Отмена", role: .cancel) {
                chatToRename = nil
            }
        } message: {
            Text("Введите локальное название для этого чата")
        }
    }
    
    private var restoreButton: some View {
        Button {
            viewModel.restoreAllChats()
        } label: {
            if viewModel.isRestoringHistory {
                ProgressView()
                    .tint(AppTheme.accent)
            } else {
                Image(systemName: "arrow.counterclockwise.icloud")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .disabled(viewModel.isRestoringHistory)
    }
    
    private var createButton: some View {
        Button {
            showCreateChat = true
        } label: {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.textTertiary)
                .font(.system(size: 15))
            TextField("Поиск", text: $searchText)
                .foregroundStyle(AppTheme.textPrimary)
                .font(.system(size: 15))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.radiusInput))
    }

    private var chatList: some View {
        List {
            ForEach(filteredChats, id: \.id) { chat in
                ChatRowView(chat: chat) {
                    viewModel.selectChat(chat)
                }
                .contextMenu {
                    Button {
                        renameText = chat.localAlias ?? ""
                        chatToRename = chat
                    } label: {
                        Label("Переименовать", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        viewModel.deleteChat(chat)
                    } label: {
                        Label("Удалить чат", systemImage: "trash")
                    }
                }
                .listRowBackground(AppTheme.background)
                .listRowSeparatorTint(AppTheme.separator)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.surface)
            Text("Нет чатов. Нажмите + чтобы начать")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var filteredChats: [ChatModel] {
        guard !searchText.isEmpty else { return viewModel.chats }
        return viewModel.chats.filter {
            $0.recipientAddress.localizedCaseInsensitiveContains(searchText)
        }
    }
}
