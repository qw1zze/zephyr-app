//
//  ChatViewModel.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [MessageModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMoreMessages = true
    @Published private(set) var error: String?
    @Published var inputText = ""

    let chatId: String
    let recipientAddress: String
    let myAddress: String

    private let container: ServiceContainer
    private let pageSize = 30
    private var oldestLoadedDate: Date?

    init(chatId: String, recipientAddress: String, myAddress: String, container: ServiceContainer) {
        self.chatId = chatId
        self.recipientAddress = recipientAddress
        self.myAddress = myAddress
        self.container = container
    }

    func loadInitialMessages() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await container.persistence.fetchMessages(
                chatId: chatId,
                limit: pageSize,
                before: nil
            )
            messages = loaded
            oldestLoadedDate = loaded.first?.timestamp
            hasMoreMessages = loaded.count == pageSize
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadMoreMessages() async {
        guard !isLoadingMore, hasMoreMessages else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let older = try await container.persistence.fetchMessages(
                chatId: chatId,
                limit: pageSize,
                before: oldestLoadedDate
            )
            if older.isEmpty {
                hasMoreMessages = false
                return
            }
            messages = older + messages
            oldestLoadedDate = older.first?.timestamp
            hasMoreMessages = older.count == pageSize
        } catch {
            self.error = error.localizedDescription
        }
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""

        let tempId = UUID().uuidString
        let now = Date()
        let message = MessageModel(
            id: UUID().uuidString,
            chatId: chatId,
            senderAddress: myAddress,
            cid: "",
            timestamp: Date(),
            isDecrypted: true,
            plaintext: text,
            status: "pending"
        )
        messages.append(message)
        
        try? await container.persistence.saveMessage(message)
        try? await container.persistence.updateChatLastMessage(chatId: chatId, text: text, date: now)

        do {
            let sent = try await container.messageSender.send(messageId: tempId, text: text, chatId: chatId, recipientAddress: recipientAddress)

            if let index = messages.firstIndex(where: { $0.id == sent.messageId }) {
                messages[index].cid = sent.cid
                messages[index].status = "sent"
                try? await container.persistence.saveMessage(messages[index])
            }
        } catch {
            messages.removeAll { $0.id == tempId }
            self.error = error.localizedDescription
            inputText = text
        }
    }

    func startRecieve() {
        Task {
            for await envelope in container.envelopePublisher
                .buffer(size: .max, prefetch: .byRequest, whenFull: .dropOldest)
                .values {
                await handleIncomingMessage(envelope)
            }
        }
        
        Task {
            for await status in container.relay.deliveryStatuses {
                await handleDeliveryStatus(status)
            }
        }
    }

    private func handleIncomingMessage(_ envelope: Envelope) async {
        guard envelope.chatId == chatId else { return }

        guard !messages.contains(where: { $0.id == envelope.messageId }) else { return }

        let plaintext: String? = try? await container.messageSender.decrypt(envelope: envelope)

        let message = MessageModel(
            id: envelope.messageId,
            chatId: envelope.chatId,
            senderAddress: envelope.senderAddr,
            cid: envelope.cid,
            timestamp: Date(timeIntervalSince1970: TimeInterval(envelope.timestamp)),
            isDecrypted: plaintext != nil,
            plaintext: plaintext,
            status: "delivered"
        )

        try? await container.persistence.saveMessage(message)
        messages.append(message)

        try? await container.relay.ack(messageId: envelope.messageId)
    }

    private func handleDeliveryStatus(_ status: ServerAckPayload) async {
        guard let index = messages.firstIndex(where: { $0.id == status.messageId }) else { return }

        messages[index].status = status.status == "delivered" ? "delivered" : "sent"
        try? await container.persistence.saveMessage(messages[index])
    }

    func groupedByDay() -> [(date: Date, messages: [MessageModel])] {
        let calendar = Calendar.current
        let grouped = Dictionary(
            grouping: messages,
            by: { calendar.startOfDay(for: $0.timestamp) }
        )
        return grouped
            .sorted { $0.key < $1.key }
            .map { (date: $0.key, messages: $0.value) }
    }
}
