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
        let onPickImage: () -> Void
        let onPickFile: () -> Void

        @State private var showAttachmentMenu = false

        var body: some View {
            HStack(alignment: .bottom, spacing: 8) {
                attachmentButton

                messageField

                sendButton
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.background)
        }

        private var attachmentButton: some View {
            Button(action: { showAttachmentMenu = true }) {
                Image(systemName: "paperclip")
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .confirmationDialog("", isPresented: $showAttachmentMenu) {
                Button("Изображение") { onPickImage() }
                Button("Файл") { onPickFile() }
                Button("Отмена", role: .cancel) {}
            }
        }

        private var messageField: some View {
            TextField("Сообщение", text: $text, axis: .vertical)
                .lineLimit(1...5)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput))
        }

        private var sendButton: some View {
            let canSend = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 34, height: 34)
                    .background(canSend ? AppTheme.accent : AppTheme.surfaceHigh)
                    .clipShape(Circle())
            }
            .disabled(!canSend)
            .animation(.easeInOut(duration: 0.15), value: canSend)
        }
    }
}
