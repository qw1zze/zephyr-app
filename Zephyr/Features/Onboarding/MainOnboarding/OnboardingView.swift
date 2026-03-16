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
            AppTheme.background.ignoresSafeArea()

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
        VStack(spacing: 12) {
            Text("Zephyr")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(AppTheme.accent)
                .tracking(2)

            Text("Enter to privacy")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
                .tracking(0.5)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: viewModel.didTapCreateWallet) {
                Text("Создать кошелёк")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: AppTheme.radiusPill))
            }

            Button(action: viewModel.didTapRestoreWallet) {
                Text("Уже есть кошелёк")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.radiusPill)
                            .stroke(Color(white: 0.3), lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    let coordinator = OnboardingCoordinator()
    OnboardingView(viewModel: OnboardingViewModel(coordinator: coordinator))
}
