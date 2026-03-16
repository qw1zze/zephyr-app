//
//  RestoreMnemonicView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import SwiftUI

struct RestoreMnemonicView: View {
    @ObservedObject var viewModel: RestoreMnemonicViewModel
    @FocusState private var focusedIndex: Int?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                mnemonicGrid
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                if let error = viewModel.error {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                        Text(error)
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                }
                
                Spacer()

                restoreButton
                    .disabled(!viewModel.isReady)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isReady)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
            }
        }
        .navigationTitle("Восстановление кошелька")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onTapGesture { focusedIndex = nil }
    }
    
    private var mnemonicGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<12, id: \.self) { index in
                MnemonicInputCell(
                    index: index,
                    word: wordBinding(for: index),
                    isInvalid: viewModel.invalidWords.contains(index),
                    isFocused: focusedIndex == index,
                    onCommit: {
                        viewModel.validateWord(at: index)
                        focusedIndex = index + 1 < 12 ? index + 1 : nil
                    },
                    onPaste: { text in
                        focusedIndex = nil
                        viewModel.handlePaste(text: text, intoIndex: index)
                    }
                )
                .focused($focusedIndex, equals: index)
            }
        }
    }
    
    private var restoreButton: some View {
        Button {
            focusedIndex = nil
            Task { await viewModel.restore() }
        } label: {
            ZStack {
                if viewModel.isLoading {
                    ProgressView().tint(.black)
                } else {
                    Text("Восстановить кошелёк")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(viewModel.isReady ? .black : AppTheme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusPill)
                    .fill(viewModel.isReady ? AppTheme.accent : AppTheme.surface)
            )
        }
    }

    private func wordBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                guard index < viewModel.words.count else { return "" }
                return viewModel.words[index]
            },
            set: {
                guard index < viewModel.words.count else { return }
                viewModel.words[index] = $0
            }
        )
    }
}

#Preview {
    NavigationStack {
        RestoreMnemonicView(
            viewModel: RestoreMnemonicViewModel(
                coordinator: OnboardingCoordinator(),
                cryptoService: CryptoServiceMock(),
                keychainService: KeychainServiceMock()
            )
        )
    }
}
