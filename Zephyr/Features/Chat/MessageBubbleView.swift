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
                messageText

                messageInfo
            }
            
            if !isOutgoing {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 8)
    }
    
    private var messageText: some View {
        Text(message.plaintext ?? "")
            .font(.system(size: 16))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isOutgoing ? Color.blue : Color(.systemGray5))
            .foregroundColor(isOutgoing ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private var messageInfo: some View {
        HStack(spacing: 4) {
            Text(message.timestamp.formatted(.dateTime.hour().minute()))
                .font(.caption2)
                .foregroundColor(.secondary)
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
                        .foregroundColor(.secondary)
                case .sent:
                    Image(systemName: "checkmark")
                        .foregroundColor(.secondary)
                case .delivered:
                    HStack(spacing: -3) {
                        Image(systemName: "checkmark")
                        Image(systemName: "checkmark")
                    }
                    .foregroundColor(.blue)
                }
            }
            .font(.caption2)
        }
    }
}
