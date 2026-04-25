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

            VStack(spacing: 15) {
                warningBanner
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(AppTheme.accent)
                    Spacer()
                } else {
                    wordGrid
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    HStack(spacing: 8) {
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { viewModel.didTapBack() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(NewAppTheme.Colors.lemon)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await viewModel.generateMnemonic() }
    }

    private var warningBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(NewAppTheme.Colors.lemon)
                .font(.system(size: 15, weight: .medium))
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 3) {
                Text("Запишите эти 12 слов в безопасном месте. Они являются единственным способом восстановить кошелёк.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(white: 0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 15)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(NewAppTheme.Colors.lemon.opacity(0.3), lineWidth: 1)
        }
        .background(NewAppTheme.Colors.bg3, in: RoundedRectangle(cornerRadius: 16))
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
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            }
            .background(NewAppTheme.Colors.bg3, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var copyButton: some View {
        Button(action: viewModel.copyToClipboard) {
            Label(
                viewModel.isCopied ? "Скопировано" : "Скопировать",
                systemImage: "doc.on.doc"
            )
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(viewModel.isCopied ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            }
            .background(
                viewModel.isCopied ? NewAppTheme.Colors.lemon.opacity(0.8) : NewAppTheme.Colors.bg3,
                in: RoundedRectangle(cornerRadius: 10)
            )
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isCopied)
    }

    private var continueButton: some View {
        Button(action: viewModel.didTapContinue) {
            Text("Продолжить")
        }
        .buttonStyle(ZephyrButtonStyle(filled: true))
        .opacity(viewModel.canContinue ? 1 : 0.5)
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
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
        .background(NewAppTheme.Colors.bg3, in: RoundedRectangle(cornerRadius: 10))
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
