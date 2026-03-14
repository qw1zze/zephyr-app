//
//  RestoreMnemonicViewModel.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation
import Combine

@MainActor
final class RestoreMnemonicViewModel: ObservableObject {
    @Published var words: [String] = Array(repeating: "", count: 12)
    @Published private(set) var invalidWords: Set<Int> = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: String?

    private weak var coordinator: OnboardingCoordinator?
    private let cryptoService: CryptoService
    private let keychainService: KeychainService

    var isReady: Bool {
        let filled = words.prefix(12).allSatisfy { !$0.isEmpty }
        return filled && invalidWords.isEmpty && !isLoading
    }

    init(coordinator: OnboardingCoordinator, cryptoService: CryptoService, keychainService: KeychainService) {
        self.coordinator = coordinator
        self.cryptoService = cryptoService
        self.keychainService = keychainService
    }

    func validateWord(at index: Int) {
        let raw = words[index]
        let normalized = raw.lowercased().trimmingCharacters(in: .whitespaces)
        words[index] = normalized

        guard !normalized.isEmpty else {
            invalidWords.remove(index)
            return
        }

        if cryptoService.isValidWord(normalized) {
            invalidWords.remove(index)
        } else {
            invalidWords.insert(index)
        }
    }

    func handlePaste(text: String, intoIndex index: Int) {
        let parts = text
            .components(separatedBy: .whitespaces)
            .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard parts.count == 12 else { return }

        words = parts
        invalidWords = []
        for i in 0..<12 {
            validateWord(at: i)
        }
    }

    func restore() async {
        guard isReady else { return }

        isLoading = true
        error = nil

        let activeWords = Array(words.prefix(12))

        do {
            try cryptoService.validateMnemonic(activeWords)
            let wallet = try cryptoService.deriveWallet(from: activeWords)
            let phrase = activeWords.joined(separator: " ")

            if let mnemonicData = phrase.data(using: .utf8),
               let addressData = wallet.address.data(using: .utf8) {
                try keychainService.save(key: KeychainKeys.mnemonic,    data: mnemonicData)
                try keychainService.save(key: KeychainKeys.address,     data: addressData)
                try keychainService.save(key: KeychainKeys.privateKey,  data: wallet.privateKey)
                try keychainService.save(key: KeychainKeys.publicKey,   data: wallet.publicKey)
            }

            coordinator?.handleWalletRestored(address: wallet.address)
        } catch CryptoError.invalidMnemonic {
            error = "Неверная мнемо фраза"
        } catch {
            self.error = "Ошибка восстановления: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
