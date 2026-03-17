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

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    avatarSection
                    nicknameSection
                    addressSection
                    Spacer(minLength: 32)
                    logoutButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.large)
        .photosPicker(
            isPresented: Binding(
                get: { photoItem != nil },
                set: { if !$0 { photoItem = nil } }
            ),
            selection: $photoItem,
            matching: .images
        )
        .onChange(of: photoItem) { _, newItem in
            Task {
                guard let newItem,
                      let data = try? await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                viewModel.setAvatar(image)
                photoItem = nil
            }
        }
        .alert("Выйти из аккаунта?", isPresented: $showLogoutAlert) {
            Button("Выйти", role: .destructive) { viewModel.logout() }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Все данные аккаунта будут удалены с устройства. Сохраните мнемоническую фразу заранее.")
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
                    .onSubmit { viewModel.saveNickname() }

                if !viewModel.nickname.isEmpty {
                    Button {
                        viewModel.saveNickname()
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
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.radiusCard))
        }
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
        .disabled(viewModel.isLoggingOut)
        .padding(.bottom, 32)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppTheme.textTertiary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}
