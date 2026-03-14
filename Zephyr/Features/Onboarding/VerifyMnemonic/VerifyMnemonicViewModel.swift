//
//  VerifyMnemonicViewModel.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation
import Combine

@MainActor
final class VerifyMnemonicViewModel: ObservableObject {
    @Published var userInputs: [Int: String] = [:]
    @Published private(set) var error: String?
    @Published private(set) var isLoading: Bool = false

    let wordsToVerify: [VerifyWord]
    private let originalWords: [String]
    private weak var coordinator: OnboardingCoordinator?
    private let cryptoService: CryptoService
    private let keychainService: KeychainService
    
    struct VerifyWord: Identifiable {
        let id = UUID()
        let index: Int
        let word: String
    }

    var isAllFilled: Bool {
        wordsToVerify.allSatisfy { !(userInputs[$0.index] ?? "").isEmpty }
    }

    var isValid: Bool {
        wordsToVerify.allSatisfy { verifyWord in
            let input = userInputs[verifyWord.index]?
                .lowercased()
                .trimmingCharacters(in: .whitespaces) ?? ""
            return input == verifyWord.word.lowercased()
        }
    }

    func wordState(for index: Int) -> Bool? {
        guard let input = userInputs[index], !input.isEmpty else { return nil }
        let correct = wordsToVerify.first { $0.index == index }?.word ?? ""
        return input.lowercased().trimmingCharacters(in: .whitespaces) == correct.lowercased()
    }

    init(coordinator: OnboardingCoordinator, words: [String], cryptoService: CryptoService, keychainService: KeychainService) {
        self.coordinator = coordinator
        self.originalWords = words
        self.cryptoService = cryptoService
        self.keychainService = keychainService

        let indices = (0..<words.count)
            .shuffled()
            .prefix(4)
            .sorted()

        self.wordsToVerify = indices.map { i in
            VerifyWord(index: i + 1, word: words[i])
        }
    }

    func confirm() async {
        guard isValid else {
            error = "Некоторые слова введены неверно"
            return
        }

        isLoading = true
        error = nil

        do {
            let wallet = try cryptoService.deriveWallet(from: originalWords)
            let phrase = originalWords.joined(separator: " ")

            if let mnemonicData = phrase.data(using: .utf8),
               let addressData = wallet.address.data(using: .utf8) {
                try keychainService.save(key: KeychainKeys.mnemonic,    data: mnemonicData)
                try keychainService.save(key: KeychainKeys.address,     data: addressData)
                try keychainService.save(key: KeychainKeys.privateKey,  data: wallet.privateKey)
                try keychainService.save(key: KeychainKeys.publicKey,   data: wallet.publicKey)
            }

            coordinator?.handleWalletCreated(address: wallet.address)
        } catch {
            self.error = "Ошибка: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
