//
//  CameraView.swift
//  Klick
//
//  Created by Tobias Bleckert on 2026-01-16.
//

import SwiftUI
import SwiftData
import AudioToolbox
#if canImport(ConfettiSwiftUI)
import ConfettiSwiftUI
#endif

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Photo.timestamp, order: .reverse) private var photos: [Photo]
    
    @StateObject private var cameraManager = CameraManager()
    @State private var showGallery = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var lastZoomFactor: CGFloat = 1.0
    @State private var showFilterName = false
    @State private var showFrameName = false
    @State private var confettiCounter = 0
    @State private var capturedImage: UIImage?
    @State private var showCapturedImage = false
    @State private var capturedImageScale: CGFloat = 1.0
    @State private var capturedImageOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Camera preview - full screen
            CameraPreviewView(session: cameraManager.session, cameraManager: cameraManager)
                .ignoresSafeArea()
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastZoomFactor
                            lastZoomFactor = value
                            let newZoom = cameraManager.zoomFactor * delta
                            cameraManager.setZoom(factor: newZoom)
                        }
                        .onEnded { _ in
                            lastZoomFactor = 1.0
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { gesture in
                            if abs(gesture.translation.width) > abs(gesture.translation.height) {
                                // Horizontal swipe - change filter
                                if gesture.translation.width > 0 {
                                    cameraManager.previousFilter()
                                } else {
                                    cameraManager.nextFilter()
                                }
                                showFilterName = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showFilterName = false
                                }
                            } else {
                                // Vertical swipe - change frame
                                if gesture.translation.height > 0 {
                                    cameraManager.previousFrame()
                                } else {
                                    cameraManager.nextFrame()
                                }
                                showFrameName = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showFrameName = false
                                }
                            }
                        }
                )

            // Frame overlay (animal emojis in corners)
            if cameraManager.currentFrame != .none {
                GeometryReader { geometry in
                    let emoji = cameraManager.currentFrame.emoji
                    let size: CGFloat = 60

                    // Top-left
                    Text(emoji)
                        .font(.system(size: size))
                        .position(x: size/2 + 20, y: size/2 + 60)

                    // Top-right
                    Text(emoji)
                        .font(.system(size: size))
                        .position(x: geometry.size.width - size/2 - 20, y: size/2 + 60)

                    // Bottom-left
                    Text(emoji)
                        .font(.system(size: size))
                        .position(x: size/2 + 20, y: geometry.size.height - size/2 - 120)

                    // Bottom-right
                    Text(emoji)
                        .font(.system(size: size))
                        .position(x: geometry.size.width - size/2 - 20, y: geometry.size.height - size/2 - 120)
                }
                .allowsHitTesting(false)
            }


            // Filter/Frame name overlay
            VStack {
                if showFilterName || showFrameName {
                    Text(showFilterName ? cameraManager.currentFilter.displayName : cameraManager.currentFrame.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .animation(.easeInOut, value: showFilterName)
            .animation(.easeInOut, value: showFrameName)

            // Captured photo animation overlay - fullscreen freeze
            if showCapturedImage, let image = capturedImage {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .drawingGroup() // Flatten into single layer for better performance
                        .scaleEffect(capturedImageScale)
                        .offset(capturedImageOffset)
                }
                .ignoresSafeArea()
            }
            
            // UI Overlay
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
                    // Gallery button - bottom left (only show if photos exist)
                    if let latestPhoto = photos.first,
                       let uiImage = loadImage(from: latestPhoto.fileURL) {
                        Button(action: {
                            showGallery = true
                        }) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        }
                        .padding(.leading, 30)
                    } else {
                        // Placeholder for symmetry when no photos
                        Color.clear
                            .frame(width: 70, height: 70)
                            .padding(.leading, 30)
                    }
                    
                    Spacer()
                    
                    // Large capture button - center
                    Button(action: {
                        capturePhoto()
                    }) {
                        ZStack {
                            // Outer ring - plain color
                            Circle()
                                .stroke(Color.orange, lineWidth: 6)
                                .frame(width: 100, height: 100)
                            
                            // Inner white circle
                            Circle()
                                .fill(Color.white)
                                .frame(width: 85, height: 85)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .scaleEffect(buttonScale)
                    }
                    .padding(.bottom, 10)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 70, height: 70)
                        .padding(.trailing, 30)
                }
                .padding(.bottom, 40)
            }
        }
