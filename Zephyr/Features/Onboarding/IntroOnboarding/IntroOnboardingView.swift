//
//  IntroOnboardingView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 25/4/26.
//

import SwiftUI

private struct IntroSlide {
    let iconPrimary: String
    let title: String
    let subtitle: String
}

struct IntroOnboardingView: View {
    let onFinish: () -> Void

    @State private var currentPage = 0

    private let slides: [IntroSlide] = [
        IntroSlide(
            iconPrimary: "onboarding1",
            title: "Полная приватность",
            subtitle: "Сквозное шифрование на каждое сообщение. Никаких серверных копий."
        ),
        IntroSlide(
            iconPrimary: "onboarding2",
            title: "Блокчейн-хранение",
            subtitle: "Ваши сообщения хранятся с использованием блокчейна — децентрализованно и без единой точки уязвимости."
        ),
        IntroSlide(
            iconPrimary: "onboarding3",
            title: "Анонимные группы",
            subtitle: "Общайтесь в закрытых кругах. Никто не узнает, кто вы."
        )
    ]

    var body: some View {
        ZStack {
            ZephyrBackground(showGrid: true, showScanline: true, showCRT: true)

            VStack(spacing: 0) {
                Spacer()
                
                TabView(selection: $currentPage) {
                    ForEach(slides.indices, id: \.self) { index in
                        slideContent(slides[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                .frame(height: 350)

                pageIndicator
                
                Spacer()

                actionButton
                    .buttonStyle(ZephyrButtonStyle(filled: true))
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
    }

    private func slideContent(_ slide: IntroSlide) -> some View {
        VStack(spacing: 20) {
            iconView(slide)
            textBlock(slide)
        }
        .padding(.bottom, 8)
    }

    private func iconView(_ slide: IntroSlide) -> some View {
        ZStack {
            Image(slide.iconPrimary)
                .renderingMode(.original)
                .frame(width: 160, height: 160)
        }
    }

    private func textBlock(_ slide: IntroSlide) -> some View {
        VStack(spacing: 12) {
            Text(slide.title)
                .font(NewAppTheme.Fonts.title)
                .foregroundStyle(NewAppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(slide.subtitle)
                .font(NewAppTheme.Fonts.body)
                .foregroundStyle(NewAppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(slides.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? AppTheme.accent : Color(white: 0.35))
                    .frame(width: index == currentPage ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }

    private var actionButton: some View {
        Button {
            if currentPage < slides.count - 1 {
                withAnimation {
                    currentPage += 1
                }
            } else {
                onFinish()
            }
        } label: {
            Text(currentPage == slides.count - 1 ? "Начать →" : "Далее")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

#Preview {
    IntroOnboardingView(onFinish: {})
}
