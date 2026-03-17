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

@MainActor
final class ChatListViewModel: ObservableObject {
    @Published private(set) var chats: [ChatModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    @Published var newChatAddress = ""
    @Published private(set) var addressValidation = AddressValidation.idle
    @Published private(set) var isCreatingChat = false
    @Published private(set) var createdChatID: String?
    @Published private(set) var isRestoringHistory = false

    private let container: ServiceContainer
    private let onChatSelected: (String, String) -> Void
    private var validationTask: Task<Void, Never>?

    init(container: ServiceContainer, onChatSelected: @escaping (String, String) -> Void) {
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

    func validateAddress(_ address: String) async {
        validationTask?.cancel()
        validationTask = nil

        guard !address.isEmpty else {
            addressValidation = .idle
            return
        }

        guard isValidEthereumAddress(address) else {
            addressValidation = .invalidFormat
            return
        }

        addressValidation = .checking

        validationTask = Task {
            do {
                try await Task.sleep(nanoseconds: 60_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            do {
                let key = try await container.ethereum.getPublicKey(address: address)
                guard !Task.isCancelled else { return }
                addressValidation = key != nil ? .valid : .notFound
            } catch {
                guard !Task.isCancelled else { return }
                addressValidation = .notFound
            }
        }
    }

    func createChat(recipientAddress: String) async {
        guard addressValidation == .valid else { return }
        isCreatingChat = true
        error = nil
        defer { isCreatingChat = false }
        do {
            let myAddress = (try? container.keychain.load(key: KeychainKeys.address))
                .flatMap { String(data: $0, encoding: .utf8) } ?? ""
            let chatId = generateChatId(address1: myAddress, address2: recipientAddress)
            let chat = try container.persistence.createChat(id: chatId, recipientAddress: recipientAddress)
            chats = try container.persistence.fetchChats()
            newChatAddress = ""
            addressValidation = .idle
            createdChatID = chat.id
        } catch {
            self.error = error.localizedDescription
        }
    }

    func selectChat(_ chat: ChatModel) {
        onChatSelected(chat.id, chat.recipientAddress)
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
                _ = try container.persistence.createChat(id: envelope.chatId, recipientAddress: envelope.senderAddr)
            }

            let decrypted: DecryptedMessage? = try? await container.messageSender.decrypt(envelope: envelope)
            let messageTimestamp = Date(timeIntervalSince1970: TimeInterval(envelope.timestamp))
            let message = MessageModel(id: envelope.messageId, chatId: envelope.chatId, senderAddress: envelope.senderAddr,
                                       cid: envelope.cid, timestamp: messageTimestamp, isDecrypted: decrypted != nil, plaintext: decrypted?.text,
                                       messageType: decrypted?.messageType, imageData: decrypted?.imageData, status: "delivered")

            try await container.persistence.saveMessage(message)

            let preview = decrypted?.messageType == "image" ? "Изображение" : (decrypted?.text ?? "")
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
                    let recipientAddress = await findRecipient(chatId: chatId, myAddress: myAddress)
                    guard !recipientAddress.isEmpty else { continue }

                    if !chats.contains(where: { $0.id == chatId }) {
                        _ = try? container.persistence.createChat(id: chatId, recipientAddress: recipientAddress)
                    }

                    let recovered = try await container.blockchainRecovery.recover(chatId: chatId, recipientAddress: recipientAddress)
                    for model in recovered {
                        try? await container.persistence.saveMessage(model)
                    }
                }

                chats = try container.persistence.fetchChats()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func findRecipient(chatId: String, myAddress: String) async -> String {
        if let existing = chats.first(where: { $0.id == chatId }) {
            return existing.recipientAddress
        }
        do {
            let startBlock = try await container.ethereum.getChatCreatedAtBlock(chatId: chatId)
            let latestBlock = try await container.ethereum.getLatestBlock()
            let toBlock = min(startBlock + 10_000, latestBlock)
            let events = try await container.ethereum.getAnchoredBatches(chatId: chatId, fromBlock: startBlock, toBlock: toBlock)
            for event in events where event.sender.lowercased() != myAddress.lowercased() {
                return event.sender
            }
        } catch {}
        return ""
    }

    func resetCreateChat() {
        newChatAddress = ""
        addressValidation = .idle
        createdChatID = nil
        validationTask?.cancel()
        validationTask = nil
    }

    private func isValidEthereumAddress(_ address: String) -> Bool {
        let pattern = "^0x[0-9a-fA-F]{40}$"
        return address.range(of: pattern, options: .regularExpression) != nil
    }
}
