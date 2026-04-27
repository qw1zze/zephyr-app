//
//  ProfileSetupViewModel.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 25/4/26.
//

import Combine
import SwiftUI

@MainActor
final class ProfileSetupViewModel: ObservableObject {
    @Published var nickname: String = ""
    @Published var avatarImage: UIImage? = nil

    private let onComplete: () -> Void

    private enum StorageKeys {
        static let nickname = "zephyr.nickname"
        static let avatar = "zephyr.avatar"
    }

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    func setAvatar(_ image: UIImage) {
        avatarImage = image
    }

    func saveAndContinue() {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            UserDefaults.standard.set(trimmed, forKey: StorageKeys.nickname)
        }
        if let image = avatarImage, let data = image.jpegData(compressionQuality: 0.85) {
            UserDefaults.standard.set(data, forKey: StorageKeys.avatar)
        }
        onComplete()
    }

    func skip() {
        onComplete()
    }
}
