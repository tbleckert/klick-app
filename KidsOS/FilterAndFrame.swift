//
//  FilterAndFrame.swift
//  KidsOS
//
//  Created by Tobias Bleckert on 2026-01-17.
//

import Foundation
import CoreImage

enum FilterType: CaseIterable {
    case none
    case sepia
    case noir
    case chrome
    case fade
    case instant
    case process
    case transfer
    case rainbow

    var displayName: String {
        switch self {
        case .none: return "No Filter"
        case .sepia: return "Vintage"
        case .noir: return "Black & White"
        case .chrome: return "Chrome"
        case .fade: return "Faded"
        case .instant: return "Instant"
        case .process: return "Process"
        case .transfer: return "Transfer"
        case .rainbow: return "Rainbow"
        }
    }

    func apply(to image: CIImage) -> CIImage? {
        switch self {
        case .none:
            return image
        case .sepia:
            guard let filter = CIFilter(name: "CISepiaTone") else { return image }
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(0.8, forKey: kCIInputIntensityKey)
            return filter.outputImage
        case .noir:
            guard let filter = CIFilter(name: "CIPhotoEffectNoir") else { return image }
            filter.setValue(image, forKey: kCIInputImageKey)
            return filter.outputImage
        case .chrome:
            guard let filter = CIFilter(name: "CIPhotoEffectChrome") else { return image }
            filter.setValue(image, forKey: kCIInputImageKey)
            return filter.outputImage
        case .fade:
            guard let filter = CIFilter(name: "CIPhotoEffectFade") else { return image }
            filter.setValue(image, forKey: kCIInputImageKey)
            return filter.outputImage
        case .instant:
            guard let filter = CIFilter(name: "CIPhotoEffectInstant") else { return image }
            filter.setValue(image, forKey: kCIInputImageKey)
            return filter.outputImage
        case .process:
            guard let filter = CIFilter(name: "CIPhotoEffectProcess") else { return image }
            filter.setValue(image, forKey: kCIInputImageKey)
            return filter.outputImage
        case .transfer:
            guard let filter = CIFilter(name: "CIPhotoEffectTransfer") else { return image }
            filter.setValue(image, forKey: kCIInputImageKey)
            return filter.outputImage
        case .rainbow:
            // Fun colorful effect for kids
            guard let hueFilter = CIFilter(name: "CIHueAdjust") else { return image }
            hueFilter.setValue(image, forKey: kCIInputImageKey)
            hueFilter.setValue(1.0, forKey: kCIInputAngleKey)

            guard let vibranceFilter = CIFilter(name: "CIVibrance") else { return hueFilter.outputImage }
            vibranceFilter.setValue(hueFilter.outputImage, forKey: kCIInputImageKey)
            vibranceFilter.setValue(1.5, forKey: "inputAmount")
            return vibranceFilter.outputImage
        }
    }
}

enum FrameOverlay: CaseIterable {
    case none
    case cat
    case dog
    case bunny
    case bear
    case lion
    case panda
    case fox

    var displayName: String {
        switch self {
        case .none: return "No Frame"
        case .cat: return "😺 Cat"
        case .dog: return "🐶 Dog"
        case .bunny: return "🐰 Bunny"
        case .bear: return "🐻 Bear"
        case .lion: return "🦁 Lion"
        case .panda: return "🐼 Panda"
        case .fox: return "🦊 Fox"
        }
    }

    var emoji: String {
        switch self {
        case .none: return ""
        case .cat: return "😺"
        case .dog: return "🐶"
        case .bunny: return "🐰"
        case .bear: return "🐻"
        case .lion: return "🦁"
        case .panda: return "🐼"
        case .fox: return "🦊"
        }
    }
}
