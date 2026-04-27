//
//  WalletReadyView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import SwiftUI

struct WalletReadyView: View {
    let address: String
    let isRestored: Bool
    let onStart: () -> Void

    @State private var addressCopied = false

    private var shortAddress: String {
        guard address.count > 10 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }

    var body: some View {
        ZStack {
            ZephyrBackground(showGrid: false, showScanline: false)

            VStack(spacing: 0) {
                Spacer()

                checkImage
                    .padding(.bottom, 28)

                title

                addressField
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(NewAppTheme.Colors.bg2, in: RoundedRectangle(cornerRadius: NewAppTheme.radiusSmall))
                    .overlay(
                        RoundedRectangle(cornerRadius: NewAppTheme.radiusSmall)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                Spacer()

                Button("Далее", action: onStart)
                    .buttonStyle(ZephyrButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
    }

    private var checkImage: some View {
        ZStack {
            Circle()
                .fill(NewAppTheme.Colors.lemon.opacity(0.08))
                .frame(width: 120, height: 120)
                .blur(radius: 20)

            Circle()
                .fill(NewAppTheme.Colors.lemon.opacity(0.12))
                .frame(width: 96, height: 96)

            Circle()
                .stroke(NewAppTheme.Colors.lemon.opacity(0.6), lineWidth: 1.5)
                .frame(width: 96, height: 96)

            Image(systemName: "checkmark")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(NewAppTheme.Colors.lemon)
        }
    }

    @ViewBuilder
    private var title: some View {
        Text(isRestored ? "Кошелёк восстановлен" : "Кошелёк создан")
            .font(NewAppTheme.Fonts.title)
            .foregroundStyle(NewAppTheme.Colors.textPrimary)
            .padding(.bottom, 8)

        Text("Ваш Ethereum адрес")
            .font(NewAppTheme.Fonts.caption)
            .foregroundStyle(NewAppTheme.Colors.textSecondary)
            .padding(.bottom, 16)
    }

    private var addressField: some View {
        HStack(spacing: 10) {
            Text(shortAddress)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(NewAppTheme.Colors.textPrimary)

            Button(action: copyAddress) {
                Image(systemName: addressCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 14))
                    .foregroundStyle(addressCopied ? NewAppTheme.Colors.lemon : NewAppTheme.Colors.textSecondary)
                    .animation(.easeInOut(duration: 0.2), value: addressCopied)
            }
        }
    }

    private func copyAddress() {
        UIPasteboard.general.string = address
        addressCopied = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            addressCopied = false
        }
    }
}

#Preview {
    NavigationStack {
        WalletReadyView(
            address: "0x71C7656EC7ab88b098defB751B7401B5f6d8976F",
            isRestored: false,
            onStart: {}
        )
    }
}