#if canImport(ConfettiSwiftUI)
        .confettiCannon(trigger: $confettiCounter, num: 40, confettis: [.text("🐶"), .text("🐱"), .text("🐭"), .text("🐹"), .text("🐰"), .text("🦊"), .text("🐻"), .text("🐼"), .text("🐨"), .text("🐯"), .text("🦁"), .text("🐮"), .text("🐷"), .text("🐸"), .text("🐵"), .text("🐔"), .text("🐧"), .text("🐦"), .text("🐤"), .text("🦆"), .text("🦅"), .text("🦉"), .text("🦇"), .text("🐺"), .text("🐗"), .text("🐴"), .text("🦄"), .text("🐝"), .text("🐛"), .text("🦋"), .text("🐌"), .text("🐞"), .text("🐢"), .text("🐍"), .text("🦎"), .text("🦖"), .text("🦕")], radius: 500)
#else
        // ConfettiSwiftUI not available; no-op to keep build green
        .onChange(of: confettiCounter) { _, _ in }
#endif
        .onAppear {
            cameraManager.onPhotoCaptured = { filename, image in
                savePhotoToDatabase(filename: filename)
                triggerPhotoAnimation(image: image)
            }

            // Warm up image processing on first launch
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) {
                // Create a tiny dummy image to warm up the resize pipeline
                let dummyImage = UIImage(systemName: "camera") ?? UIImage()
                _ = self.resizeImage(dummyImage, targetSize: CGSize(width: 100, height: 100))
            }
        }
        .fullScreenCover(isPresented: $showGallery) {
            GalleryView()
        }
        .animation(.easeInOut(duration: 0.1), value: cameraManager.showFlashAnimation)
    }
    
    private func capturePhoto() {
        // Button press animation
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            buttonScale = 0.85
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                buttonScale = 1.0
            }
        }
        
        cameraManager.capturePhoto()
    }
    
    private func savePhotoToDatabase(filename: String) {
        let photo = Photo(filename: filename)
        modelContext.insert(photo)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving photo to database: \(error)")
        }
    }
    
    private func loadImage(from url: URL) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }

    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let scaleFactor = max(widthRatio, heightRatio)

        let scaledSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
    }

    private func triggerPhotoAnimation(image: UIImage) {
        // Resize image on background thread for better performance
        DispatchQueue.global(qos: .userInitiated).async {
            // Use 50% screen size for faster animation
            let screenSize = UIScreen.main.bounds.size
            let targetSize = CGSize(width: screenSize.width * 0.5, height: screenSize.height * 0.5)
            let resizedImage = self.resizeImage(image, targetSize: targetSize)

            // Switch back to main thread for UI updates
            DispatchQueue.main.async {
                self.capturedImage = resizedImage
                self.showCapturedImage = true
                self.capturedImageScale = 1.0
                self.capturedImageOffset = .zero

                // Step 1: Pop and expand slightly (0.0 - 0.2s)
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    self.capturedImageScale = 1.15
                }

                // Step 2: Trigger confetti at peak (0.1s)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.confettiCounter += 1
                }

                // Step 3: Start flying animation to gallery button (0.3s - 0.8s)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        // Calculate screen dimensions
                        let screenWidth = UIScreen.main.bounds.width
                        let screenHeight = UIScreen.main.bounds.height

                        // Shrink to 0 to go into the thumbnail
                        self.capturedImageScale = 0.01

                        // Calculate offset to gallery button position
                        let targetX = -(screenWidth / 2) + 65
                        let targetY = (screenHeight / 2) - 145

                        self.capturedImageOffset = CGSize(width: targetX, height: targetY)
                    }
                }

                // Step 4: Hide the animated image after animation completes (0.9s)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    self.showCapturedImage = false
                    self.capturedImage = nil
                    self.capturedImageScale = 1.0
                    self.capturedImageOffset = .zero
                }
            }
        }
    }
}

#Preview {
    CameraView()
        .modelContainer(for: Photo.self, inMemory: true)
}
