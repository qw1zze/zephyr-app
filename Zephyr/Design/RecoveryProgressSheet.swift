//
//  RecoveryProgressSheet.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 25/4/26.
//

import SwiftUI

struct RecoveryProgressSheet: View {
    let onCancel: () -> Void

    @State private var rotation: Double = 0
    @State private var dotPhase: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            dragHandle

            spinnerSection
                .padding(.top, 36)
                .padding(.bottom, 24)

            Text("Восстановление чата")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.bottom, 8)

            Text("Загружаем историю из блокчейна...")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.bottom, 24)

            cancelButton
                .padding(.horizontal, 25)
                .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            startDotAnimation()
        }
    }

    private var dragHandle: some View {
        Capsule()
            .fill(AppTheme.textTertiary)
            .frame(width: 36, height: 4)
            .padding(.top, 12)
    }

    private var spinnerSection: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.accent.opacity(0.15), lineWidth: 2.5)
                .frame(width: 60, height: 60)

            Circle()
                .trim(from: 0, to: 0.22)
                .stroke(
                    AppTheme.accent,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(rotation))
        }
    }

    private var cancelButton: some View {
        Button(action: onCancel) {
            Text("Отмена")
                .font(.body.weight(.semibold))
                .foregroundColor(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(AppTheme.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusPill, style: .continuous))
        }
    }

    private func startDotAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
            dotPhase = (dotPhase + 1) % 3
        }
    }
}
