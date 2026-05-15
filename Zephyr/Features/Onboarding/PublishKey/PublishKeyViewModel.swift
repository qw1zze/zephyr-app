//
//  PublishKeyView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation
import Combine

enum PublishKeyError: LocalizedError {
    case transactionFailed
    case timeout
    case keychainError
    case contractError(String)

    var errorDescription: String? {
        switch self {
        case .transactionFailed:
            return "Транзакция отклонена сетью"
        case .timeout:
            return "Проверьте баланс для оплаты газа"
        case .keychainError:
            return "Ошибка чтения ключей из Keychain"
        case .contractError(let msg):
            return "Ошибка контракта: \(msg)"
        }
    }
}

@MainActor
final class PublishKeyViewModel: ObservableObject {
    @Published private(set) var state: PublishKeyState = .checking

    private let container: ServiceContainer
    private let pendingWallet: PendingWallet
    let onComplete: (Bool) -> Void

    init(container: ServiceContainer, pendingWallet: PendingWallet, onComplete: @escaping (Bool) -> Void) {
        self.container = container
        self.pendingWallet = pendingWallet
        self.onComplete = onComplete
    }

    func complete() {
        onComplete(state == .done)
    }
    
    enum PublishKeyState: Equatable {
        case checking
        case publishing
        case waitingConfirm
        case done
        case alreadyExists
        case error(String)
    }

    func start() async {
        state = .checking
        do {
            let address = pendingWallet.address

            let existing = try await container.ethereum.getPublicKey(address: address)
            if existing != nil {
                try saveToKeychain()
                state = .alreadyExists
                Task { await fetchAndCacheProfile(address: address) }
                return
            }

            try saveToKeychain()

            state = .publishing
            let txHash = try await container.ethereum.publishPublicKey(pendingWallet.publicKey)

            state = .waitingConfirm
            try await container.ethereum.waitForConfirmation(txHash: txHash)

            state = .done

        } catch {
            deleteFromKeychain()
            state = .error(error.localizedDescription)
        }
    }

    func retry() async {
        await start()
    }

    private func saveToKeychain() throws {
        guard let mnemonicData = pendingWallet.mnemonic.data(using: .utf8),
              let addressData = pendingWallet.address.data(using: .utf8) else {
            throw PublishKeyError.keychainError
        }
        
        try container.keychain.save(key: KeychainKeys.mnemonic, data: mnemonicData)
        try container.keychain.save(key: KeychainKeys.address, data: addressData)
        try container.keychain.save(key: KeychainKeys.privateKey, data: pendingWallet.privateKey)
        try container.keychain.save(key: KeychainKeys.publicKey, data: pendingWallet.publicKey)
    }

    private func deleteFromKeychain() {
        try? container.keychain.delete(key: KeychainKeys.mnemonic)
        try? container.keychain.delete(key: KeychainKeys.address)
        try? container.keychain.delete(key: KeychainKeys.privateKey)
        try? container.keychain.delete(key: KeychainKeys.publicKey)
    }

    private func fetchAndCacheProfile(address: String) async {
        do {
            let cid = try await container.ethereum.getProfileCID(address: address)
            guard !cid.isEmpty else { return }

            let profile = try await container.profile.getProfile(cid: cid)

            if !profile.name.isEmpty {
                UserDefaults.standard.set(profile.name, forKey: "zephyr.nickname")
            }

            if !profile.avatar.isEmpty {
                let avatarData = try await container.storage.download(cid: profile.avatar)
                UserDefaults.standard.set(avatarData, forKey: "zephyr.avatar")
            }
        } catch {

        }
    }
}
