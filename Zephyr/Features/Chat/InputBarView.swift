//
//  InputBarView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import SwiftUI

extension ChatView {
    struct InputBarView: View {
        @Binding var text: String
        let onSend: () -> Void

        var body: some View {
            HStack(alignment: .bottom, spacing: 8) {
                messageField

                sendButton
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 4, y: -2)
        }
        
        private var messageField: some View {
            TextField("Сообщение", text: $text, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        
        private var sendButton: some View {
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}
