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
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                checkImage
                    .padding(.bottom, 28)

                title

                addressField
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(white: 0.15), lineWidth: 1)
                    )

                Spacer()

                startButton
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
                .fill(Color(white: 0.1))
                .frame(width: 96, height: 96)

            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
        }
    }
    
    @ViewBuilder
    private var title: some View {
        Text(isRestored ? "Кошелёк восстановлен" : "Кошелёк создан")
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(.white)
            .padding(.bottom, 8)

        Text("Ваш Ethereum адрес")
            .font(.system(size: 13))
            .foregroundStyle(Color(white: 0.5))
            .padding(.bottom, 16)
    }
    
    private var addressField: some View {
        HStack(spacing: 10) {
            Text(shortAddress)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)

            Button(action: copyAddress) {
                Image(systemName: addressCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 14))
                    .foregroundStyle(addressCopied ? .green : Color(white: 0.55))
                    .animation(.easeInOut(duration: 0.2), value: addressCopied)
            }
        }
    }
    
    private var startButton: some View {
        Button(action: onStart) {
            Text("Далее")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
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
