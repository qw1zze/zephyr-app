//
//  ChatRowView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import SwiftUI
import UIKit

extension ChatListView {
    struct ChatRowView: View {
        let chat: ChatModel
        let onTap: () -> Void

        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 14) {
                    avatar

                    chatInfo

                    Spacer()

                    if let date = chat.lastMessageDate {
                        chatDate(date: date)
                    }
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        
        private var avatar: some View {
            Circle()
                .fill(AppTheme.surface)
                .frame(width: 50, height: 50)
                .overlay {
                    if let data = chat.recipientAvatarData,
                       !chat.isGroupChat,
                       let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: chat.isGroupChat ? "person.3.fill" : "person.fill")
                            .font(.system(size: chat.isGroupChat ? 18 : 22))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
        }
        
        private var chatInfo: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(chatDisplayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                if let preview = chat.lastMessagePreview {
                    Text(preview)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        
        private var chatDisplayName: String {
            if chat.isGroupChat {
                return "Группа · \(chat.participantAddresses.count + 1) участника"
            }
            if let nickname = chat.recipientNickname, !nickname.isEmpty {
                return nickname
            }
            return shortAddress(chat.recipientAddress)
        }
        
        private func chatDate(date: Date) -> some View {
            Text(formattedDate(date))
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textTertiary)
        }

        private func shortAddress(_ address: String) -> String {
            guard address.count >= 10 else { return address }
            let prefix = address.prefix(6)
            let suffix = address.suffix(4)
            return "\(prefix)...\(suffix)"
        }

        private func formattedDate(_ date: Date) -> String {
            let calendar = Calendar.current
            if calendar.isDateInToday(date) {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return formatter.string(from: date)
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM"
                return formatter.string(from: date)
            }
        }
    }
}
