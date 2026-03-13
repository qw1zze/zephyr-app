//
//  ZephyrApp.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import SwiftUI

@main
struct ZephyrApp: App {
    @StateObject private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            AppRootView(coordinator: appCoordinator)
        }
    }
}

struct AppRootView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        switch coordinator.currentRoute {
        case .onboarding:
            OnboardingCoordinatorView()
        case .chatList:
            Text("Chat List")
                .preferredColorScheme(.dark)
        }
    }
}

struct OnboardingCoordinatorView: View {
    @StateObject private var coordinator: OnboardingCoordinator = OnboardingCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.makeWelcomeView()
        }
    }
}
