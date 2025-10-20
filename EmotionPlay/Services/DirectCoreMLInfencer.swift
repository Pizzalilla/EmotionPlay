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
import OSLog

// Create a logger for better debugging on device
private let logger = Logger(subsystem: "com.emotionplay.inference", category: "CoreML")

final class DirectCoreMLInferencer: MoodInferencer {
    
    // MARK: - Properties
    
    private let model: EmotiPlayFinal
    private let inputSize: CGSize
    private let inferenceQueue = DispatchQueue(label: "com.emotionplay.inference", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init() throws {
        logger.info("🔍 Loading Core ML model...")
        
        let config = MLModelConfiguration()
        // Use .all for best performance on real devices (uses Neural Engine when available)
        config.computeUnits = .all
        
        guard let mlModel = try? EmotiPlayFinal(configuration: config) else {
            logger.error("❌ Failed to initialize EmotiPlayModel")
            throw CoreMLError.modelLoadFailed
        }
        self.model = mlModel
        
        // Get input size from model
        let desc = mlModel.model.modelDescription
        guard let firstInput = desc.inputDescriptionsByName.first?.value,
              let constraint = firstInput.imageConstraint else {
            logger.error("❌ Failed to get model input constraints")
            throw CoreMLError.modelLoadFailed
        }
        
        self.inputSize = CGSize(width: constraint.pixelsWide, height: constraint.pixelsHigh)
        logger.info("✅ Model loaded: \(Int(self.inputSize.width))x\(Int(self.inputSize.height))")
    }
    
    // MARK: - MoodInferencer Protocol
    
    func infer(fromImageData data: Data) async throws -> (Mood, Double) {
        logger.info("🖼️ Starting inference with image data of size: \(data.count) bytes")
        
        guard let uiImage = UIImage(data: data) else {
            logger.error("❌ Failed to create UIImage from data")
            throw CoreMLError.invalidImageData
        }
        logger.info("✅ UIImage created: \(uiImage.size.width)x\(uiImage.size.height)")
        
        guard let cgImage = uiImage.cgImage else {
            logger.error("❌ Failed to get CGImage from UIImage")
            throw CoreMLError.invalidImageData
        }
        logger.info("✅ CGImage obtained")
        
        // Create pixel buffer with center crop (matches Xcode preview)
        guard let pixelBuffer = Self.makePixelBuffer(from: cgImage, targetSize: inputSize) else {
            logger.error("❌ Failed to create pixel buffer")
            throw CoreMLError.imageConversionFailed
        }
        logger.info("✅ Pixel buffer created")
        
        return try await withCheckedThrowingContinuation { continuation in
            inferenceQueue.async { [weak self] in
                guard let self = self else {
                    logger.error("❌ Self was deallocated during inference")
                    continuation.resume(throwing: CoreMLError.modelLoadFailed)
                    return
                }
                
                do {
                    logger.info("🔮 Running model prediction...")
                    let prediction = try self.model.prediction(image: pixelBuffer)
                    logger.info("✅ Prediction completed")
                    
                    let predictedLabel = prediction.target
                    let probabilities = prediction.targetProbability
                    let confidence = probabilities[predictedLabel] ?? 0.0
                    
                    logger.info("📊 Predictions:")
                    let sortedProbs = probabilities.sorted(by: { $0.value > $1.value })
                    for (label, prob) in sortedProbs {
                        logger.info("  \(label): \(Int(prob * 100))%")
                    }
                    
                    let mood = self.mapClassificationToMood(predictedLabel)
                    logger.info("✅ Final: \(predictedLabel) → \(mood.rawValue) (\(Int(confidence * 100))%)")
                    
                    // Also print to console for backward compatibility
                    print("📊 DirectCoreML Predictions:")
                    for (label, prob) in sortedProbs {
                        print("  \(label): \(Int(prob * 100))%")
                    }
                    print("✅ Result: \(predictedLabel) → \(mood.rawValue) (\(Int(confidence * 100))%)")
                    
                    continuation.resume(returning: (mood, confidence))
                    
                } catch {
                    logger.error("❌ Prediction error: \(error.localizedDescription)")
                    print("❌ DirectCoreML Prediction error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func mapClassificationToMood(_ label: String) -> Mood {
        let lowercased = label.lowercased()
        logger.info("🔄 Mapping '\(label)' to mood...")
        
        switch lowercased {
        case "happy":
            return .happy
        case "sad":
            return .sad
        case "angry":
            return .angry
        case "surprised":
            return .energetic
        case "fear", "fearful":
            return .anxious
        case "disgust":
            return .angry
        case "neutral":
            return .calm
        default:
            logger.warning("⚠️ Unexpected label: '\(label)', defaulting to calm")
            return .calm
        }
    }
    
    // MARK: - Pixel Buffer Creation
    
    /// Creates a pixel buffer with center crop (matches Xcode's preview behavior)
    private static func makePixelBuffer(from cgImage: CGImage, targetSize: CGSize) -> CVPixelBuffer? {
        let width = Int(targetSize.width)
        let height = Int(targetSize.height)
        
        logger.info("🎨 Creating pixel buffer: \(width)x\(height)")
        
        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true
        ]
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let pb = pixelBuffer else {
            logger.error("❌ CVPixelBufferCreate failed with status: \(status)")
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
            logger.error("❌ Failed to create CGContext")
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
        
        logger.info("📐 Image transform - scale: \(String(format: "%.2f", scale)), offset: (\(String(format: "%.1f", x)), \(String(format: "%.1f", y)))")
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: x, y: y, width: scaledW, height: scaledH))
        
        logger.info("✅ Pixel buffer created successfully")
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
