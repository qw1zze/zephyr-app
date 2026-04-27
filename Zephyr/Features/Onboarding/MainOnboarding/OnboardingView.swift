//
//  OnboardingView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            ZephyrBackground(showGrid: false, showScanline: false, showCRT: true).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                header

                Spacer()

                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
    }
    
    private var header: some View {
        VStack(spacing: 5) {
            ZStack {
                Text("Zephyr")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(NewAppTheme.Colors.lemon.opacity(0.6))
                    .tracking(-1.62)
                    .blur(radius: 6)
                
                Text("Zephyr")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(NewAppTheme.Colors.lemon)
                    .tracking(-1.62)
            }

            Text("Enter to privacy")
                .font(.system(size: 16, weight: .regular))
                .italic()
                .foregroundStyle(AppTheme.textSecondary)
                .tracking(0.5)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: viewModel.didTapCreateWallet) {
                Text("Создать кошелёк")
            }
            .buttonStyle(ZephyrButtonStyle(filled: true))
            .shadow(color: Color(hex: "D9F000").opacity(0.8), radius: 12)

            Button(action: viewModel.didTapRestoreWallet) {
                Text("Уже есть кошелёк")
            }
            .buttonStyle(ZephyrButtonStyle(filled: false))
        }
    }
}

#Preview {
    let coordinator = OnboardingCoordinator()
    OnboardingView(viewModel: OnboardingViewModel(coordinator: coordinator))
}
