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

        private var canSend: Bool {
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var body: some View {
            VStack(spacing: 0) {
                Divider()
                    .background(AppTheme.separator)

                HStack(alignment: .bottom, spacing: 10) {
                    attachmentButton

                    inputFieldWithSend
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.background)
            }
        }

        private var attachmentButton: some View {
            Button(action: { showAttachmentMenu = true }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.surfaceHigh)
                        .frame(width: 36, height: 36)
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .confirmationDialog("", isPresented: $showAttachmentMenu) {
                Button("Изображение") { onPickImage() }
                Button("Файл") { onPickFile() }
                Button("Отмена", role: .cancel) {}
            }
        }

        private var inputFieldWithSend: some View {
            HStack(alignment: .bottom, spacing: 6) {
                TextField("Сообщение...", text: $text, axis: .vertical)
                    .lineLimit(1...5)
                    .foregroundStyle(AppTheme.textPrimary)
                    .tint(AppTheme.accent)
                    .padding(.leading, 14)
                    .padding(.trailing, 6)
                    .padding(.vertical, 9)

                sendButton
                    .padding(.bottom, 5)
                    .padding(.trailing, 5)
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput))
        }

        private var sendButton: some View {
            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(canSend ? .black : AppTheme.textTertiary)
                    .frame(width: 30, height: 30)
                    .background(canSend ? AppTheme.accent : AppTheme.surfaceHigh)
                    .clipShape(Circle())
            }
            .disabled(!canSend)
            .animation(.easeInOut(duration: 0.15), value: canSend)
        }
    }
}
