//
//  CarGameView.swift
//  Klick
//
//  Created by Tobias Bleckert on 2026-02-01.
//

import SwiftUI
import SpriteKit

struct CarGameView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isAccelerating = false
    @State private var scene = CarGameScene()

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear {
                    scene.scaleMode = .resizeFill
                    scene.isAccelerating = isAccelerating
                    scene.bottomInset = 150
                }
                .onChange(of: isAccelerating) { newValue in
                    scene.isAccelerating = newValue
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

                    GasButton(isPressed: $isAccelerating)
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
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 0.58, blue: 0.32),
                            Color(red: 0.97, green: 0.34, blue: 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 130, height: 130)

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

#Preview {
    CarGameView()
}
