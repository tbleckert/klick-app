//
//  CameraPreviewView.swift
//  KidsOS
//
//  Created by Tobias Bleckert on 2026-01-16.
//

import SwiftUI
import AVFoundation
import CoreImage

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    @ObservedObject var cameraManager: CameraManager

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill

        // Set up filtered frame callback
        cameraManager.onFilteredFrameReady = { [weak view] filteredImage in
            DispatchQueue.main.async {
                view?.displayFilteredImage(filteredImage)
            }
        }

        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.previewLayer.session = session

        // Show/hide overlay based on filter
        if cameraManager.currentFilter == .none {
            uiView.hideFilteredOverlay()
        }
    }
}

class CameraPreviewUIView: UIView {
    private let ciContext = CIContext()
    private var filterOverlayLayer: CALayer?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    func displayFilteredImage(_ ciImage: CIImage) {
        // Create overlay layer if needed
        if filterOverlayLayer == nil {
            let overlayLayer = CALayer()
            overlayLayer.frame = bounds
            overlayLayer.contentsGravity = .resizeAspectFill
            layer.addSublayer(overlayLayer)
            filterOverlayLayer = overlayLayer
        }

        // Convert CIImage to CGImage and display
        if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
            filterOverlayLayer?.contents = cgImage
            filterOverlayLayer?.isHidden = false
        }
    }

    func hideFilteredOverlay() {
        filterOverlayLayer?.isHidden = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        filterOverlayLayer?.frame = bounds
    }
}
