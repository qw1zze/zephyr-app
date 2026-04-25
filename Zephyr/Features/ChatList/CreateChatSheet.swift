//
//  CreateChatSheet.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import SwiftUI
import UIKit
import AVFoundation

private let accentLime = Color(red: 0.78, green: 1.0, blue: 0.0)

private struct ScanTarget: Identifiable {
    let id = UUID()
    let entryID: UUID
}

struct CreateChatSheet: View {
    @ObservedObject var viewModel: ChatListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var scanningEntryID: ScanTarget?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            recipientsList
                            addRecipientButton
                            Spacer(minLength: 24)
                        }
                        .padding(24)
                    }

                    createButton
                        .disabled(!viewModel.canCreateChat)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .padding(.top, 12)
                }
            }
            .navigationTitle("Новый чат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        viewModel.resetCreateChat()
                        dismiss()
                    }
                    .foregroundStyle(accentLime)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: viewModel.createdChatID) { _, id in
            if id != nil { dismiss() }
        }
        .sheet(item: $scanningEntryID) { target in
            QRScannerSheet { scanned in
                Task { await viewModel.validateEntry(id: target.entryID, value: scanned) }
            }
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
                    },
                    onCameraTap: { scanningEntryID = ScanTarget(entryID: entry.id) }
                )
            }
        }
    }

    private var addRecipientButton: some View {
        Button {
            viewModel.addAddressEntry()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(white: 0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accentLime)
                }
                Text("Добавить участника")
                    .font(.system(size: 15))
                    .foregroundStyle(accentLime)
            }
        }
    }

    private var createButton: some View {
        Button {
            Task { await viewModel.createChat() }
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
            .padding(.vertical, 18)
            .background(
                viewModel.canCreateChat ? accentLime : Color(white: 0.18),
                in: Capsule()
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
    let onCameraTap: () -> Void

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

            HStack(spacing: 0) {
                TextField("0x...", text: $text)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Button(action: onCameraTap) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(white: 0.5))
                        .padding(.leading, 8)
                }
            }
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
            resolvedCard
        }
    }

    private var resolvedCard: some View {
        HStack(spacing: 10) {
            avatarThumbnail

            Text(entry.profileName ?? truncated(entry.text))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(accentLime)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    private var avatarThumbnail: some View {
        Group {
            if let data = entry.avatarData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(white: 0.2))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(white: 0.5))
                    }
            }
        }
    }

    private func truncated(_ address: String) -> String {
        guard address.count > 12 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }
}
