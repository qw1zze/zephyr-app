//
//  ChatInfoView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 25/4/26.
//

import SwiftUI

struct ChatInfoView: View {
    let viewModel: ChatViewModel

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.isGroupChat {
                    groupContent
                } else {
                    personalContent
                }
            }
            .navigationTitle("О чате")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
        }
    }

    private var personalContent: some View {
        VStack(spacing: 24) {
            avatarView
                .padding(.top, 32)

            VStack(spacing: 6) {
                if let nickname = viewModel.recipientNickname, !nickname.isEmpty {
                    Text(nickname)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                addressBadge(viewModel.recipientAddress)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var avatarView: some View {
        Circle()
            .fill(AppTheme.surface)
            .frame(width: 90, height: 90)
            .overlay {
                if let data = viewModel.recipientAvatarData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
    }

    private var groupContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                groupHeader
                    .padding(.bottom, 16)

                Text("Участники")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                VStack(spacing: 0) {
                    participantRow(address: viewModel.myAddress, label: "Вы", isLast: false)

                    ForEach(Array(viewModel.recipientAddresses.enumerated()), id: \.offset) { index, address in
                        participantRow(
                            address: address,
                            label: nil,
                            isLast: index == viewModel.recipientAddresses.count - 1
                        )
                    }
                }
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                .padding(.horizontal, 16)
            }
            .padding(.top, 24)
        }
    }

    private var groupHeader: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(AppTheme.surface)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.textSecondary)
                }

            VStack(alignment: .leading, spacing: 4) {
                if let alias = viewModel.localAlias, !alias.isEmpty {
                    Text(alias)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                Text("Группа · \(viewModel.recipientAddresses.count + 1) участника")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
    }

    private func participantRow(address: String, label: String?, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Circle()
                    .fill(AppTheme.surfaceHigh)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    if let label {
                        Text(label)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if !isLast {
                Divider()
                    .background(AppTheme.separator)
                    .padding(.leading, 62)
            }
        }
    }

    private func addressBadge(_ address: String) -> some View {
        Text(address)
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
    }
}
