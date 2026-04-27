//
//  ZephyrButtonStyle.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 25/4/26.
//

import SwiftUI

struct ZephyrButtonStyle: ButtonStyle {
    var filled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(filled ? NewAppTheme.Colors.lemon : Color.clear)
            .foregroundColor(filled ? NewAppTheme.Colors.bg : .white)
            .cornerRadius(NewAppTheme.radiusButton)
            .overlay(
                RoundedRectangle(cornerRadius: NewAppTheme.radiusButton)
                    .stroke(Color.white.opacity(0.18), lineWidth: filled ? 0 : 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.15), value: configuration.isPressed)
    }
}
