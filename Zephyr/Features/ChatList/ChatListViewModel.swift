//
//  ChatListViewModel.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation
import Combine

enum AddressValidation: Equatable {
    case idle
    case invalidFormat
    case checking
    case notFound
    case valid
}

struct AddressEntry: Identifiable, Equatable {
    var id = UUID()
    var text: String = ""
    var validation: AddressValidation = .idle
}

@MainActor
final class ChatListViewModel: ObservableObject {
    @Published private(set) var chats: [ChatModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    @Published var addressEntries: [AddressEntry] = [AddressEntry()]
    @Published private(set) var isCreatingChat = false
    @Published private(set) var createdChatID: String?
    @Published private(set) var isRestoringHistory = false

    var canCreateChat: Bool {
        !isCreatingChat && !addressEntries.isEmpty && addressEntries.allSatisfy { $0.validation == .valid }
    }

    private let container: ServiceContainer
    private let onChatSelected: (String, [String]) -> Void
    private var validationTasks: [UUID: Task<Void, Never>] = [:]

    init(container: ServiceContainer, onChatSelected: @escaping (String, [String]) -> Void) {
        self.container = container
        self.onChatSelected = onChatSelected
    }

    func loadChats() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            chats = try container.persistence.fetchChats()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func refresh() async {
        await loadChats()
    }

    func addAddressEntry() {
        addressEntries.append(AddressEntry())
    }

    func removeAddressEntry(id: UUID) {
        guard addressEntries.count > 1 else { return }
        validationTasks[id]?.cancel()
        validationTasks.removeValue(forKey: id)
        addressEntries.removeAll { $0.id == id }
    }

    func validateEntry(id: UUID, value: String) async {
        validationTasks[id]?.cancel()
        validationTasks[id] = nil

        guard let index = addressEntries.firstIndex(where: { $0.id == id }) else { return }
        addressEntries[index].text = value

        guard !value.isEmpty else {
            addressEntries[index].validation = .idle
            return
        }

        guard isValidEthereumAddress(value) else {
            addressEntries[index].validation = .invalidFormat
            return
        }

        addressEntries[index].validation = .checking

        let task = Task {
            do {
                try await Task.sleep(nanoseconds: 60_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            guard let idx = addressEntries.firstIndex(where: { $0.id == id }) else { return }
            do {
                let key = try await container.ethereum.getPublicKey(address: value)
                guard !Task.isCancelled else { return }
                addressEntries[idx].validation = key != nil ? .valid : .notFound
            } catch {
                guard !Task.isCancelled else { return }
                addressEntries[idx].validation = .notFound
            }
        }
        validationTasks[id] = task
    }

    func createChat() async {
        guard canCreateChat else { return }
        isCreatingChat = true
        error = nil
        defer { isCreatingChat = false }
        do {
            let myAddress = (try? container.keychain.load(key: KeychainKeys.address))
                .flatMap { String(data: $0, encoding: .utf8) } ?? ""
            let recipientAddresses = addressEntries.map { $0.text }

            let chat: ChatModel
            if recipientAddresses.count == 1 {
                let chatId = generateChatId(addresses: [myAddress, recipientAddresses[0]])
                chat = try container.persistence.createChat(id: chatId, recipientAddress: recipientAddresses[0])
            } else {
                let chatId = generateChatId(addresses: [myAddress] + recipientAddresses)
                chat = try container.persistence.createChat(id: chatId, participantAddresses: recipientAddresses)
            }

            chats = try container.persistence.fetchChats()
            resetCreateChat()
            createdChatID = chat.id
        } catch {
            self.error = error.localizedDescription
        }
    }

    func selectChat(_ chat: ChatModel) {
        let recipients = chat.isGroupChat ? chat.participantAddresses : [chat.recipientAddress]
        onChatSelected(chat.id, recipients)
    }

    func deleteChat(_ chat: ChatModel) {
        do {
            try container.persistence.deleteChat(chatId: chat.id)
            chats.removeAll { $0.id == chat.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func startListen() {
        Task {
            do {
                try await container.relay.connect()
            } catch {
                self.error = error.localizedDescription
            }
            
            for await envelope in container.relay.incomingEnvelopes {
                container.envelopePublisher.send(envelope)
            }
        }

        Task {
            for await envelope in container.envelopePublisher
                .buffer(size: .max, prefetch: .byRequest, whenFull: .dropOldest)
                .values {
                await handleIncomingMessage(envelope)
            }
        }
    }

    private func handleIncomingMessage(_ envelope: Envelope) async {
        do {
            if !chats.contains(where: { $0.id == envelope.chatId }) {
                if envelope.recipientAddrs.count > 1 {
                    let myAddress = (try? container.keychain.load(key: KeychainKeys.address))
                        .flatMap { String(data: $0, encoding: .utf8) } ?? ""
                    let otherParticipants = ([envelope.senderAddr] + envelope.recipientAddrs)
                        .filter { $0.lowercased() != myAddress.lowercased() }
                    _ = try container.persistence.createChat(id: envelope.chatId, participantAddresses: otherParticipants)
                } else {
                    _ = try container.persistence.createChat(id: envelope.chatId, recipientAddress: envelope.senderAddr)
                }
            }

            let decrypted: DecryptedMessage? = try? await container.messageSender.decrypt(envelope: envelope)
            let messageTimestamp = Date(timeIntervalSince1970: TimeInterval(envelope.timestamp))
            let message = MessageModel(id: envelope.messageId, chatId: envelope.chatId, senderAddress: envelope.senderAddr,
                                       cid: envelope.cid, timestamp: messageTimestamp, isDecrypted: decrypted != nil, plaintext: decrypted?.text,
                                       messageType: decrypted?.messageType, imageData: decrypted?.imageData, status: "delivered")

            try await container.persistence.saveMessage(message)

            let preview: String
            switch decrypted?.messageType {
            case "image": preview = "📷 Изображение"
            case "file": preview = decrypted?.fileName.map { "📎 \($0)" } ?? "Файл"
            default: preview = decrypted?.text ?? ""
            }
            try await container.persistence.updateChatLastMessage(chatId: envelope.chatId, text: preview, date: messageTimestamp)

            chats = try container.persistence.fetchChats()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func restoreAllChats() {
        guard !isRestoringHistory else { return }
        isRestoringHistory = true
        Task {
            defer { isRestoringHistory = false }
            
            do {
                let myAddress = (try? container.keychain.load(key: KeychainKeys.address))
                    .flatMap { String(data: $0, encoding: .utf8) } ?? ""

                let chatIds = try await container.ethereum.getUserChats(userAddress: myAddress)

                for chatId in chatIds {
                    let allParticipants = (try? await container.ethereum.getChatParticipants(chatId: chatId)) ?? []
                    let otherParticipants = allParticipants.filter { $0.lowercased() != myAddress.lowercased() }
                    guard !otherParticipants.isEmpty else { continue }

                    if otherParticipants.count >= 2 {
                        _ = try? container.persistence.createChat(id: chatId, participantAddresses: otherParticipants)
                    } else if !chats.contains(where: { $0.id == chatId }) {
                        _ = try? container.persistence.createChat(id: chatId, recipientAddress: otherParticipants[0])
                    }

                    let primaryRecipient = otherParticipants[0]
                    let recovered = try await container.blockchainRecovery.recover(chatId: chatId, recipientAddress: primaryRecipient)
                    for model in recovered {
                        try? await container.persistence.saveMessage(model)
                    }

                    if let last = recovered.max(by: { $0.timestamp < $1.timestamp }) {
                        let preview: String
                        switch last.messageType {
                        case "image": preview = "📷 Изображение"
                        case "file": preview = last.fileName.map { "📎 \($0)" } ?? "Файл"
                        default: preview = last.plaintext ?? ""
                        }
                        try? await container.persistence.updateChatLastMessage(chatId: chatId, text: preview, date: last.timestamp)
                    }
                }

                chats = try container.persistence.fetchChats()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func resetCreateChat() {
        for entry in addressEntries {
            validationTasks[entry.id]?.cancel()
        }
        validationTasks.removeAll()
        addressEntries = [AddressEntry()]
        createdChatID = nil
    }

    private func isValidEthereumAddress(_ address: String) -> Bool {
        let pattern = "^0x[0-9a-fA-F]{40}$"
        return address.range(of: pattern, options: .regularExpression) != nil
    }
}
