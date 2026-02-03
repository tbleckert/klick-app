//
//  BalloonInflateView.swift
//  Klick
//
//  Created by Tobias Bleckert on 2026-02-03.
//

import SwiftUI

struct BalloonInflateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    @State private var offsetY: CGFloat = 0
    @State private var isFloating = false
    @State private var bobbing = false
    @State private var colorIndex = 0

    private let maxScale: CGFloat = 2.2
    private let inflateDuration: TimeInterval = 1.5
    private let floatDuration: TimeInterval = 2.6
    private let balloonColors: [[Color]] = [
        [Color(red: 0.99, green: 0.52, blue: 0.74), Color(red: 0.96, green: 0.30, blue: 0.60)],
        [Color(red: 0.42, green: 0.72, blue: 0.98), Color(red: 0.18, green: 0.46, blue: 0.88)],
        [Color(red: 0.98, green: 0.78, blue: 0.49), Color(red: 0.97, green: 0.58, blue: 0.32)],
        [Color(red: 0.56, green: 0.86, blue: 0.54), Color(red: 0.22, green: 0.62, blue: 0.32)]
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let balloonBaseSize = min(size.width, size.height) * 0.28
            let floatDistance = size.height * 0.55

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.55, green: 0.87, blue: 0.98),
                        Color(red: 0.86, green: 0.94, blue: 1.0),
                        Color(red: 0.98, green: 0.78, blue: 0.49)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: balloonBaseSize * 2.4, height: balloonBaseSize * 2.4)
                    .offset(x: size.width * 0.35, y: -size.height * 0.35)

                VStack {
                    HStack {
                        HomeButton(action: {
                            dismiss()
                        })
                        .padding(.leading, 20)
                        .padding(.top, 60)

                        Spacer()
                    }

                    Spacer()
                }

                ZStack(alignment: .top) {
                    BalloonShape()
                        .fill(
                            LinearGradient(
                                colors: balloonColors[colorIndex],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            BalloonShape()
                                .stroke(Color.white.opacity(0.7), lineWidth: 4)
                        )
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.35))
                                .frame(width: balloonBaseSize * 0.36, height: balloonBaseSize * 0.36)
                                .offset(x: -balloonBaseSize * 0.18, y: -balloonBaseSize * 0.25)
                        )
                        .frame(width: balloonBaseSize, height: balloonBaseSize * 1.3)

                    BalloonString()
                        .stroke(Color.black.opacity(0.25), lineWidth: 3)
                        .frame(width: 40, height: 90)
                        .offset(y: balloonBaseSize * 1.18)
                }
                .scaleEffect(scale)
                .offset(y: offsetY + (bobbing ? -10 : 10))
                .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: bobbing)
                .onLongPressGesture(minimumDuration: 0, maximumDistance: 60, pressing: { pressing in
                    if pressing {
                        startInflate()
                    } else {
                        releaseBalloon(floatDistance: floatDistance)
                    }
                }) {}
                .accessibilityLabel(Text("Ballong"))
            }
            .onAppear {
                resetBalloon(advanceColor: false)
                bobbing = true
            }
            .onDisappear {
                resetBalloon(advanceColor: false)
            }
        }
    }

    private func startInflate() {
        guard !isFloating else { return }
        isPressed = true
        withAnimation(.easeOut(duration: inflateDuration)) {
            scale = maxScale
        }
    }

    private func releaseBalloon(floatDistance: CGFloat) {
        guard isPressed else { return }
        isPressed = false
        guard !isFloating else { return }
        isFloating = true
        withAnimation(.easeInOut(duration: floatDuration)) {
            offsetY = -floatDistance
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + floatDuration) {
            resetBalloon(advanceColor: true)
        }
    }

    private func resetBalloon(advanceColor: Bool) {
        isPressed = false
        isFloating = false
        scale = 1.0
        offsetY = 0
        if advanceColor {
            colorIndex = (colorIndex + 1) % balloonColors.count
        }
    }
}

private struct BalloonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.5, y: height))
        path.addCurve(
            to: CGPoint(x: width * 0.08, y: height * 0.35),
            control1: CGPoint(x: width * 0.2, y: height * 0.92),
            control2: CGPoint(x: width * 0.04, y: height * 0.65)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control1: CGPoint(x: width * 0.1, y: height * 0.08),
            control2: CGPoint(x: width * 0.3, y: 0)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.92, y: height * 0.35),
            control1: CGPoint(x: width * 0.7, y: 0),
            control2: CGPoint(x: width * 0.9, y: height * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: width * 0.96, y: height * 0.65),
            control2: CGPoint(x: width * 0.8, y: height * 0.92)
        )
        return path
    }
}

private struct BalloonString: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: 0))
        path.addCurve(
            to: CGPoint(x: rect.midX - 6, y: rect.maxY),
            control1: CGPoint(x: rect.midX + 8, y: rect.maxY * 0.3),
            control2: CGPoint(x: rect.midX - 12, y: rect.maxY * 0.7)
        )
        return path
    }
}

#Preview {
    BalloonInflateView()
}
