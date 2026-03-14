//
//  CreateChatSheet.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import SwiftUI

struct CreateChatSheet: View {
    @ObservedObject var viewModel: ChatListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    addressBlock

                    Spacer()

                    createButton
                        .disabled(viewModel.addressValidation != .valid || viewModel.isCreatingChat)
                }
                .padding(24)
            }
            .navigationTitle("Новый чат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        viewModel.resetCreateChat()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: viewModel.createdChatID) { _, id in
            if id != nil { dismiss() }
        }
    }
    
    private var addressBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ethereum адрес")
                .font(.system(size: 13))
                .foregroundStyle(Color(white: 0.45))

            addressField
                .onChange(of: viewModel.newChatAddress) { _, newValue in
                    Task { await viewModel.validateAddress(newValue) }
                }

            validationLabel
        }
    }
    
    private var addressField: some View {
        TextField("0x...", text: $viewModel.newChatAddress)
            .font(.system(size: 15, design: .monospaced))
            .foregroundStyle(.white)
            .tint(.white)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(white: 0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var validationLabel: some View {
        switch viewModel.addressValidation {
        case .idle:
            EmptyView()
        case .invalidFormat:
            Text("Неверный формат адреса")
                .font(.system(size: 12))
                .foregroundStyle(.red)
        case .checking:
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(Color(white: 0.5))
                Text("Проверяем реестр...")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.45))
            }
        case .notFound:
            Text("Ключ не найден в реестре")
                .font(.system(size: 12))
                .foregroundStyle(.yellow)
        case .valid:
            Text("Адрес найден")
                .font(.system(size: 12))
                .foregroundStyle(.green)
        }
    }
    
    private var createButton: some View {
        Button {
            Task {
                await viewModel.createChat(recipientAddress: viewModel.newChatAddress)
            }
        } label: {
            ZStack {
                if viewModel.isCreatingChat {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text("Создать чат")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                viewModel.addressValidation == .valid
                    ? Color.white
                    : Color(white: 0.25),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
    }
}
