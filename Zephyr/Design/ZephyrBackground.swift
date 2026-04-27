//
//  ZephyrBackground.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 25/4/26.
//

import SwiftUI

private struct Particle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let size: CGFloat
    let duration: Double
    let delay: Double
    let opacity: Double
}

private struct ParticlesView: View {
    private let particles: [Particle] = (0..<20).map { _ in
        Particle(
            x: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 2...5),
            duration: Double.random(in: 6...16),
            delay: Double.random(in: 0...8),
            opacity: Double.random(in: 0.2...0.4)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                ParticleView(
                    particle: p,
                    screenWidth: geo.size.width,
                    screenHeight: geo.size.height
                )
            }
        }
    }
}

private struct ParticleView: View {
    let particle: Particle
    let screenWidth: CGFloat
    let screenHeight: CGFloat

    @State private var offsetY: CGFloat = 0

    var body: some View {
        Circle()
            .fill(NewAppTheme.Colors.lemon.opacity(particle.opacity))
            .frame(width: particle.size, height: particle.size)
            .position(
                x: particle.x * screenWidth,
                y: screenHeight + 10 + offsetY
            )
            .onAppear {
                offsetY = 0
                withAnimation(
                    .linear(duration: particle.duration)
                    .delay(particle.delay)
                    .repeatForever(autoreverses: false)
                ) {
                    offsetY = -(screenHeight + 60)
                }
            }
    }
}

private struct OrbConfig {
    let offsetX: CGFloat
    let offsetY: CGFloat
    let size: CGFloat
    let duration: Double
    let delay: Double
    let targetX: CGFloat
    let targetY: CGFloat
}

private struct OrbView: View {
    let config: OrbConfig

    @State private var x: CGFloat = 0
    @State private var y: CGFloat = 0

    var body: some View {
        NewAppTheme.Colors.lemon
            .opacity(0.0)
            .frame(width: config.size, height: config.size)
            .background(
                RadialGradient(
                    colors: [NewAppTheme.Colors.lemon.opacity(0.2), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: config.size / 2
                )
            )
            .clipShape(Circle())
            .blur(radius: 44)
            .offset(x: config.offsetX + x, y: config.offsetY + y)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: config.duration)
                    .delay(config.delay)
                    .repeatForever(autoreverses: true)
                ) {
                    x = config.targetX
                    y = config.targetY
                }
            }
    }
}

private struct OrbsView: View {
    private let orbs: [OrbConfig] = [
        OrbConfig(offsetX: -250, offsetY: -290, size: 320, duration: 8,  delay: 0, targetX: 30,  targetY: -40),
        OrbConfig(offsetX:  -30,  offsetY:  30, size: 260, duration: 11, delay: 3, targetX: -20, targetY:  30),
    ]

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            ForEach(Array(orbs.enumerated()), id: \.offset) { _, orb in
                OrbView(config: OrbConfig(
                    offsetX: cx + orb.offsetX,
                    offsetY: cy + orb.offsetY,
                    size: orb.size,
                    duration: orb.duration,
                    delay: orb.delay,
                    targetX: orb.targetX,
                    targetY: orb.targetY
                ))
            }
        }
    }
}

private struct GridLinesView: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 50
            let color = GraphicsContext.Shading.color(
                NewAppTheme.Colors.lemon.opacity(0.035)
            )

            var x: CGFloat = 0
            while x <= size.width {
                var p = Path()
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x, y: size.height))
                ctx.stroke(p, with: color, lineWidth: 1)
                x += step
            }

            var y: CGFloat = 0
            while y <= size.height {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(p, with: color, lineWidth: 1)
                y += step
            }
        }
    }
}

private struct ScanlineView: View {
    @State private var offsetY: CGFloat = -60

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, NewAppTheme.Colors.lemon.opacity(0.04), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 60)
                .offset(y: offsetY)
                .onAppear {
                    withAnimation(
                        .linear(duration: 4)
                        .repeatForever(autoreverses: false)
                    ) {
                        offsetY = geo.size.height + 60
                    }
                }
        }
        .clipped()
    }
}

private struct CRTOverlay: View {
    var body: some View {
        Canvas { ctx, size in
            let lineColor = GraphicsContext.Shading.color(Color.black.opacity(0.08))
            var y: CGFloat = 0
            while y < size.height {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(p, with: lineColor, lineWidth: 2)
                y += 4
            }
        }
        .allowsHitTesting(false)
    }
}

public struct ZephyrBackground: View {
    public var showGrid: Bool      = true
    public var showScanline: Bool  = true
    public var showCRT: Bool       = false

    public init(showGrid: Bool = true, showScanline: Bool = true, showCRT: Bool = false) {
        self.showGrid = showGrid
        self.showScanline = showScanline
        self.showCRT = showCRT
    }

    public var body: some View {
        ZStack {
            NewAppTheme.Colors.bg
                .ignoresSafeArea()

            if showGrid {
                GridLinesView()
                    .ignoresSafeArea()
            }

            OrbsView()
                .ignoresSafeArea()

            ParticlesView()
                .ignoresSafeArea()

            if showScanline {
                ScanlineView()
                    .ignoresSafeArea()
            }

            if showCRT {
                CRTOverlay()
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }
}
