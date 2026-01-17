//
//  CameraManager.swift
//  Klick
//
//  Created by Tobias Bleckert on 2026-01-16.
//

import AVFoundation
import AudioToolbox
import Combine
import UIKit
import SwiftUI
import CoreImage

class CameraManager: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var capturedImage: UIImage?
    @Published var showFlashAnimation = false
    @Published var zoomFactor: CGFloat = 1.0
    @Published var currentFilter: FilterType = .none
    @Published var currentFrame: FrameOverlay = .none

    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var videoDataOutput = AVCaptureVideoDataOutput()

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoOutputQueue = DispatchQueue(label: "camera.video.output.queue")

    private let ciContext = CIContext()

    // Child-friendly camera shutter sounds that cycle through
    private let shutterSounds: [SystemSoundID] = [
        1108, // photoShutter.caf - classic camera
        1103, // Tink.caf - light tap
        1104, // Tock.caf - playful tap
        1105, // Pop.caf - bubble pop
        1106, // KeyPressClick.caf - click
        1107  // SMS_Alert_Tone.caf - notification
    ]
    private var currentSoundIndex = 0

    var onPhotoCaptured: ((String, UIImage) -> Void)?
    var onFilteredFrameReady: ((CIImage) -> Void)?
    
    override init() {
        super.init()
        preloadResources()
        checkPermissions()
    }

    private func preloadResources() {
        // Preload all sounds to avoid first-time lag
        for soundID in shutterSounds {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) // Silent preload
        }

        // Warm up the graphics renderer
        DispatchQueue.global(qos: .userInitiated).async {
            let dummySize = CGSize(width: 100, height: 100)
            let renderer = UIGraphicsImageRenderer(size: dummySize)
            _ = renderer.image { _ in }
        }
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupSession()
                }
            }
        default:
            break
        }
    }
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                self.session.commitConfiguration()
                return
            }
            
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                
                if self.session.canAddInput(videoDeviceInput) {
                    self.session.addInput(videoDeviceInput)
                    self.videoDeviceInput = videoDeviceInput
                }
            } catch {
                print("Could not create video device input: \(error)")
                self.session.commitConfiguration()
                return
            }
            
            // Add photo output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                // Use the maximum supported photo dimensions
                if let maxDimensions = videoDevice.activeFormat.supportedMaxPhotoDimensions.first {
                    self.photoOutput.maxPhotoDimensions = maxDimensions
                }
            }

            // Add video data output for live filtering
            self.videoDataOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            self.videoDataOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)

            if self.session.canAddOutput(self.videoDataOutput) {
                self.session.addOutput(self.videoDataOutput)

                // Set proper orientation for video output
                if let connection = self.videoDataOutput.connection(with: .video) {
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                }
            }

            self.session.commitConfiguration()
            self.startSession()
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    func setZoom(factor: CGFloat) {
        guard let device = videoDeviceInput?.device else { return }

        do {
            try device.lockForConfiguration()

            // Clamp zoom factor between min and max
            let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 10.0)
            let clampedZoom = max(1.0, min(factor, maxZoom))

            device.videoZoomFactor = clampedZoom

            DispatchQueue.main.async {
                self.zoomFactor = clampedZoom
            }

            device.unlockForConfiguration()
        } catch {
            print("Error setting zoom: \(error)")
        }
    }

    func nextFilter() {
        let allFilters = FilterType.allCases
        if let currentIndex = allFilters.firstIndex(of: currentFilter) {
            let nextIndex = (currentIndex + 1) % allFilters.count
            currentFilter = allFilters[nextIndex]
        }
    }

    func previousFilter() {
        let allFilters = FilterType.allCases
        if let currentIndex = allFilters.firstIndex(of: currentFilter) {
            let previousIndex = (currentIndex - 1 + allFilters.count) % allFilters.count
            currentFilter = allFilters[previousIndex]
        }
    }

    func nextFrame() {
        let allFrames = FrameOverlay.allCases
        if let currentIndex = allFrames.firstIndex(of: currentFrame) {
            let nextIndex = (currentIndex + 1) % allFrames.count
            currentFrame = allFrames[nextIndex]
        }
    }

    func previousFrame() {
        let allFrames = FrameOverlay.allCases
        if let currentIndex = allFrames.firstIndex(of: currentFrame) {
            let previousIndex = (currentIndex - 1 + allFrames.count) % allFrames.count
            currentFrame = allFrames[previousIndex]
        }
    }

    func capturePhoto() {
        // Play cycling shutter sound immediately for feedback
        AudioServicesPlaySystemSound(shutterSounds[currentSoundIndex])

        // Cycle to next sound for next photo
        currentSoundIndex = (currentSoundIndex + 1) % shutterSounds.count

        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto

            self.photoOutput.capturePhoto(with: settings, delegate: self)

            DispatchQueue.main.async {
                self.showFlashAnimation = true
                // Longer flash duration for more prominent effect
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.showFlashAnimation = false
                }
            }
        }
    }
    
    private func savePhoto(_ imageData: Data) -> String? {
        let filename = "klick_\(UUID().uuidString).jpg"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            return filename
        } catch {
            print("Error saving photo: \(error)")
            return nil
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              var uiImage = UIImage(data: imageData) else {
            print("Could not get image data")
            return
        }

        // Apply filter if not .none
        if currentFilter != .none, let ciImage = CIImage(image: uiImage) {
            if let filteredImage = currentFilter.apply(to: ciImage),
               let cgImage = ciContext.createCGImage(filteredImage, from: filteredImage.extent) {
                uiImage = UIImage(cgImage: cgImage, scale: uiImage.scale, orientation: uiImage.imageOrientation)
            }
        }

        // Apply frame overlay if not .none
        if currentFrame != .none {
            uiImage = addFrameOverlay(to: uiImage, frame: currentFrame)
        }

        // Convert back to JPEG data
        guard let finalImageData = uiImage.jpegData(compressionQuality: 0.9) else {
            print("Could not convert filtered image to data")
            return
        }

        if let filename = savePhoto(finalImageData) {
            DispatchQueue.main.async { [weak self] in
                self?.capturedImage = uiImage
                self?.onPhotoCaptured?(filename, uiImage)
            }
        }
    }

    private func addFrameOverlay(to image: UIImage, frame: FrameOverlay) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            // Draw original image
            image.draw(at: .zero)

            // Draw emoji frame in all four corners
            let fontSize = image.size.width * 0.15
            let font = UIFont.systemFont(ofSize: fontSize)
            let attributes: [NSAttributedString.Key: Any] = [.font: font]

            let emojiString = frame.emoji as NSString
            let emojiSize = emojiString.size(withAttributes: attributes)

            // Top-left
            emojiString.draw(at: CGPoint(x: 20, y: 20), withAttributes: attributes)

            // Top-right
            emojiString.draw(at: CGPoint(x: image.size.width - emojiSize.width - 20, y: 20), withAttributes: attributes)

            // Bottom-left
            emojiString.draw(at: CGPoint(x: 20, y: image.size.height - emojiSize.height - 20), withAttributes: attributes)

            // Bottom-right
            emojiString.draw(at: CGPoint(x: image.size.width - emojiSize.width - 20, y: image.size.height - emojiSize.height - 20), withAttributes: attributes)
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Apply filter if active, otherwise pass through the original
        if currentFilter != .none, let filteredImage = currentFilter.apply(to: ciImage) {
            onFilteredFrameReady?(filteredImage)
        } else if currentFilter == .none {
            // When no filter, hide the overlay
            DispatchQueue.main.async { [weak self] in
                self?.onFilteredFrameReady?(ciImage)
            }
        }
    }
}
