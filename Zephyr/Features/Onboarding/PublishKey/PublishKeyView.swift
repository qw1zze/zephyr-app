//
//  PublishKeyView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import SwiftUI

struct PublishKeyView: View {
    @ObservedObject var viewModel: PublishKeyViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            content
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
        .task { await viewModel.start() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .checking:
            progressView(
                label: "Проверяем реестр ключей...",
                subtitle: nil
            )

        case .publishing:
            progressView(
                label: "Публикуем ключ в блокчейне...",
                subtitle: "Это займёт несколько секунд"
            )

        case .waitingConfirm:
            progressView(
                label: "Ожидаем подтверждения транзакции...",
                subtitle: "Обычно занимает 5–15 секунд"
            )

        case .done:
            successView(label: "Ключ зарегистрирован")

        case .alreadyExists:
            successView(label: "Ключ зарегистрирован")

        case .error(let message):
            errorView(message: message)
        }
    }

    private func progressView(label: String, subtitle: String?) -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(Color(white: 0.6))

            VStack(spacing: 8) {
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(white: 0.45))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, 40)
    }

    private func successView(label: String) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color(white: 0.1))
                        .frame(width: 88, height: 88)
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text(label)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button(action: viewModel.onComplete) {
                Text("Перейти к чатам")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "xmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.red)
                }

                VStack(spacing: 8) {
                    Text("Ошибка публикации")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    Text(message)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(white: 0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            Spacer()

            Button {
                Task { await viewModel.retry() }
            } label: {
                Text("Повторить")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(white: 0.25), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

#Preview("Checking") {
    NavigationStack {
        PublishKeyView(
            viewModel: PublishKeyViewModel(
                container: .mock(),
                onComplete: {}
            )
        )
    }
}
