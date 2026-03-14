//
//  AppCoordinator.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import SwiftUI
import Combine

enum AppRoute {
    case onboarding
    case chatList
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published private(set) var currentRoute: AppRoute!

    let container: ServiceContainer = .live()
    
    init() {
        currentRoute = (try? container.keychain.load(key: KeychainKeys.privateKey)) != nil ? .chatList : .onboarding
    }

    func handleOnboardingComplete() {
        currentRoute = .chatList
    }

    func showOnboarding() {
        currentRoute = .onboarding
    }
}
