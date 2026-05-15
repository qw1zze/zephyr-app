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
    case selfAddress
    case duplicate
    case checking
    case notFound
    case valid
}

struct AddressEntry: Identifiable, Equatable {
    var id = UUID()
    var text: String = ""
    var validation: AddressValidation = .idle
    var profileName: String? = nil
    var avatarData: Data? = nil
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
    @Published private(set) var unblockAlertChat: ChatModel? = nil

    var canCreateChat: Bool {
        !isCreatingChat && !addressEntries.isEmpty && addressEntries.allSatisfy { $0.validation == .valid }
    }

    private let container: ServiceContainer
    private let onChatSelected: (String, [String], String?, String?, Data?, [String: String]) -> Void
    private var validationTasks: [UUID: Task<Void, Never>] = [:]
    private var restoreTask: Task<Void, Never>?

    init(container: ServiceContainer, onChatSelected: @escaping (String, [String], String?, String?, Data?, [String: String]) -> Void) {
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
        for entry in addressEntries where entry.validation == .duplicate {
            Task { await validateEntry(id: entry.id, value: entry.text) }
        }
    }

    func validateEntry(id: UUID, value: String) async {
        validationTasks[id]?.cancel()
        validationTasks[id] = nil

        guard let index = addressEntries.firstIndex(where: { $0.id == id }) else { return }
        addressEntries[index].text = value

        guard !value.isEmpty else {
            addressEntries[index].validation = .idle
            addressEntries[index].profileName = nil
            addressEntries[index].avatarData = nil
            return
        }

        guard isValidEthereumAddress(value) else {
            addressEntries[index].validation = .invalidFormat
            addressEntries[index].profileName = nil
            addressEntries[index].avatarData = nil
            return
        }

        let myAddress = (try? container.keychain.load(key: KeychainKeys.address))
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
        if !myAddress.isEmpty && value.lowercased() == myAddress.lowercased() {
            addressEntries[index].validation = .selfAddress
            addressEntries[index].profileName = nil
            addressEntries[index].avatarData = nil
            return
        }

        let isDuplicate = addressEntries.contains { entry in
            entry.id != id && entry.text.lowercased() == value.lowercased()
        }
        if isDuplicate {
            addressEntries[index].validation = .duplicate
            addressEntries[index].profileName = nil
            addressEntries[index].avatarData = nil
            return
        }

        addressEntries[index].validation = .checking
        addressEntries[index].profileName = nil
        addressEntries[index].avatarData = nil

        let task = Task {
            do {
                try await Task.sleep(nanoseconds: 60_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            guard addressEntries.contains(where: { $0.id == id }) else { return }
            do {
                let key = try await container.ethereum.getPublicKey(address: value)
                guard !Task.isCancelled else { return }
                guard let idx2 = addressEntries.firstIndex(where: { $0.id == id }) else { return }
                guard key != nil else {
                    addressEntries[idx2].validation = .notFound
                    return
                }
                addressEntries[idx2].validation = .valid
                await fetchProfile(entryID: id, address: value)
            } catch {
                guard !Task.isCancelled else { return }
                guard let idx2 = addressEntries.firstIndex(where: { $0.id == id }) else { return }
                addressEntries[idx2].validation = .notFound
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
                chat.recipientNickname = addressEntries.first?.profileName
                chat.recipientAvatarData = addressEntries.first?.avatarData
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
        var participantNicknames: [String: String] = [:]
        if chat.isGroupChat {
            for address in chat.participantAddresses {
                if let dmChat = try? container.persistence.chat(forAddress: address),
                   let nickname = dmChat.recipientNickname, !nickname.isEmpty {
                    participantNicknames[address.lowercased()] = nickname
                }
            }
        }
        onChatSelected(chat.id, recipients, chat.recipientNickname, chat.localAlias, chat.recipientAvatarData, participantNicknames)
    }

    func renameChat(_ chat: ChatModel, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        chat.localAlias = trimmed.isEmpty ? nil : trimmed
        objectWillChange.send()
    }

    func deleteChat(_ chat: ChatModel) {
        do {
            try container.persistence.deleteChat(chatId: chat.id)
            chats.removeAll { $0.id == chat.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func blockChat(_ chat: ChatModel) {
        do {
            try container.persistence.setBlocked(chatId: chat.id, isBlocked: true)
            chat.isBlocked = true
            objectWillChange.send()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func unblockChat(_ chat: ChatModel) {
        do {
            try container.persistence.setBlocked(chatId: chat.id, isBlocked: false)
            chat.isBlocked = false
            objectWillChange.send()
            unblockAlertChat = chat
        } catch {
            self.error = error.localizedDescription
        }
    }

    func dismissUnblockAlert() {
        unblockAlertChat = nil
    }

    func restoreChat(_ chat: ChatModel) {
        Task {
            do {
                let primaryRecipient = chat.isGroupChat ? (chat.participantAddresses.first ?? chat.recipientAddress) : chat.recipientAddress
                let recovered = try await container.blockchainRecovery.recover(chatId: chat.id, recipientAddress: primaryRecipient)
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
                    try? await container.persistence.updateChatLastMessage(chatId: chat.id, text: preview, date: last.timestamp)
                }
                chats = try container.persistence.fetchChats()
            } catch {
                self.error = error.localizedDescription
            }
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
            if let existing = chats.first(where: { $0.id == envelope.chatId }), existing.isBlocked {
                return
            }
            let blockedAddresses = chats.filter { $0.isBlocked }.map { $0.recipientAddress.lowercased() }
            if blockedAddresses.contains(envelope.senderAddr.lowercased()) {
                return
            }

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
        restoreTask = Task {
            defer { isRestoringHistory = false }

            do {
                let myAddress = (try? container.keychain.load(key: KeychainKeys.address))
                    .flatMap { String(data: $0, encoding: .utf8) } ?? ""

                let chatIds = try await container.ethereum.getUserChats(userAddress: myAddress)

                for chatId in chatIds {
                    try Task.checkCancellation()

                    let allParticipants = (try? await container.ethereum.getChatParticipants(chatId: chatId)) ?? []
                    let otherParticipants = allParticipants.filter { $0.lowercased() != myAddress.lowercased() }
                    guard !otherParticipants.isEmpty else { continue }

                    if otherParticipants.count >= 2 {
                        _ = try? container.persistence.createChat(id: chatId, participantAddresses: otherParticipants)
                    } else {
                        let chat: ChatModel
                        if let existing = chats.first(where: { $0.id == chatId }) {
                            chat = existing
                        } else {
                            guard let created = try? container.persistence.createChat(id: chatId, recipientAddress: otherParticipants[0]) else { continue }
                            chat = created
                        }
                        let (name, avatarData) = await fetchProfileForAddress(otherParticipants[0])
                        chat.recipientNickname = name
                        chat.recipientAvatarData = avatarData
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
            } catch is CancellationError {
                
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func cancelRestore() {
        restoreTask?.cancel()
        restoreTask = nil
        isRestoringHistory = false
    }

    func resetCreateChat() {
        for entry in addressEntries {
            validationTasks[entry.id]?.cancel()
        }
        validationTasks.removeAll()
        addressEntries = [AddressEntry()]
        createdChatID = nil
    }

    private func fetchProfileForAddress(_ address: String) async -> (name: String?, avatarData: Data?) {
        guard let cid = try? await container.ethereum.getProfileCID(address: address),
              !cid.isEmpty else { return (nil, nil) }
        guard let profileData = try? await container.profile.getProfile(cid: cid) else { return (nil, nil) }
        let name = profileData.name.isEmpty ? nil : profileData.name
        var avatarData: Data? = nil
        if !profileData.avatar.isEmpty {
            avatarData = try? await container.storage.download(cid: profileData.avatar)
        }
        return (name, avatarData)
    }

    private func fetchProfile(entryID: UUID, address: String) async {
        let (name, avatarData) = await fetchProfileForAddress(address)
        guard !Task.isCancelled,
              let idx = addressEntries.firstIndex(where: { $0.id == entryID }) else { return }
        addressEntries[idx].profileName = name
        addressEntries[idx].avatarData = avatarData
    }

    private func isValidEthereumAddress(_ address: String) -> Bool {
        let pattern = "^0x[0-9a-fA-F]{40}$"
        return address.range(of: pattern, options: .regularExpression) != nil
    }
}
