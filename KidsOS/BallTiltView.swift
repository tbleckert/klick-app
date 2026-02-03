//
//  BallTiltView.swift
//  KidsOS
//
//  Created by Tobias Bleckert on 2026-02-03.
//

import SwiftUI
import CoreMotion
import SpriteKit

struct BallTiltView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scene = BallTiltScene()
    @State private var motionManager = CMMotionManager()
    @State private var lastShakeTime: TimeInterval = 0

    private let shakeThreshold = 1.1
    private let shakeCooldown: TimeInterval = 0.6

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear {
                    scene.scaleMode = .resizeFill
                    startMotionUpdates()
                }
                .onDisappear {
                    motionManager.stopDeviceMotionUpdates()
                }

            VStack {
                HStack {
                    HomeCircleButton(systemName: "house.fill") {
                        dismiss()
                    }
                    .accessibilityLabel(Text("Hem"))

                    Spacer()

                    HomeCircleButton(systemName: "arrow.clockwise") {
                        scene.resetScene()
                    }
                    .accessibilityLabel(Text("Nollställ"))
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()
            }
        }
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion else { return }
            let gravity = motion.gravity
            scene.updateGravity(dx: gravity.x, dy: gravity.y)

            let accel = motion.userAcceleration
            let magnitude = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)
            let now = Date().timeIntervalSinceReferenceDate
            if magnitude > shakeThreshold, now - lastShakeTime > shakeCooldown {
                lastShakeTime = now
                scene.applyShakeImpulse()
            }
        }
    }
}

private struct HomeCircleButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.45))
                    .frame(width: 52, height: 52)

                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    BallTiltView()
}
