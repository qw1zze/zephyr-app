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
    @Published var currentRoute: AppRoute = .onboarding

    func showChatList() {
        currentRoute = .chatList
    }

    func showOnboarding() {
        currentRoute = .onboarding
    }
}
