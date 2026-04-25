//
//  NewAppTheme.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 25/4/26.
//

import SwiftUI

enum NewAppTheme {
    enum Colors {
        static let lemon = Color(hex: "D9F000")
        static let lemonDark = Color(hex: "B8CC00")
        static let bg = Color(hex: "0A0A0A")
        static let bg2 = Color(hex: "111111")
        static let bg3 = Color(hex: "1A1A1A")

        static let textPrimary   = Color.white
        static let textSecondary = Color.white.opacity(0.45)
        static let textTertiary  = Color.white.opacity(0.25)
    }

    static let radiusSmall:  CGFloat = 12
    static let radiusMedium: CGFloat = 16
    static let radiusLarge:  CGFloat = 18
    static let radiusButton: CGFloat = 18
    
    enum Fonts {
        static let title = Font.system(size: 26, weight: .bold,   design: .default)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 15, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
    }
}
