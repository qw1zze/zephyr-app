//
//  VerifyMnemonicView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import SwiftUI

struct VerifyMnemonicView: View {
    @ObservedObject var viewModel: VerifyMnemonicViewModel
    @FocusState private var focusedIndex: Int?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                inputWords
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                if let error = viewModel.error {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                }

                Spacer()

                confirmButton
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isValid)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .navigationTitle("Верификация")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onTapGesture { focusedIndex = nil }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Text("Подтвердите фразу")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text("Введите слова под указанными номерами")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color(white: 0.55))
                .multilineTextAlignment(.center)
        }
    }
    
    private var inputWords: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.wordsToVerify) { verifyWord in
                WordInputField(
                    label: "Слово #\(verifyWord.index)",
                    text: binding(for: verifyWord.index),
                    state: viewModel.wordState(for: verifyWord.index),
                    isFocused: focusedIndex == verifyWord.index
                )
                .focused($focusedIndex, equals: verifyWord.index)
            }
        }
    }
    
    private var confirmButton: some View {
        Button {
            Task { await viewModel.confirm() }
        } label: {
            ZStack {
                if viewModel.isLoading {
                    ProgressView().tint(.black)
                } else {
                    Text("Подтвердить")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(viewModel.isValid ? .black : Color(white: 0.35))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(viewModel.isValid ? Color.white : Color(white: 0.15))
            )
        }
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { viewModel.userInputs[index] ?? "" },
            set: { viewModel.userInputs[index] = $0 }
        )
    }
}

#Preview {
    NavigationStack {
        VerifyMnemonicView(
            viewModel: VerifyMnemonicViewModel(
                coordinator: OnboardingCoordinator(),
                words: ["apple","brave","crane","desert","eagle","forest",
                        "grape","honor","island","jungle","knight","lemon"],
                cryptoService: CryptoServiceMock(),
                keychainService: KeychainServiceMock()
            )
        )
    }
}
