//
//  GenerateMnemonicView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import SwiftUI

struct GenerateMnemonicView: View {
    @ObservedObject var viewModel: GenerateMnemonicViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                warningBanner
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(AppTheme.accent)
                    Spacer()
                } else {
                    wordGrid
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    HStack(spacing: 12) {
                        revealButton
                        copyButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Spacer()

                    continueButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                }
            }
        }
        .navigationTitle("Секретная фраза")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .task { await viewModel.generateMnemonic() }
    }

    private var warningBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .font(.system(size: 16))
                .padding(.top, 1)

            Text("Запишите эти 12 слов в безопасном месте. Они являются единственным способом восстановить кошелёк.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(white: 0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color(white: 0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private var wordGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(viewModel.words.enumerated()), id: \.offset) { index, word in
                WordCell(index: index + 1, word: word, isRevealed: viewModel.isRevealed)
            }
        }
    }

    private var revealButton: some View {
        Button(action: viewModel.toggleReveal) {
            Label(
                viewModel.isRevealed ? "Скрыть" : "Показать",
                systemImage: viewModel.isRevealed ? "eye.slash" : "eye"
            )
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var copyButton: some View {
        Button(action: viewModel.copyToClipboard) {
            Label(
                viewModel.isCopied ? "Скопировано" : "Скопировать",
                systemImage: viewModel.isCopied ? "checkmark" : "doc.on.doc"
            )
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(viewModel.isCopied ? .green : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 10))
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isCopied)
    }

    private var continueButton: some View {
        Button(action: viewModel.didTapContinue) {
            Text("Продолжить")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(viewModel.canContinue ? .black : AppTheme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.radiusPill)
                        .fill(viewModel.canContinue ? AppTheme.accent : AppTheme.surface)
                )
        }
        .disabled(!viewModel.canContinue)
        .animation(.easeInOut(duration: 0.2), value: viewModel.canContinue)
    }
}

private struct WordCell: View {
    let index: Int
    let word: String
    let isRevealed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(index)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color(white: 0.4))

            Text(isRevealed ? word : "•••••")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .blur(radius: isRevealed ? 0 : 4)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 10))
        .animation(.easeInOut(duration: 0.3), value: isRevealed)
    }
}

#Preview {
    NavigationStack {
        GenerateMnemonicView(
            viewModel: GenerateMnemonicViewModel(
                coordinator: OnboardingCoordinator(),
                cryptoService: CryptoServiceMock(),
                keychainService: KeychainServiceMock()
            )
        )
    }
}
