//
//  SettingsView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 16/3/26.
//

import SwiftUI
import PhotosUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var showLogoutAlert = false
    @State private var showQRSheet = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    avatarSection
                    nicknameSection
                    if let error = viewModel.saveError {
                        errorBanner(error)
                    }
                    addressSection
                    Spacer(minLength: 32)
                    qrButton
                    logoutButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }

            if viewModel.isSaving {
                savingOverlay
            }
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: photoItem) { _, newItem in
            Task {
                guard let newItem,
                      let data = try? await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                viewModel.setAvatar(image)
                photoItem = nil
            }
        }
        .onChange(of: viewModel.savedSuccessfully) { _, success in
            if success {
                viewModel.savedSuccessfully = false
            }
        }
        .alert("Выйти из аккаунта?", isPresented: $showLogoutAlert) {
            Button("Выйти", role: .destructive) { viewModel.logout() }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Все данные аккаунта будут удалены с устройства. Сохраните мнемоническую фразу заранее.")
        }
        .sheet(isPresented: $showQRSheet) {
            QRCodeSheet(address: viewModel.address)
        }
        .preferredColorScheme(.dark)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    avatarCircle
                    editBadge
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSaving)

            Text("Нажмите, чтобы изменить фото")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var avatarCircle: some View {
        Group {
            if let image = viewModel.avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(width: 100, height: 100)
        .background(AppTheme.surface)
        .clipShape(Circle())
        .overlay(Circle().stroke(AppTheme.surfaceHigh, lineWidth: 2))
    }

    private var editBadge: some View {
        Image(systemName: "camera.fill")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppTheme.background)
            .padding(7)
            .background(AppTheme.accent, in: Circle())
            .offset(x: 4, y: 4)
    }

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Никнейм")

            HStack(spacing: 10) {
                TextField("Введите никнейм", text: $viewModel.nickname)
                    .foregroundStyle(AppTheme.textPrimary)
                    .font(.system(size: 15))
                    .submitLabel(.done)
                    .onSubmit { viewModel.saveProfile() }
                    .disabled(viewModel.isSaving)
                    .onChange(of: viewModel.nickname) { _, newValue in
                        viewModel.nicknameDidChange(newValue)
                    }

                if viewModel.hasUnsavedChanges && !viewModel.isSaving {
                    Button {
                        viewModel.saveProfile()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.radiusCard))
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.leading)
            Spacer()
            Button {
                viewModel.saveError = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: AppTheme.radiusCard))
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Адрес кошелька")

            HStack(spacing: 10) {
                Text(viewModel.address.isEmpty ? "—" : viewModel.address)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !viewModel.address.isEmpty {
                    Button {
                        UIPasteboard.general.string = viewModel.address
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.radiusCard))
        }
    }

    private var qrButton: some View {
        Button {
            showQRSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "qrcode")
                    .font(.system(size: 17, weight: .semibold))
                Text("Показать QR-код")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.radiusPill))
            .foregroundStyle(AppTheme.textPrimary)
        }
        .disabled(viewModel.address.isEmpty)
    }

    private var logoutButton: some View {
        Button {
            showLogoutAlert = true
        } label: {
            HStack(spacing: 10) {
                if viewModel.isLoggingOut {
                    ProgressView()
                        .tint(AppTheme.background)
                } else {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Выйти из аккаунта")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: AppTheme.radiusPill))
            .foregroundStyle(.white)
        }
        .disabled(viewModel.isLoggingOut || viewModel.isSaving)
        .padding(.bottom, 32)
    }

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(AppTheme.accent)
                Text("Сохранение профиля…")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(28)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.radiusCard))
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppTheme.textTertiary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

private struct QRCodeSheet: View {
    let address: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Text("Адрес кошелька")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                if let qrImage = generateQR(from: address) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .padding(16)
                        .background(.white, in: RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                }

                Text(address)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    UIPasteboard.general.string = address
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.doc")
                        Text("Скопировать адрес")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.radiusPill))
                }

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func generateQR(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
