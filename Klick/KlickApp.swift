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

                Button(action: {
                    showCamera = true
                }) {
                    VStack(spacing: 16) {
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
                                .frame(width: 200, height: 200)

                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 6)
                                .frame(width: 200, height: 200)

                            Image(systemName: "camera.fill")
                                .font(.system(size: 68, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color.white.opacity(0.65))
                            .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 8)
                    )
                }
                .buttonStyle(.plain)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView()
        }
    }
}
