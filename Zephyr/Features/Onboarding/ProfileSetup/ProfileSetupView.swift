//
//  ProfileSetupView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 25/4/26.
//

import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @ObservedObject var viewModel: ProfileSetupViewModel
    @State private var photoItem: PhotosPickerItem? = nil
    @FocusState private var nicknameFocused: Bool

    var body: some View {
        ZStack {
            ZephyrBackground(showGrid: false, showScanline: false)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, 52)

                Spacer()

                avatarPicker
                    .padding(.bottom, 36)

                nicknameField
                    .padding(.horizontal, 24)

                Spacer()

                buttons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
        .contentShape(Rectangle())
        .onTapGesture { nicknameFocused = false }
        .onChange(of: photoItem) { _, newItem in
            Task {
                guard let newItem,
                      let data = try? await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                viewModel.setAvatar(image)
                photoItem = nil
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Настройте профиль")
                .font(NewAppTheme.Fonts.title)
                .foregroundStyle(NewAppTheme.Colors.textPrimary)

            Text("Вы всегда можете изменить это в настройках")
                .font(NewAppTheme.Fonts.caption)
                .foregroundStyle(NewAppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private var avatarPicker: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let image = viewModel.avatarImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Circle()
                                .fill(NewAppTheme.Colors.lemon.opacity(0.06))
                                .frame(width: 120, height: 120)
                                .blur(radius: 16)

                            Image(systemName: "person.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(NewAppTheme.Colors.textSecondary)
                        }
                    }
                }
                .frame(width: 112, height: 112)
                .background(NewAppTheme.Colors.bg2)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(NewAppTheme.Colors.lemon.opacity(0.25), lineWidth: 1.5)
                )

                Image(systemName: "camera.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NewAppTheme.Colors.bg)
                    .padding(8)
                    .background(NewAppTheme.Colors.lemon, in: Circle())
                    .offset(x: 4, y: 4)
            }
        }
        .buttonStyle(.plain)
    }

    private var nicknameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("НИКНЕЙМ")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(NewAppTheme.Colors.textTertiary)
                .tracking(1)

            HStack(spacing: 10) {
                TextField("Введите никнейм", text: $viewModel.nickname)
                    .foregroundStyle(NewAppTheme.Colors.textPrimary)
                    .font(.system(size: 15))
                    .submitLabel(.done)
                    .focused($nicknameFocused)
                    .onSubmit { nicknameFocused = false }

                if !viewModel.nickname.isEmpty {
                    Button {
                        viewModel.nickname = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(NewAppTheme.Colors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(NewAppTheme.Colors.bg2, in: RoundedRectangle(cornerRadius: NewAppTheme.radiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: NewAppTheme.radiusSmall)
                    .stroke(
                        nicknameFocused
                            ? NewAppTheme.Colors.lemon.opacity(0.4)
                            : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
                    .animation(.easeInOut(duration: 0.2), value: nicknameFocused)
            )
        }
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            Button("Продолжить") {
                viewModel.saveAndContinue()
            }
            .buttonStyle(ZephyrButtonStyle(filled: true))

            Button("Пропустить") {
                viewModel.skip()
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(NewAppTheme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileSetupView(viewModel: ProfileSetupViewModel(onComplete: {}))
    }
}
