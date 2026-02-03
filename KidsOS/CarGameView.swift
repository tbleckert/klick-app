//
//  CarGameView.swift
//  KidsOS
//
//  Created by Tobias Bleckert on 2026-02-01.
//

import SwiftUI
import Combine
import SpriteKit

struct CarGameView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isAccelerating = false
    @State private var scene = CarGameScene()
    @State private var idleSeconds: TimeInterval = 0
    @State private var showHint = false

    private let idleHintDelay: TimeInterval = 5
    private let idleTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear {
                    scene.scaleMode = .resizeFill
                    scene.isAccelerating = isAccelerating
                    scene.bottomInset = 150
                    idleSeconds = 0
                    showHint = false
                }
                .onChange(of: isAccelerating) { newValue in
                    scene.isAccelerating = newValue
                    if newValue {
                        idleSeconds = 0
                        showHint = false
                    }
                }
                .onReceive(idleTimer) { _ in
                    if isAccelerating {
                        idleSeconds = 0
                        showHint = false
                    } else {
                        idleSeconds = min(idleSeconds + 0.5, 60)
                        showHint = idleSeconds >= idleHintDelay
                    }
                }

            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.45))
                                .frame(width: 52, height: 52)

                            Image(systemName: "house.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60)
                    .accessibilityLabel(Text("Hem"))

                    Spacer()
                }

                Spacer()

                HStack {
                    Spacer()

                    ZStack {
                        if showHint {
                            GasHintView()
                                .transition(.opacity)
                                .offset(y: -140)
                        }

                        GasButton(isPressed: $isAccelerating)
                    }
                }
                .padding(.trailing, 24)
                .padding(.bottom, 36)
            }
        }
    }
}

struct GasButton: View {
    @Binding var isPressed: Bool

    var body: some View {
        let topColor = isPressed
            ? Color(red: 1.0, green: 0.70, blue: 0.40)
            : Color(red: 0.99, green: 0.58, blue: 0.32)
        let bottomColor = isPressed
            ? Color(red: 0.98, green: 0.40, blue: 0.30)
            : Color(red: 0.97, green: 0.34, blue: 0.25)

        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            topColor,
                            bottomColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 130, height: 130)
                .shadow(color: Color.white.opacity(isPressed ? 0.5 : 0.2), radius: isPressed ? 18 : 8, x: 0, y: 0)

            Circle()
                .stroke(Color.white.opacity(0.85), lineWidth: 6)
                .frame(width: 130, height: 130)

            Text("GASA")
                .font(.custom("Chalkboard SE", size: 28))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: 60, pressing: { pressing in
            isPressed = pressing
        }) {}
        .accessibilityLabel(Text("Gasa"))
    }
}

struct GasHintView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.25))
                .frame(width: 54, height: 54)
            Image(systemName: "arrow.down")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(pulse ? 1.05 : 0.92)
        .opacity(pulse ? 1.0 : 0.7)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
        .onAppear {
            pulse = true
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    CarGameView()
}
