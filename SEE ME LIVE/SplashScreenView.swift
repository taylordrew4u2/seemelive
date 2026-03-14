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
    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── App Icon ──
                ZStack {
                    // Soft glow behind icon
                    Circle()
                        .fill(Color.accentColor.opacity(0.08))
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseScale)

                    // Icon container
                    Image("SplashIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 20, y: 10)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                Spacer().frame(height: 32)

                // ── Title ──
                VStack(spacing: 8) {
                    Text("SEE ME LIVE")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                        .tracking(1.5)

                    Text("Your Performance Calendar")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .opacity(subtitleOpacity)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            // Phase 1: Icon appears with spring
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.1)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }

            // Phase 2: Title slides up
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                titleOffset = 0
                titleOpacity = 1.0
            }

            // Phase 3: Subtitle fades in
            withAnimation(.easeOut(duration: 0.4).delay(0.7)) {
                subtitleOpacity = 1.0
            }

            // Phase 4: Subtle pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(1.0)) {
                pulseScale = 1.15
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
