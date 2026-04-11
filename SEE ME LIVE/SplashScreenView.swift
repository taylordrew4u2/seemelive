//
//  SplashScreenView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI

// MARK: - Splash Screen View
/// Elegant launch animation that plays when app starts.

struct SplashScreenView: View {
    // Optional callback when the splash finishes so the app can advance.
    var onFinish: () -> Void = {}

    @Environment(\.colorScheme) private var colorScheme
    @State private var showContent = false
    @State private var pulse = false
    @State private var ripple = false
    @State private var glow = false

    private var brand: Color { Color(red: 0.92, green: 0.14, blue: 0.16) } // matches red/white icon
    private var background: Color { Color("AppBackground") }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    brand.opacity(colorScheme == .dark ? 0.5 : 0.85),
                    background.opacity(colorScheme == .dark ? 0.95 : 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(brand.opacity(0.22))
                .blur(radius: 72)
                .frame(width: 420, height: 420)
                .offset(x: -120, y: -200)

            Circle()
                .fill(brand.opacity(colorScheme == .dark ? 0.18 : 0.24))
                .blur(radius: 90)
                .frame(width: 520, height: 520)
                .offset(x: 140, y: 180)

            VStack(spacing: 18) {
                ZStack {
                    // Decorative animations — drawingGroup to prevent rate-limit spam
                    Group {
                        Circle()
                            .fill(brand.opacity(0.18))
                            .scaleEffect(glow ? 1.14 : 0.94)
                            .blur(radius: glow ? 26 : 16)
                            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: glow)

                        Circle()
                            .stroke(brand.opacity(0.28), lineWidth: 3)
                            .scaleEffect(ripple ? 1.45 : 0.75)
                            .opacity(ripple ? 0.0 : 0.65)
                            .animation(.easeOut(duration: 1.9).delay(0.15).repeatForever(autoreverses: false), value: ripple)

                        Circle()
                            .stroke(Color.white.opacity(0.55), lineWidth: 2)
                            .scaleEffect(pulse ? 1.18 : 0.9)
                            .opacity(pulse ? 0.0 : 0.7)
                            .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulse)
                    }
                    .drawingGroup()
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)

                    BrandLogoView(size: 138)
                        .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.2), radius: 16, y: 10)
                        .scaleEffect(showContent ? 1.0 : 0.88)
                        .animation(.spring(response: 0.65, dampingFraction: 0.78, blendDuration: 0.25), value: showContent)
                }

                VStack(spacing: 6) {
                    Text("SEE ME LIVE")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .kerning(1.5)
                        .foregroundStyle(.primary)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 6)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)

                    Text("Show the world where you’re performing next.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(.easeOut(duration: 0.6).delay(0.32), value: showContent)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("SEE ME LIVE is starting up")
        }
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        showContent = true
        pulse = true
        ripple = true
        glow = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            onFinish()
        }
    }
}

#Preview {
    SplashScreenView()
}
