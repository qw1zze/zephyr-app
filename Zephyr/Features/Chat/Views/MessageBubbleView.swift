//
//  MessageBubbleView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import SwiftUI
import UIKit
import QuickLook

private enum BubbleLayoutWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct MessageBubbleView: View {
    let message: MessageModel
    let isOutgoing: Bool
    var senderLabel: String? = nil
    var downloadState: ChatViewModel.FileDownloadState? = nil
    var onRetry: (() -> Void)? = nil
    var onCancelDownload: (() -> Void)? = nil
    var onRetryDownload: (() -> Void)? = nil

    @State private var rowLayoutWidth: CGFloat = 0
    @State private var filePreviewURL: URL? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let label = senderLabel {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(.leading, 14)
            }

            HStack(spacing: 6) {
                if isOutgoing {
                    Spacer(minLength: 60)

                    if message.messageStatus == .failed, let onRetry {
                        Button(action: onRetry) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                    }
                }

                messageContent(layoutWidth: effectiveLayoutWidth)

                if !isOutgoing {
                    Spacer(minLength: 60)
                }
            }
        }
        .padding(.horizontal, 8)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: BubbleLayoutWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(BubbleLayoutWidthKey.self) { rowLayoutWidth = $0 }
        .quickLookPreview($filePreviewURL)
    }

    private var effectiveLayoutWidth: CGFloat {
        if rowLayoutWidth > 1 { return rowLayoutWidth }
        return max(320, UIScreen.main.bounds.width - 16)
    }

    @ViewBuilder
    private func messageContent(layoutWidth: CGFloat) -> some View {
        switch downloadState {
        case .loading:
            FileBubble(
                fileName: message.fileName ?? "Загрузка...",
                fileSize: message.imageData?.count ?? 0,
                isOutgoing: isOutgoing,
                mode: .loading
            ) { messageInfo }
            .onTapGesture { onCancelDownload?() }
        case .failed:
            FileBubble(
                fileName: message.fileName ?? "Файл",
                fileSize: message.imageData?.count ?? 0,
                isOutgoing: isOutgoing,
                mode: .retry
            ) { messageInfo }
            .onTapGesture { onRetryDownload?() }
        case .none:
            if message.isImageMessage, let data = message.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(alignment: .bottomTrailing) {
                        messageInfo
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(6)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            } else if message.isFileMessage {
                FileBubble(
                    fileName: message.fileName ?? "Файл",
                    fileSize: message.imageData?.count ?? 0,
                    isOutgoing: isOutgoing,
                    mode: .normal
                ) { messageInfo }
                .onTapGesture { openFile() }
            } else {
                TextMessageBubble(
                    text: message.plaintext ?? "",
                    isOutgoing: isOutgoing,
                    layoutWidth: layoutWidth
                ) { messageInfo }
            }
        }
    }

    private var messageInfo: some View {
        HStack(spacing: 4) {
            Text(message.timestamp.formatted(.dateTime.hour().minute()))
                .font(.system(size: 10))
                .foregroundColor(message.isImageMessage ? .white.opacity(0.85) : AppTheme.textTertiary)
            if isOutgoing {
                StatusIcon(status: message.messageStatus, onImage: message.isImageMessage)
            }
        }
    }

    private func openFile() {
        guard let data = message.imageData else { return }
        let name = message.fileName ?? "file"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try? data.write(to: url)
        filePreviewURL = url
    }
}

private enum FileBubbleMode { case normal, loading, retry }

private struct FileBubble<MessageInfo: View>: View {
    let fileName: String
    let fileSize: Int
    let isOutgoing: Bool
    let mode: FileBubbleMode
    @ViewBuilder let messageInfo: () -> MessageInfo

    private var formattedSize: String {
        switch mode {
        case .loading: 
            return "Загружается..."
        case .retry: 
            return fileSize > 0 ? sizeString : "Нажмите для загрузки"
        case .normal:
            return sizeString
        }
    }

    private var sizeString: String {
        guard fileSize > 0 else { return "" }
        let kb = Double(fileSize) / 1024
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        return String(format: "%.1f MB", kb / 1024)
    }

