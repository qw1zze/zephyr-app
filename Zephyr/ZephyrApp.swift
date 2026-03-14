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
            OnboardingCoordinatorView(
                container: coordinator.container,
                onComplete: coordinator.handleOnboardingComplete
            )
        case .chatList:
            Text("Chat List")
                .preferredColorScheme(.dark)
        case .none:
            EmptyView()
        }
    }
}

struct OnboardingCoordinatorView: View {
    @StateObject private var coordinator: OnboardingCoordinator

    init(container: ServiceContainer, onComplete: @escaping () -> Void) {
        _coordinator = StateObject(
            wrappedValue: OnboardingCoordinator(container: container, onComplete: onComplete)
        )
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.makeWelcomeView()
                .navigationDestination(for: OnboardingCoordinator.Route.self) { route in
                    coordinator.view(for: route)
                }
        }
    }
}
