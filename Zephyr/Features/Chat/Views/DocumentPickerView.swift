//
//  DocumentPickerView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 24/4/26.
//

import SwiftUI
import UniformTypeIdentifiers

extension ChatView {
    struct DocumentPickerView: UIViewControllerRepresentable {
        let onPick: (Data, String) -> Void

        func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

        func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .item], asCopy: true)
            picker.delegate = context.coordinator
            picker.allowsMultipleSelection = false
            return picker
        }

        func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

        final class Coordinator: NSObject, UIDocumentPickerDelegate {
            let onPick: (Data, String) -> Void
            init(onPick: @escaping (Data, String) -> Void) { self.onPick = onPick }

            func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                guard let url = urls.first,
                      let data = try? Data(contentsOf: url) else { return }
                onPick(data, url.lastPathComponent)
            }
        }
    }
}
