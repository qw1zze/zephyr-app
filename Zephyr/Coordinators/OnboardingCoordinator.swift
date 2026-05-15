//
//  OnboardingCoordinator.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import SwiftUI
import Combine

@MainActor
final class OnboardingCoordinator: ObservableObject {
    @Published var path = NavigationPath()

    private let container: ServiceContainer
    private let onComplete: (() -> Void)?

    enum Route: Hashable {
        case generateMnemonic
        case verifyMnemonic(words: [String])
        case restoreMnemonic
        case walletReady(wallet: PendingWallet, isRestored: Bool)
        case publishKey(wallet: PendingWallet)
    }

    private var generateMnemonicViewModel: GenerateMnemonicViewModel?
    private var restoreMnemonicViewModel: RestoreMnemonicViewModel?

    init(container: ServiceContainer = .live(), onComplete: (() -> Void)? = nil) {
        self.container = container
        self.onComplete = onComplete
    }

    public func navigate(to route: Route) {
        path.append(route)
    }

    public func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    public func handleWalletCreated(wallet: PendingWallet) {
        navigate(to: .walletReady(wallet: wallet, isRestored: false))
    }

    public func handleWalletRestored(wallet: PendingWallet) {
        navigate(to: .walletReady(wallet: wallet, isRestored: true))
    }

    public func completeOnboarding() {
        onComplete?()
    }

    func makeWelcomeView() -> some View {
        OnboardingView(viewModel: OnboardingViewModel(coordinator: self))
    }

    private func cachedGenerateMnemonicVM() -> GenerateMnemonicViewModel {
        if let vm = generateMnemonicViewModel { return vm }
        let vm = GenerateMnemonicViewModel(coordinator: self, cryptoService: container.crypto, keychainService: container.keychain)
        generateMnemonicViewModel = vm
        return vm
    }

    private func cachedRestoreMnemonicVM() -> RestoreMnemonicViewModel {
        if let vm = restoreMnemonicViewModel { return vm }
        let vm = RestoreMnemonicViewModel(coordinator: self, cryptoService: container.crypto)
        restoreMnemonicViewModel = vm
        return vm
    }
    
    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .generateMnemonic:
            GenerateMnemonicView(viewModel: cachedGenerateMnemonicVM())

        case .verifyMnemonic(let words):
            VerifyMnemonicView(
                viewModel: VerifyMnemonicViewModel(
                    coordinator: self,
                    words: words,
                    cryptoService: container.crypto
                )
            )

        case .restoreMnemonic:
            RestoreMnemonicView(viewModel: cachedRestoreMnemonicVM())
            
        case .walletReady(let wallet, let isRestored):
            WalletReadyView(
                address: wallet.address,
                isRestored: isRestored,
                onStart: { [weak self] in
                    self?.navigate(to: .publishKey(wallet: wallet))
                }
            )
            
        case .publishKey(let wallet):
            PublishKeyView(
                viewModel: PublishKeyViewModel(
                    container: container,
                    pendingWallet: wallet,
                    onComplete: { [weak self] _ in
                        self?.completeOnboarding()
                    }
                )
            )
        }
    }
}

struct PendingWallet: Hashable {
    let address: String
    let privateKey: Data
    let publicKey: Data
    let mnemonic: String
}
