//
//  GenerateMnemonicViewModel.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation
import Combine
import UIKit

@MainActor
final class GenerateMnemonicViewModel: ObservableObject {
    @Published private(set) var words: [String] = []
    @Published private(set) var isCopied: Bool = false
    @Published var isRevealed: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: String?

    var canContinue: Bool { isRevealed && !words.isEmpty }

    private weak var coordinator: OnboardingCoordinator?
    private let cryptoService: CryptoService
    private let keychainService: KeychainService

    init(coordinator: OnboardingCoordinator, cryptoService: CryptoService, keychainService: KeychainService) {
        self.coordinator = coordinator
        self.cryptoService = cryptoService
        self.keychainService = keychainService
    }

    func generateMnemonic() async {
        isLoading = true
        error = nil
        do {
            words = try cryptoService.generateMnemonic()
        } catch {
            self.error = "Не удалось сгенерировать фразу"
        }
        isLoading = false
    }

    func toggleReveal() {
        isRevealed.toggle()
    }

    func copyToClipboard() {
        UIPasteboard.general.string = words.joined(separator: " ")
        isCopied = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            isCopied = false
        }
    }

    func didTapContinue() {
        guard !words.isEmpty else { return }
        coordinator?.navigate(to: .verifyMnemonic(words: words))
    }
}
