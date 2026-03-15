//
//  ChatView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var keyboardTrigger: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            messageList(keyboardTrigger: keyboardTrigger)

            InputBarView(text: $viewModel.inputText) {
                Task { await viewModel.sendMessage() }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardTrigger += 1
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardTrigger += 1
        }
        .navigationTitle(formattedAddress(viewModel.recipientAddress))
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                recoveryButton
            }
        }
        .alert(recoveryAlertTitle, isPresented: .constant(isRecoveryAlertPresented)) {
            Button("OK") {
                viewModel.dismissRecoveryAlert()
            }
        }
        .task {
            await viewModel.loadInitialMessages()
            viewModel.startRecieve()
        }
    }

    private var isRecoveryAlertPresented: Bool {
        switch viewModel.recoveryState {
        case .done, .failed:
            return true
        default:
            return false
        }
    }

    private var recoveryAlertTitle: String {
        switch viewModel.recoveryState {
        case .done(let count):
            return count > 0 ? "сообщения восстановлены" : "Новых сообщений не найдено"
        case .failed(let msg):
            return "Ошибка восстановления: \(msg)"
        default:
            return ""
        }
    }

    @ViewBuilder
    private var recoveryButton: some View {
        switch viewModel.recoveryState {
        case .recovering:
            ProgressView()
                .tint(.white)
        default:
            Button {
                viewModel.recoverFromBlockchain()
            } label: {
                Image(systemName: "arrow.clockwise.icloud")
                    .foregroundColor(.white)
            }
        }
    }

    private func messageList(keyboardTrigger: Int) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    } else if viewModel.hasMoreMessages && !viewModel.messages.isEmpty {
                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                Task { await viewModel.loadMoreMessages() }
                            }
                    }

                    ForEach(viewModel.groupedByDay(), id: \.date) { group in
                        dayHeader(for: group.date)
                        ForEach(group.messages, id: \.id) { message in
                            MessageBubbleView(
                                message: message,
                                isOutgoing: message.senderAddress == viewModel.myAddress
                            )
                            .padding(.vertical, 2)
                            .id(message.id)
                        }
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: .infinity)
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            )
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: keyboardTrigger) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onAppear {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    private func dayHeader(for date: Date) -> some View {
        Text(formattedDay(date))
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(.systemGray5).opacity(0.6))
            .clipShape(Capsule())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }

    private func formattedAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }

    private func formattedDay(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Сегодня" }
        if calendar.isDateInYesterday(date) { return "Вчера" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = calendar.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "d MMMM"
            : "d MMMM yyyy"
        return formatter.string(from: date)
    }
}
