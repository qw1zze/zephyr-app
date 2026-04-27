//
//  BackButton.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 25/4/26.
//

import SwiftUI

struct BackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
        }
    }
}