    private var fileExtension: String {
        (fileName as NSString).pathExtension.uppercased()
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isOutgoing ? Color.black.opacity(0.15) : AppTheme.surfaceHigh)
                    .frame(width: 40, height: 48)
                VStack(spacing: 2) {
                    switch mode {
                    case .loading:
                        ProgressView()
                            .tint(isOutgoing ? .black.opacity(0.6) : AppTheme.textSecondary)
                            .scaleEffect(0.85)
                    case .retry:
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isOutgoing ? .black.opacity(0.5) : AppTheme.textTertiary)
                    case .normal:
                        Image(systemName: "doc.fill")
                            .font(.system(size: 18))
                            .foregroundColor(isOutgoing ? .black.opacity(0.6) : AppTheme.textSecondary)
                        if !fileExtension.isEmpty {
                            Text(fileExtension)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(isOutgoing ? .black.opacity(0.5) : AppTheme.textTertiary)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(fileName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isOutgoing ? .black : AppTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Text(formattedSize)
                        .font(.system(size: 11))
                        .foregroundColor(isOutgoing ? .black.opacity(0.5) : AppTheme.textTertiary)
                    Spacer()
                    messageInfo()
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: 260)
        .background(isOutgoing ? AppTheme.accent : AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private enum TextBubbleLayoutMetrics {
    static let textFont = UIFont.systemFont(ofSize: 16)
    static let metaInlineReserve: CGFloat = 56
    static let textMetaSpacing: CGFloat = 6
    static let bubbleTextHorizontalPadding: CGFloat = 24

    static func textHeight(for text: String, maxWidth: CGFloat) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: max(1, maxWidth), height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: textFont],
            context: nil
        )
        return ceil(rect.height)
    }

    static func useInlineMeta(text: String, layoutWidth: CGFloat) -> Bool {
        let bubbleMax = max(1, layoutWidth - 60)
        let textInner = max(1, bubbleMax - bubbleTextHorizontalPadding)
        let lineCap = textFont.lineHeight * 1.08
        guard textHeight(for: text, maxWidth: textInner) <= lineCap else { return false }
        let textWithMetaRow = max(1, textInner - metaInlineReserve - textMetaSpacing)
        return textHeight(for: text, maxWidth: textWithMetaRow) <= lineCap
    }
}

private struct TextMessageBubble<MessageInfo: View>: View {
    let text: String
    let isOutgoing: Bool
    let layoutWidth: CGFloat
    @ViewBuilder let messageInfo: () -> MessageInfo

    var body: some View {
        Group {
            if TextBubbleLayoutMetrics.useInlineMeta(text: text, layoutWidth: layoutWidth) {
                HStack(alignment: .bottom, spacing: TextBubbleLayoutMetrics.textMetaSpacing) {
                    Text(text)
                        .font(.system(size: 16))
                        .foregroundColor(isOutgoing ? .black : AppTheme.textPrimary)
                        .padding(.leading, 12)
                        .padding(.trailing, 4)
                        .padding(.vertical, 6)
                    messageInfo()
                        .padding(.trailing, 8)
                        .padding(.bottom, 6)
                }
            } else {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(text)
                        .font(.system(size: 16))
                        .padding(.horizontal, 12)
                        .padding(.top, 6)
                        .foregroundColor(isOutgoing ? .black : AppTheme.textPrimary)

                    messageInfo()
                        .padding(.horizontal, 8)
                        .padding(.bottom, 6)
                }
            }
        }
        .background(isOutgoing ? AppTheme.accent : AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension MessageBubbleView {
    private struct StatusIcon: View {
        let status: MessageModel.MessageStatus
        var onImage: Bool = false

        private var tint: Color { onImage ? .white.opacity(0.85) : AppTheme.textTertiary }

        var body: some View {
            Group {
                switch status {
                case .pending:
                    Image(systemName: "clock")
                        .foregroundColor(tint)
                case .sent:
                    Image(systemName: "checkmark")
                        .foregroundColor(tint)
                case .delivered:
                    HStack(spacing: -3) {
                        Image(systemName: "checkmark")
                        Image(systemName: "checkmark")
                    }
                    .foregroundColor(onImage ? .white : AppTheme.textTertiary)
                case .failed:
                    EmptyView()
                }
            }
            .font(.system(size: 10))
        }
    }
}
