//
//  MessageBubbleView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: MessageModel
    let isOutgoing: Bool

    var body: some View {
        HStack(alignment: .bottom) {
            if isOutgoing {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 4) {
                messageContent

                messageInfo
            }
            
            if !isOutgoing {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 8)
    }
    
    @ViewBuilder
    private var messageContent: some View {
        if message.isImageMessage, let data = message.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 240)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        } else {
            Text(message.plaintext ?? "")
                .font(.system(size: 16))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isOutgoing ? AppTheme.accent : AppTheme.surface)
                .foregroundColor(isOutgoing ? .black : AppTheme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
    
    private var messageInfo: some View {
        HStack(spacing: 4) {
            Text(message.timestamp.formatted(.dateTime.hour().minute()))
                .font(.caption2)
                .foregroundColor(AppTheme.textTertiary)
            if isOutgoing {
                StatusIcon(status: message.messageStatus)
            }
        }
    }
}

extension MessageBubbleView {
    private struct StatusIcon: View {
        let status: MessageModel.MessageStatus

        var body: some View {
            Group {
                switch status {
                case .pending:
                    Image(systemName: "clock")
                        .foregroundColor(AppTheme.textTertiary)
                case .sent:
                    Image(systemName: "checkmark")
                        .foregroundColor(AppTheme.textTertiary)
                case .delivered:
                    HStack(spacing: -3) {
                        Image(systemName: "checkmark")
                        Image(systemName: "checkmark")
                    }
                    .foregroundColor(AppTheme.accent)
                }
            }
            .font(.caption2)
        }
    }
}
