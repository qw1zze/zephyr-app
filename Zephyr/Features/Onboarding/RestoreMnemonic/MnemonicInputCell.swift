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
            if isInvalid { return .red.opacity(0.8) }
            if isFocused { return NewAppTheme.Colors.lemon.opacity(0.6) }
            return .white.opacity(0.1)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(index + 1)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))

                TextField("", text: $word)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .foregroundStyle(.white)
                    .font(.system(size: 13, weight: .semibold))
                    .onSubmit(onCommit)
                    .onChange(of: word) { newValue in
                        if newValue.contains(" ") {
                            onPaste(newValue)
                        }
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(NewAppTheme.Colors.bg3, in: RoundedRectangle(cornerRadius: NewAppTheme.radiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: NewAppTheme.radiusSmall)
                    .stroke(borderColor, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isInvalid)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
    }
}
