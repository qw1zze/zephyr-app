//
//  ChatRowView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import SwiftUI

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
                .fill(Color(white: 0.15))
                .frame(width: 46, height: 46)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(white: 0.45))
                }
        }
        
        private var chatInfo: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(shortAddress(chat.recipientAddress))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                if let preview = chat.lastMessagePreview {
                    Text(preview)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(white: 0.45))
                        .lineLimit(1)
                }
            }
        }
        
        private func chatDate(date: Date) -> some View {
            Text(formattedDate(date))
                .font(.system(size: 12))
                .foregroundStyle(Color(white: 0.35))
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
