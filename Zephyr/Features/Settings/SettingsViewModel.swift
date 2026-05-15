//
//  SettingsViewModel.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 16/3/26.
//

import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var nickname: String = ""
    @Published var avatarImage: UIImage? = nil
    @Published var address: String = ""
    @Published var isLoggingOut = false
    @Published var isSaving = false
    @Published var saveError: String? = nil
    @Published var savedSuccessfully = false
    @Published private(set) var hasUnsavedChanges = false

    private var originalNickname: String = ""
    private var avatarChanged = false

    private let container: ServiceContainer
    private let onLogout: () -> Void

    private enum StorageKeys {
        static let nickname = "zephyr.nickname"
        static let avatar = "zephyr.avatar"
        static let profileCID = "zephyr.profileCID"
    }

    init(container: ServiceContainer, onLogout: @escaping () -> Void) {
        self.container = container
        self.onLogout = onLogout
        loadProfile()
    }

    func loadProfile() {
        let saved = UserDefaults.standard.string(forKey: StorageKeys.nickname) ?? ""
        nickname = saved
        originalNickname = saved
        avatarChanged = false
        hasUnsavedChanges = false
        if let data = UserDefaults.standard.data(forKey: StorageKeys.avatar) {
            avatarImage = UIImage(data: data)
        }
        if let data = try? container.keychain.load(key: KeychainKeys.address),
           let addr = String(data: data, encoding: .utf8) {
            address = addr
        }
    }

    func nicknameDidChange(_ newValue: String) {
        hasUnsavedChanges = newValue != originalNickname || avatarChanged
    }

    func setAvatar(_ image: UIImage) {
        avatarImage = image
        avatarChanged = true
        hasUnsavedChanges = true
    }

    func saveProfile() {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        Task {
            isSaving = true
            saveError = nil
            defer { isSaving = false }

            do {
                var avatarCID = ""
                if let avatarData = UserDefaults.standard.data(forKey: StorageKeys.avatar) {
                    avatarCID = try await container.storage.upload(data: avatarData)
                }

                let profileCID = try await container.profile.saveProfile(name: trimmed, avatar: avatarCID)

                let txHash = try await container.ethereum.setProfileCID(profileCID)
                if !txHash.isEmpty {
                    try await container.ethereum.waitForConfirmation(txHash: txHash)
                }

                UserDefaults.standard.set(trimmed, forKey: StorageKeys.nickname)
                UserDefaults.standard.set(profileCID, forKey: StorageKeys.profileCID)

                originalNickname = trimmed
                avatarChanged = false
                hasUnsavedChanges = false
                savedSuccessfully = true
            } catch {
                saveError = error.localizedDescription
            }
        }
    }

    func logout() {
        isLoggingOut = true
        try? container.keychain.delete(key: KeychainKeys.mnemonic)
        try? container.keychain.delete(key: KeychainKeys.address)
        try? container.keychain.delete(key: KeychainKeys.privateKey)
        try? container.keychain.delete(key: KeychainKeys.publicKey)
        try? container.persistence.deleteAllData()
        UserDefaults.standard.removeObject(forKey: StorageKeys.nickname)
        UserDefaults.standard.removeObject(forKey: StorageKeys.avatar)
        UserDefaults.standard.removeObject(forKey: StorageKeys.profileCID)
        onLogout()
    }
}
