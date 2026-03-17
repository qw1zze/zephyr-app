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

    private let container: ServiceContainer
    private let onLogout: () -> Void

    private enum StorageKeys {
        static let nickname = "zephyr.nickname"
        static let avatar   = "zephyr.avatar"
    }

    init(container: ServiceContainer, onLogout: @escaping () -> Void) {
        self.container = container
        self.onLogout = onLogout
        loadProfile()
    }

    func loadProfile() {
        nickname = UserDefaults.standard.string(forKey: StorageKeys.nickname) ?? ""
        if let data = UserDefaults.standard.data(forKey: StorageKeys.avatar) {
            avatarImage = UIImage(data: data)
        }
        if let data = try? container.keychain.load(key: KeychainKeys.address),
           let addr = String(data: data, encoding: .utf8) {
            address = addr
        }
    }

    func saveNickname() {
        UserDefaults.standard.set(nickname, forKey: StorageKeys.nickname)
    }

    func setAvatar(_ image: UIImage) {
        avatarImage = image
        if let data = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(data, forKey: StorageKeys.avatar)
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
        onLogout()
    }
}
