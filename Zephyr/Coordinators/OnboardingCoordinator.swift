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
        case walletReady(address: String, isRestored: Bool)
        case publishKey
    }

    init(container: ServiceContainer = .live(), onComplete: (() -> Void)? = nil) {
        self.container = container
        self.onComplete = onComplete
    }

    public func navigate(to route: Route) {
        path.append(route)
    }

    public func handleWalletCreated(address: String) {
        navigate(to: .walletReady(address: address, isRestored: false))
    }

    public func handleWalletRestored(address: String) {
        navigate(to: .walletReady(address: address, isRestored: true))
    }

    public func completeOnboarding() {
        onComplete?()
    }

    func makeWelcomeView() -> some View {
        OnboardingView(viewModel: OnboardingViewModel(coordinator: self))
    }

    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .generateMnemonic:
            GenerateMnemonicView(
                viewModel: GenerateMnemonicViewModel(
                    coordinator: self,
                    cryptoService: container.crypto,
                    keychainService: container.keychain
                )
            )

        case .verifyMnemonic(let words):
            VerifyMnemonicView(
                viewModel: VerifyMnemonicViewModel(
                    coordinator: self,
                    words: words,
                    cryptoService: container.crypto,
                    keychainService: container.keychain
                )
            )

        case .restoreMnemonic:
            RestoreMnemonicView(
                viewModel: RestoreMnemonicViewModel(
                    coordinator: self,
                    cryptoService: container.crypto,
                    keychainService: container.keychain
                )
            )

        case .walletReady(let address, let isRestored):
            WalletReadyView(
                address: address,
                isRestored: isRestored,
                onStart: { [weak self] in
                    self?.navigate(to: .publishKey)
                }
            )

        case .publishKey:
            PublishKeyView(
                viewModel: PublishKeyViewModel(
                    container: container,
                    onComplete: { [weak self] in
                        self?.completeOnboarding()
                    }
                )
            )
        }
    }
}
