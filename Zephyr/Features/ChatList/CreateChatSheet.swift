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

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        recipientsList

                        addRecipientButton

                        Spacer(minLength: 24)

                        createButton
                            .disabled(!viewModel.canCreateChat)
                    }
                    .padding(24)
                }
            }
            .navigationTitle(viewModel.addressEntries.count > 1 ? "Новая группа" : "Новый чат")
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
    
    private var recipientsList: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(viewModel.addressEntries.enumerated()), id: \.element.id) { index, entry in
                AddressEntryRow(
                    entry: entry,
                    label: viewModel.addressEntries.count > 1 ? "Участник \(index + 1)" : "Ethereum адрес",
                    canRemove: viewModel.addressEntries.count > 1,
                    onRemove: { viewModel.removeAddressEntry(id: entry.id) },
                    onChange: { newValue in
                        Task { await viewModel.validateEntry(id: entry.id, value: newValue) }
                    }
                )
            }
        }
    }

    private var addRecipientButton: some View {
        Button {
            viewModel.addAddressEntry()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 17))
                Text("Добавить участника")
                    .font(.system(size: 15))
            }
            .foregroundStyle(Color.white.opacity(0.6))
        }
    }

    private var createButton: some View {
        Button {
            Task {
                await viewModel.createChat()
            }
        } label: {
            ZStack {
                if viewModel.isCreatingChat {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text(viewModel.addressEntries.count > 1 ? "Создать группу" : "Создать чат")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                viewModel.canCreateChat
                    ? Color.white
                    : Color(white: 0.25),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
    }
}

private struct AddressEntryRow: View {
    let entry: AddressEntry
    let label: String
    let canRemove: Bool
    let onRemove: () -> Void
    let onChange: (String) -> Void

    @State private var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.45))
                Spacer()
                if canRemove {
                    Button(action: onRemove) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(white: 0.4))
                    }
                }
            }

            TextField("0x...", text: $text)
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(.white)
                .tint(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(white: 0.1), in: RoundedRectangle(cornerRadius: 10))
                .onChange(of: text) { _, newValue in
                    onChange(newValue)
                }
                .onAppear {
                    text = entry.text
                }

            validationLabel(for: entry.validation)
        }
        .onChange(of: entry.text) { _, newText in
            if text != newText { text = newText }
        }
    }

    @ViewBuilder
    private func validationLabel(for validation: AddressValidation) -> some View {
        switch validation {
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
}
