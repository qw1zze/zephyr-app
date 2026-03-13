//
//  OnboardingCoordinator.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import SwiftUI
import Combine

enum OnboardingRoute: Hashable {
    case welcome
}

@MainActor
final class OnboardingCoordinator: ObservableObject {
    @Published var path = NavigationPath()

    init() {
    }

    func userDidTapAlreadyHaveWallet() {
        
    }

    func makeWelcomeView() -> some View {
        let vm = OnboardingViewModel(coordinator: self)
        return OnboardingView(viewModel: vm)
    }
}
