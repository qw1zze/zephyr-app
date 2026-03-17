//
//  WordInputField.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import SwiftUI

extension VerifyMnemonicView {
    struct WordInputField: View {
        let label: String
        @Binding var text: String
        let state: Bool?
        let isFocused: Bool

        private var borderColor: Color {
            switch state {
            case .none:  return isFocused ? Color(white: 0.4) : Color(white: 0.15)
            case true:   return .green.opacity(0.7)
            case false:  return .red.opacity(0.8)
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(white: 0.5))

                HStack {
                    TextField("введите слово", text: $text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(.white)
                        .font(.system(size: 15))

                    if let state {
                        Image(systemName: state ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(state ? .green : .red)
                            .font(.system(size: 16))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 1)
                )
                .animation(.easeInOut(duration: 0.2), value: state)
                .animation(.easeInOut(duration: 0.15), value: isFocused)
            }
        }
    }
}
