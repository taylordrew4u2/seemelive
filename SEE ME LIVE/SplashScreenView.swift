//
//  SplashScreenView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI

// MARK: - Splash Screen View
/// Beautiful launch animation that plays when app starts.

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accentColor.opacity(0.1),
                    Color.accentColor.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Animated logo/icon
                ZStack {
                    // Background pulse
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .opacity(isAnimating ? 0 : 1)

                    // Main icon
                    Image(systemName: "music.mic.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentColor,
                                    Color.accentColor.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isAnimating ? 1 : 0.5)
                        .opacity(isAnimating ? 1 : 0)
                }
                .frame(height: 140)

                // App name with animation
                VStack(spacing: 10) {
                    Text("SEE ME LIVE")
                        .font(.system(size: 42, weight: .bold, design: .default))
                        .foregroundStyle(Color.primary)
                        .scaleEffect(isAnimating ? 1 : 0.8)
                        .opacity(isAnimating ? 1 : 0)

                    Text("Your Performance Calendar")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .scaleEffect(isAnimating ? 1 : 0.8)
                        .opacity(isAnimating ? 1 : 0)
                }
                .multilineTextAlignment(.center)

                Spacer()

                // Loading indicator
                if !showContent {
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isAnimating && index < 2 ? 1.2 : 0.8)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.15),
                                    value: isAnimating
                                )
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }

            // Show main content after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeIn(duration: 0.5)) {
                    showContent = true
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
