//
//  KlickApp.swift
//  Klick
//
//  Created by Tobias Bleckert on 2026-01-16.
//

import SwiftUI
import SwiftData

@main
struct KlickApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Photo.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct HomeView: View {
    @State private var showCamera = false
    @State private var showCarGame = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.87, blue: 0.98),
                    Color(red: 0.98, green: 0.78, blue: 0.49)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.25))
                .frame(width: 260, height: 260)
                .offset(x: 130, y: -220)

            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 320, height: 320)
                .offset(x: -170, y: 240)

            VStack(spacing: 28) {
                Text("👋 Liam")
                    .font(.custom("Chalkboard SE", size: 36))
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.14))

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 24) {
                        HomeTileButton(
                            iconName: "camera.fill",
                            colors: [
                                Color(red: 0.99, green: 0.58, blue: 0.32),
                                Color(red: 0.97, green: 0.34, blue: 0.25)
                            ],
                            accessibilityLabel: "Kamera"
                        ) {
                            showCamera = true
                        }

                        HomeTileButton(
                            iconName: "car.fill",
                            colors: [
                                Color(red: 0.42, green: 0.72, blue: 0.98),
                                Color(red: 0.18, green: 0.46, blue: 0.88)
                            ],
                            accessibilityLabel: "Bilspel"
                        ) {
                            showCarGame = true
                        }
                    }

                    VStack(spacing: 24) {
                        HomeTileButton(
                            iconName: "camera.fill",
                            colors: [
                                Color(red: 0.99, green: 0.58, blue: 0.32),
                                Color(red: 0.97, green: 0.34, blue: 0.25)
                            ],
                            accessibilityLabel: "Kamera"
                        ) {
                            showCamera = true
                        }

                        HomeTileButton(
                            iconName: "car.fill",
                            colors: [
                                Color(red: 0.42, green: 0.72, blue: 0.98),
                                Color(red: 0.18, green: 0.46, blue: 0.88)
                            ],
                            accessibilityLabel: "Bilspel"
                        ) {
                            showCarGame = true
                        }
                    }
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView()
        }
        .fullScreenCover(isPresented: $showCarGame) {
            CarGameView()
        }
    }
}

struct HomeTileButton: View {
    let iconName: String
    let colors: [Color]
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.white.opacity(0.65))
                    .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 8)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 190, height: 190)

                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 6)
                        .frame(width: 190, height: 190)

                    Image(systemName: iconName)
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                }
            }
            .frame(width: 240, height: 240)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabel))
    }
}
