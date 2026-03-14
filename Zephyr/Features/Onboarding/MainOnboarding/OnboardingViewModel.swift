//
//  OnboardingViewModel.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    private weak var coordinator: OnboardingCoordinator?

    init(coordinator: OnboardingCoordinator) {
        self.coordinator = coordinator
    }

    func didTapCreateWallet() {
        coordinator?.navigate(to: .generateMnemonic)
    }

    func didTapRestoreWallet() {
        coordinator?.navigate(to: .restoreMnemonic)
    }
}
