//
//  IntroOnboardingView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 25/4/26.
//

import SwiftUI

private struct IntroSlide {
    let iconPrimary: String
    let iconBadge: String?
    let title: String
    let subtitle: String
}

struct IntroOnboardingView: View {
    let onFinish: () -> Void

    @State private var currentPage = 0

    private let slides: [IntroSlide] = [
        IntroSlide(
            iconPrimary: "envelope.fill",
            iconBadge: "checkmark.circle.fill",
            title: "Полная приватность",
            subtitle: "Сквозное шифрование на каждое сообщение. Никаких серверных копий."
        ),
        IntroSlide(
            iconPrimary: "cpu",
            iconBadge: nil,
            title: "Блокчейн-хранение",
            subtitle: "Ваши сообщения хранятся с использованием блокчейна — децентрализованно и без единой точки уязвимости."
        ),
        IntroSlide(
            iconPrimary: "scope",
            iconBadge: nil,
            title: "Анонимные группы",
            subtitle: "Общайтесь в закрытых кругах. Никто не узнает, кто вы."
        )
    ]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            IntroGridBackground()
            IntroScatteredDots()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(slides.indices, id: \.self) { index in
                        slideContent(slides[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                pageIndicator
                    .padding(.top, 32)

                actionButton
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
    }

    private func slideContent(_ slide: IntroSlide) -> some View {
        VStack(spacing: 0) {
            Spacer()
            iconView(slide)
            Spacer()
            textBlock(slide)
        }
        .padding(.bottom, 8)
    }

    private func iconView(_ slide: IntroSlide) -> some View {
        ZStack {
            RadialGradient(
                colors: [AppTheme.accent.opacity(0.22), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 160
            )
            .frame(width: 320, height: 320)

            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(white: 0.09))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(AppTheme.accent.opacity(0.35), lineWidth: 1)
                    )
                    .frame(width: 160, height: 160)
                    .shadow(color: AppTheme.accent.opacity(0.15), radius: 24, x: 0, y: 8)

                Image(systemName: slide.iconPrimary)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 160, height: 160)

                if let badge = slide.iconBadge {
                    Image(systemName: badge)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(AppTheme.accent)
                        .background(
                            Circle()
                                .fill(AppTheme.background)
                                .padding(-2)
                        )
                        .offset(x: 8, y: -8)
                }
            }
        }
    }

    private func textBlock(_ slide: IntroSlide) -> some View {
        VStack(spacing: 12) {
            Text(slide.title)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(slide.subtitle)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
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

private struct IntroGridBackground: View {
    var body: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 44
            let color = Color.white.opacity(0.035)
            var x: CGFloat = 0
            while x <= size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                ctx.stroke(path, with: .color(color), lineWidth: 0.5)
                x += spacing
            }
            var y: CGFloat = 0
            while y <= size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(path, with: .color(color), lineWidth: 0.5)
                y += spacing
            }
        }
        .ignoresSafeArea()
    }
}

private struct IntroScatteredDots: View {
    private let positions: [(CGFloat, CGFloat)] = [
        (0.08, 0.12), (0.88, 0.09), (0.04, 0.42), (0.92, 0.33),
        (0.14, 0.68), (0.82, 0.62), (0.28, 0.87), (0.72, 0.91),
        (0.5, 0.18), (0.48, 0.78), (0.62, 0.44), (0.22, 0.55)
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(positions.indices, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 4, height: 4)
                    .position(
                        x: positions[i].0 * geo.size.width,
                        y: positions[i].1 * geo.size.height
                    )
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    IntroOnboardingView(onFinish: {})
}
