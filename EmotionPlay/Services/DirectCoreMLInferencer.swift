//
//  DirectCoreMLInferencer.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 19/10/2025.
//

import Foundation
import CoreML
import UIKit
import CoreImage
import VideoToolbox

final class DirectCoreMLInferencer: MoodInferencer {
    
    // MARK: - Properties
    
    private let model: EmotiPlayFinal
    private let inputSize: CGSize
    private let inferenceQueue = DispatchQueue(label: "com.emotionplay.inference", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init() throws {
        print("🔍 Loading Core ML model...")
        
        let config = MLModelConfiguration()
        // Use .all for best performance on real devices (uses Neural Engine when available)
        config.computeUnits = .all
        
        guard let mlModel = try? EmotiPlayFinal(configuration: config) else {
            print("❌ Failed to initialize EmotiPlayModel")
            throw CoreMLError.modelLoadFailed
        }
        self.model = mlModel
        
        // Get input size from model
        let desc = mlModel.model.modelDescription
        guard let firstInput = desc.inputDescriptionsByName.first?.value,
              let constraint = firstInput.imageConstraint else {
            throw CoreMLError.modelLoadFailed
        }
        
        self.inputSize = CGSize(width: constraint.pixelsWide, height: constraint.pixelsHigh)
        print("✅ Model loaded: \(Int(inputSize.width))x\(Int(inputSize.height))")
    }
    
    // MARK: - MoodInferencer Protocol
    
    func infer(fromImageData data: Data) async throws -> (Mood, Double) {
        guard let uiImage = UIImage(data: data), let cgImage = uiImage.cgImage else {
            throw CoreMLError.invalidImageData
        }
        
        // Create pixel buffer with center crop (matches Xcode preview)
        guard let pixelBuffer = Self.makePixelBuffer(from: cgImage, targetSize: inputSize) else {
            throw CoreMLError.imageConversionFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            inferenceQueue.async {
                do {
                    let prediction = try self.model.prediction(image: pixelBuffer)
                    
                    let predictedLabel = prediction.target
                    let probabilities = prediction.targetProbability
                    let confidence = probabilities[predictedLabel] ?? 0.0
                    
                    print("📊 Predictions:")
                    for (label, prob) in probabilities.sorted(by: { $0.value > $1.value }) {
                        print("  \(label): \(Int(prob * 100))%")
                    }
                    
                    let mood = self.mapClassificationToMood(predictedLabel)
                    print("✅ \(predictedLabel) → \(mood.rawValue) (\(Int(confidence * 100))%)")
                    
                    continuation.resume(returning: (mood, confidence))
                    
                } catch {
                    print("❌ Prediction error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func mapClassificationToMood(_ label: String) -> Mood {
        let lowercased = label.lowercased()
        switch lowercased {
        case "happy":
            return .happy
        case "sad":
            return .sad
        case "angry":
            return .angry
        case "surprised":
            return .energetic
        default:
            print("⚠️ Unexpected label: '\(label)', defaulting to calm")
            return .calm
        }
    }
    
    // MARK: - Pixel Buffer Creation
    
    /// Creates a pixel buffer with center crop (matches Xcode's preview behavior)
    private static func makePixelBuffer(from cgImage: CGImage, targetSize: CGSize) -> CVPixelBuffer? {
        let width = Int(targetSize.width)
        let height = Int(targetSize.height)
        
        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true
        ]
        
        guard CVPixelBufferCreate(kCFAllocatorDefault,
                                  width,
                                  height,
                                  kCVPixelFormatType_32BGRA,
                                  attrs as CFDictionary,
                                  &pixelBuffer) == kCVReturnSuccess,
              let pb = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pb, [])
        defer { CVPixelBufferUnlockBaseAddress(pb, []) }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pb),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pb),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            return nil
        }
        
        // Center crop: scale to fill, then center
        let srcW = CGFloat(cgImage.width)
        let srcH = CGFloat(cgImage.height)
        let targetW = CGFloat(width)
        let targetH = CGFloat(height)
        
        let scale = max(targetW / srcW, targetH / srcH)
        let scaledW = srcW * scale
        let scaledH = srcH * scale
        let x = (targetW - scaledW) / 2.0
        let y = (targetH - scaledH) / 2.0
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: x, y: y, width: scaledW, height: scaledH))
        
        return pb
    }
}

// MARK: - Errors

enum CoreMLError: Error, LocalizedError {
    case modelLoadFailed
    case invalidImageData
    case imageConversionFailed
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .modelLoadFailed:
            return "Failed to load Core ML model"
        case .invalidImageData:
            return "Invalid image data provided"
        case .imageConversionFailed:
            return "Failed to convert image for processing"
        case .noResults:
            return "No classification results from model"
        }
    }
}
