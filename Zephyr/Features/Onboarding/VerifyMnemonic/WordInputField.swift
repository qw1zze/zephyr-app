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

        private static let errorRed = Color(red: 1, green: 0.23, blue: 0.19)

        private var borderColor: Color {
            switch state {
            case .none:  return isFocused ? Color(white: 0.4) : Color(white: 0.15)
            case true:   return AppTheme.accent
            case false:  return Self.errorRed
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)

                HStack {
                    TextField("", text: $text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(.white)
                        .font(.system(size: 15))

                    if let state {
                        Image(systemName: state ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(state ? AppTheme.accent : Self.errorRed)
                            .font(.system(size: 18))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.radiusInput))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(borderColor, lineWidth: 1.5)
                )
                .animation(.easeInOut(duration: 0.2), value: state)
                .animation(.easeInOut(duration: 0.15), value: isFocused)
            }
        }
    }
}
