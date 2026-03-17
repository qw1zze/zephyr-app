//
//  MnemonicInputCell.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import SwiftUI

extension RestoreMnemonicView {
    struct MnemonicInputCell: View {
        let index: Int
        @Binding var word: String
        let isInvalid: Bool
        let isFocused: Bool
        let onCommit: () -> Void
        let onPaste: (String) -> Void

        private var borderColor: Color {
            if isInvalid  { return .red.opacity(0.8) }
            if isFocused  { return Color(white: 0.4) }
            return Color(white: 0.12)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(index + 1)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color(white: 0.35))

                TextField("", text: $word)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .foregroundStyle(.white)
                    .font(.system(size: 12, weight: .medium))
                    .onSubmit(onCommit)
                    .onChange(of: word) { newValue in
                        if newValue.contains(" ") {
                            onPaste(newValue)
                        }
                    }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color(white: 0.07), in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isInvalid)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
    }
}
