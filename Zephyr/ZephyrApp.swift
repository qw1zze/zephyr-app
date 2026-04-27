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
            MainTabView(
                container: coordinator.container,
                onLogout: coordinator.logout
            )
        case .none:
            EmptyView()
        }
    }
}


struct MainTabView: View {
    let container: ServiceContainer
    let onLogout: () -> Void

    @State private var selectedTab = 0
    @State private var tabBarVisible = true
    @State private var isRestoringChatHistory = false
    @State private var cancelChatRestore: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            ChatListCoordinatorView(
                container: container,
                tabBarVisible: $tabBarVisible,
                isRestoringHistory: $isRestoringChatHistory,
                onCancelActionAvailable: { action in cancelChatRestore = action }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(selectedTab == 0 ? 1 : 0)
            .allowsHitTesting(selectedTab == 0)

            SettingsCoordinatorView(container: container, onLogout: onLogout)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(selectedTab == 1 ? 1 : 0)
                .allowsHitTesting(selectedTab == 1)

            if tabBarVisible {
                CustomTabBar(selectedTab: $selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if isRestoringChatHistory {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack {
                    Spacer()
                    RecoveryProgressSheet {
                        cancelChatRestore?()
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isRestoringChatHistory)
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            tabItem(icon: "bubble.left.and.bubble.right.fill", label: "Чаты", index: 0)
            tabItem(icon: "gearshape.fill", label: "Настройки", index: 1)
        }
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(.black)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.separator)
                .frame(height: 0.5)
        }
    }

    private func tabItem(icon: String, label: String, index: Int) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selectedTab == index ? AppTheme.accent : AppTheme.textTertiary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ChatListCoordinatorView: View {
    @StateObject private var coordinator: ChatListCoordinator
    @Binding var tabBarVisible: Bool
    @Binding var isRestoringHistory: Bool
    let onCancelActionAvailable: (@escaping () -> Void) -> Void

    init(container: ServiceContainer, tabBarVisible: Binding<Bool>, isRestoringHistory: Binding<Bool>, onCancelActionAvailable: @escaping (@escaping () -> Void) -> Void) {
        _coordinator = StateObject(wrappedValue: ChatListCoordinator(container: container))
        _tabBarVisible = tabBarVisible
        _isRestoringHistory = isRestoringHistory
        self.onCancelActionAvailable = onCancelActionAvailable
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.makeChatListView()
                .navigationDestination(for: ChatListCoordinator.Route.self) { route in
                    coordinator.view(for: route)
                }
        }
        .onChange(of: coordinator.path.isEmpty) { _, isEmpty in
            withAnimation(.easeInOut(duration: 0.3)) {
                tabBarVisible = isEmpty
            }
        }
        .onReceive(coordinator.$isRestoringHistory) { value in
            isRestoringHistory = value
        }
        .onAppear {
            onCancelActionAvailable { [weak coordinator] in
                coordinator?.cancelRestore()
            }
        }
    }
}

struct SettingsCoordinatorView: View {
    let container: ServiceContainer
    let onLogout: () -> Void

    var body: some View {
        NavigationStack {
            SettingsView(
                viewModel: SettingsViewModel(container: container, onLogout: onLogout)
            )
        }
    }
}

struct OnboardingCoordinatorView: View {
    @StateObject private var coordinator: OnboardingCoordinator
    @State private var introCompleted: Bool

    init(container: ServiceContainer, onComplete: @escaping () -> Void) {
        _coordinator = StateObject(
            wrappedValue: OnboardingCoordinator(container: container, onComplete: onComplete)
        )
        _introCompleted = State(initialValue: UserDefaults.standard.bool(forKey: "introOnboardingSeen"))
    }

    var body: some View {
        if introCompleted {
            NavigationStack(path: $coordinator.path) {
                coordinator.makeWelcomeView()
                    .navigationDestination(for: OnboardingCoordinator.Route.self) { route in
                        coordinator.view(for: route)
                    }
            }
        } else {
            IntroOnboardingView {
                UserDefaults.standard.set(true, forKey: "introOnboardingSeen")
                withAnimation(.easeInOut(duration: 0.35)) {
                    introCompleted = true
                }
            }
        }
    }
}
