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
    @Published var inputText = ""
    @Published private(set) var error: String? {
        didSet {
            print(error?.description ?? "")
        }
    }

    enum RecoveryState: Equatable {
        case idle
        case recovering
        case done(newMessages: Int)
        case failed(String)
    }

    enum FileDownloadState: Equatable {
        case loading
        case failed
    }

    @Published private(set) var recoveryState: RecoveryState = .idle
    @Published private(set) var messageDownloadStates: [String: FileDownloadState] = [:]

    let chatId: String
    let recipientAddresses: [String]
    let myAddress: String
    let recipientNickname: String?
    let localAlias: String?
    let recipientAvatarData: Data?
    let participantNicknames: [String: String]

    var recipientAddress: String { recipientAddresses.first ?? "" }
    var isGroupChat: Bool { recipientAddresses.count > 1 }

    private let container: ServiceContainer
    private let pageSize = 30
    private var oldestLoadedDate: Date?
    private var chatIsRegisteredOnChain = false
    private var downloadTasks: [String: Task<Void, Never>] = [:]
    private var recoveryTask: Task<Void, Never>?

    init(chatId: String, recipientAddresses: [String], myAddress: String, recipientNickname: String? = nil, localAlias: String? = nil, recipientAvatarData: Data? = nil, participantNicknames: [String: String] = [:], container: ServiceContainer) {
        self.chatId = chatId
        self.recipientAddresses = recipientAddresses
        self.myAddress = myAddress
        self.recipientNickname = recipientNickname
        self.localAlias = localAlias
        self.recipientAvatarData = recipientAvatarData
        self.participantNicknames = participantNicknames
        self.container = container
    }

    func displayName(for address: String) -> String? {
        if let nickname = participantNicknames[address.lowercased()], !nickname.isEmpty {
            return nickname
        }
        return nil
    }

    func loadInitialMessages() async {
        isLoading = true
        defer { isLoading = false }
        do {
            chatIsRegisteredOnChain = (try? container.persistence.isChatRegisteredOnChain(chatId: chatId)) ?? false
            let loaded = try await container.persistence.fetchMessages(
                chatId: chatId,
                limit: pageSize,
                before: nil
            )
            messages = loaded
            oldestLoadedDate = loaded.first?.timestamp
            hasMoreMessages = loaded.count == pageSize
            markFailedDownloads(in: loaded)
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
            markFailedDownloads(in: older)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""

        let isFirstMessage = !chatIsRegisteredOnChain && messages.isEmpty
        if isFirstMessage {
            chatIsRegisteredOnChain = true
            try? container.persistence.markChatRegistered(chatId: chatId)
            let chatIdCopy = chatId
            let recipientsCopy = recipientAddresses
            Task {
                do {
                    print(try await container.ethereum.createChat(chatId: chatIdCopy, recipientAddresses: recipientsCopy))
                } catch {
                    print(error.localizedDescription)
                }
            }
        }

        let messageId = UUID().uuidString
        let now = Date()
        let message = MessageModel(
            id: messageId,
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
            let sent = try await container.messageSender.send(messageId: messageId, text: text, chatId: chatId, recipientAddresses: recipientAddresses)

            if let index = messages.firstIndex(where: { $0.id == sent.messageId }) {
                messages[index].cid = sent.cid
                messages[index].status = "sent"
                try? await container.persistence.saveMessage(messages[index])
            }

            Task {
                await container.messageBatch.add(chatId: chatId, messageId: sent.messageId, cid: sent.cid, timestamp: Int64(now.timeIntervalSince1970))
            }
        } catch {
            if let index = messages.firstIndex(where: { $0.id == messageId }) {
                messages[index].status = "failed"
                try? await container.persistence.saveMessage(messages[index])
            }
            self.error = error.localizedDescription
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

    func sendImage(_ imageData: Data) async {
        let messageId = UUID().uuidString
        let now = Date()
        let message = MessageModel(id: messageId, chatId: chatId, senderAddress: myAddress, cid: "",
                                   timestamp: now, isDecrypted: true, plaintext: nil, messageType: "image", imageData: imageData, status: "pending")
        messages.append(message)
        
        try? await container.persistence.saveMessage(message)
        try? await container.persistence.updateChatLastMessage(chatId: chatId, text: "📷 Изображение", date: now)

        do {
            let sent = try await container.messageSender.sendImage(messageId: messageId, imageData: imageData, chatId: chatId, recipientAddresses: recipientAddresses)
            if let index = messages.firstIndex(where: { $0.id == sent.messageId }) {
                messages[index].cid = sent.cid
                messages[index].status = "sent"
                try? await container.persistence.saveMessage(messages[index])
            }
            
            Task {
                await container.messageBatch.add(chatId: chatId, messageId: sent.messageId, cid: sent.cid, timestamp: Int64(now.timeIntervalSince1970))
            }
        } catch {
            if let index = messages.firstIndex(where: { $0.id == messageId }) {
                messages[index].status = "failed"
                try? await container.persistence.saveMessage(messages[index])
            }
            self.error = error.localizedDescription
        }
    }

    func sendFile(_ fileData: Data, fileName: String) async {
        let messageId = UUID().uuidString
        let now = Date()
        let message = MessageModel(
            id: messageId,
            chatId: chatId,
            senderAddress: myAddress,
            cid: "",
            timestamp: now,
            isDecrypted: true,
            plaintext: nil,
            messageType: "file",
            imageData: fileData,
            fileName: fileName,
            status: "pending"
        )
        messages.append(message)

        try? await container.persistence.saveMessage(message)
        try? await container.persistence.updateChatLastMessage(chatId: chatId, text: "📎 \(fileName)", date: now)

        do {
            let sent = try await container.messageSender.sendFile(messageId: messageId, fileData: fileData, fileName: fileName, chatId: chatId, recipientAddresses: recipientAddresses)
            if let index = messages.firstIndex(where: { $0.id == sent.messageId }) {
                messages[index].cid = sent.cid
                messages[index].status = "sent"
                try? await container.persistence.saveMessage(messages[index])
            }
            Task {
                await container.messageBatch.add(chatId: chatId, messageId: sent.messageId, cid: sent.cid, timestamp: Int64(now.timeIntervalSince1970))
            }
        } catch {
            if let index = messages.firstIndex(where: { $0.id == messageId }) {
                messages[index].status = "failed"
                try? await container.persistence.saveMessage(messages[index])
            }
            self.error = error.localizedDescription
        }
    }

    func retryMessage(id: String) {
        guard let message = messages.first(where: { $0.id == id && $0.status == "failed" }) else { return }
        Task {
            guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
            messages[index].status = "pending"

            do {
                if message.isImageMessage, let imageData = message.imageData {
                    let sent = try await container.messageSender.sendImage(
                        messageId: message.id, imageData: imageData,
                        chatId: chatId, recipientAddresses: recipientAddresses
                    )
                    if let idx = messages.firstIndex(where: { $0.id == sent.messageId }) {
                        messages[idx].cid = sent.cid
                        messages[idx].status = "sent"
                        try? await container.persistence.saveMessage(messages[idx])
                        await container.messageBatch.add(chatId: chatId, messageId: sent.messageId, cid: sent.cid, timestamp: Int64(message.timestamp.timeIntervalSince1970))
                    }
                } else if message.isFileMessage, let fileData = message.imageData, let fileName = message.fileName {
                    let sent = try await container.messageSender.sendFile(
                        messageId: message.id, fileData: fileData, fileName: fileName,
                        chatId: chatId, recipientAddresses: recipientAddresses
                    )
                    if let idx = messages.firstIndex(where: { $0.id == sent.messageId }) {
                        messages[idx].cid = sent.cid
                        messages[idx].status = "sent"
                        try? await container.persistence.saveMessage(messages[idx])
                        await container.messageBatch.add(chatId: chatId, messageId: sent.messageId, cid: sent.cid, timestamp: Int64(message.timestamp.timeIntervalSince1970))
                    }
                } else if let text = message.plaintext {
                    let sent = try await container.messageSender.send(
                        messageId: message.id, text: text,
                        chatId: chatId, recipientAddresses: recipientAddresses
                    )
                    if let idx = messages.firstIndex(where: { $0.id == sent.messageId }) {
                        messages[idx].cid = sent.cid
                        messages[idx].status = "sent"
                        try? await container.persistence.saveMessage(messages[idx])
                        await container.messageBatch.add(chatId: chatId, messageId: sent.messageId, cid: sent.cid, timestamp: Int64(message.timestamp.timeIntervalSince1970))
                    }
                }
            } catch {
                if let idx = messages.firstIndex(where: { $0.id == id }) {
                    messages[idx].status = "failed"
                    try? await container.persistence.saveMessage(messages[idx])
                }
                self.error = error.localizedDescription
            }
        }
    }

    private func markFailedDownloads(in batch: [MessageModel]) {
        for m in batch where !m.isDecrypted && m.imageData == nil && m.plaintext == nil {
            messageDownloadStates[m.id] = .failed
        }
    }

    private func handleIncomingMessage(_ envelope: Envelope) async {
        guard envelope.chatId == chatId else { return }
        guard (try? container.persistence.isChatBlocked(chatId: chatId)) != true else { return }
        let messageId = envelope.messageId

        if messages.first(where: { $0.id == messageId })?.isDecrypted == true { return }
        if downloadTasks[messageId] != nil { return }

        if !messages.contains(where: { $0.id == messageId }) {
            let placeholder = MessageModel(
                id: messageId, chatId: envelope.chatId, senderAddress: envelope.senderAddr,
                cid: envelope.cid, timestamp: Date(timeIntervalSince1970: TimeInterval(envelope.timestamp)),
                isDecrypted: false, plaintext: nil, messageType: nil, imageData: nil, fileName: nil, status: "delivered"
            )
            try? await container.persistence.saveMessage(placeholder)
        }
        startDownloadTask(for: envelope)
    }

    func cancelDownload(id: String) {
        downloadTasks[id]?.cancel()
        downloadTasks.removeValue(forKey: id)
        messageDownloadStates[id] = .failed
        if let message = messages.first(where: { $0.id == id }) {
            Task { try? await container.persistence.saveMessage(message) }
        }
    }

    func retryDownload(id: String) {
        guard messageDownloadStates[id] == .failed,
              let message = messages.first(where: { $0.id == id }),
              !message.cid.isEmpty else { return }
        let envelopeRecipients = isGroupChat ? recipientAddresses : [myAddress]
        let envelope = Envelope(
            messageId: message.id, chatId: message.chatId,
            senderAddr: message.senderAddress, recipientAddrs: envelopeRecipients,
            cid: message.cid, timestamp: Int64(message.timestamp.timeIntervalSince1970),
            encryptedPayload: nil, signature: nil
        )
        messageDownloadStates[id] = .loading
        startDownloadTask(for: envelope)
    }

    private func startDownloadTask(for envelope: Envelope) {
        let messageId = envelope.messageId
        messageDownloadStates[messageId] = .loading
        let task = Task {
            do {
                let decrypted = try await container.messageSender.decrypt(envelope: envelope)
                let timestamp = Date(timeIntervalSince1970: TimeInterval(envelope.timestamp))
                if let idx = messages.firstIndex(where: { $0.id == messageId }) {
                    messages[idx].messageType = decrypted.messageType
                    messages[idx].plaintext = decrypted.text
                    messages[idx].imageData = decrypted.imageData
                    messages[idx].fileName = decrypted.fileName
                    messages[idx].isDecrypted = true
                    try? await container.persistence.saveMessage(messages[idx])
                    let preview = decrypted.text
                        ?? (decrypted.messageType == "image" ? "📷 Изображение" : nil)
                        ?? (decrypted.messageType == "file" ? "📎 \(decrypted.fileName ?? "Файл")" : nil)
                    if let preview {
                        try? await container.persistence.updateChatLastMessage(chatId: chatId, text: preview, date: timestamp)
                    }
                } else {
                    let message = MessageModel(
                        id: messageId, chatId: envelope.chatId, senderAddress: envelope.senderAddr,
                        cid: envelope.cid, timestamp: timestamp, isDecrypted: true,
                        plaintext: decrypted.text, messageType: decrypted.messageType,
                        imageData: decrypted.imageData, fileName: decrypted.fileName, status: "delivered"
                    )
                    messages.append(message)
                    try? await container.persistence.saveMessage(message)
                    let preview = decrypted.text
                        ?? (decrypted.messageType == "image" ? "📷 Изображение" : nil)
                        ?? (decrypted.messageType == "file" ? "📎 \(decrypted.fileName?.trimmingCharacters(in: .whitespaces) ?? "Файл")" : nil)
                    if let preview {
                        try? await container.persistence.updateChatLastMessage(chatId: chatId, text: preview, date: timestamp)
                    }
                }
                messageDownloadStates.removeValue(forKey: messageId)
                downloadTasks.removeValue(forKey: messageId)
                try? await container.relay.ack(messageId: messageId)
            } catch {
                messageDownloadStates[messageId] = .failed
                downloadTasks.removeValue(forKey: messageId)
                if !messages.contains(where: { $0.id == messageId }) {
                    let placeholder = MessageModel(
                        id: messageId, chatId: envelope.chatId, senderAddress: envelope.senderAddr,
                        cid: envelope.cid,
                        timestamp: Date(timeIntervalSince1970: TimeInterval(envelope.timestamp)),
                        isDecrypted: false, plaintext: nil, messageType: nil, imageData: nil, fileName: nil, status: "delivered"
                    )
                    messages.append(placeholder)
                }
                if !(error is CancellationError) {
                    self.error = error.localizedDescription
                }
            }
        }
        downloadTasks[messageId] = task
    }

    private func handleDeliveryStatus(_ status: ServerAckPayload) async {
        guard let index = messages.firstIndex(where: { $0.id == status.messageId }) else { return }

        messages[index].status = status.status == "delivered" ? "delivered" : "sent"
        try? await container.persistence.saveMessage(messages[index])
    }

    func dismissRecoveryAlert() {
        recoveryState = .idle
    }

    func recoverFromBlockchain() {
        guard recoveryState != .recovering else { return }

        recoveryState = .recovering
        recoveryTask = Task {
            do {
                let recovered = try await container.blockchainRecovery.recover(chatId: chatId, recipientAddress: recipientAddress)

                try Task.checkCancellation()

                for model in recovered {
                    try? await container.persistence.saveMessage(model)
                }

                if !recovered.isEmpty {
                    let existingIds = Set(messages.map(\.id))
                    let newOnes = recovered.filter { !existingIds.contains($0.id) }
                    messages = (messages + newOnes).sorted { $0.timestamp < $1.timestamp }
                    oldestLoadedDate = messages.first?.timestamp

                    if let latest = messages.last {
                        try? await container.persistence.updateChatLastMessage(chatId: chatId, text: latest.plaintext ?? "", date: latest.timestamp)
                    }
                }

                recoveryState = .done(newMessages: recovered.count)
            } catch is CancellationError {
                recoveryState = .idle
            } catch {
                recoveryState = .failed(error.localizedDescription)
            }
        }
    }

    func cancelRecovery() {
        recoveryTask?.cancel()
        recoveryTask = nil
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
