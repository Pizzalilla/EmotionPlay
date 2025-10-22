//
//  FaceDetectionHelper.swift
//  EmotionPlay
//
//  Face detection validation using Vision framework - FIXED double-resume bug
//

import Foundation
import Vision
import UIKit
import OSLog

private let logger = Logger(subsystem: "com.emotionplay.facedetection", category: "Validation")

final class FaceDetectionHelper {
    
    /// Check if image contains at least one face
    /// - Parameter imageData: Image data to analyze
    /// - Returns: True if face detected, false otherwise
    static func containsFace(imageData: Data) async throws -> Bool {
        guard let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else {
            logger.error("❌ Could not create CGImage from data")
            throw FaceDetectionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false  // 🔒 Prevent double-resume
            let lock = NSLock()
            
            func safeResume(with result: Result<Bool, Error>) {
                lock.lock()
                defer { lock.unlock() }
                
                guard !hasResumed else {
                    logger.warning("⚠️ Attempted to resume face detection continuation twice")
                    return
                }
                hasResumed = true
                
                switch result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error = error {
                    logger.error("❌ Face detection error: \(error.localizedDescription)")
                    safeResume(with: .failure(error))
                    return
                }
                
                guard let results = request.results as? [VNFaceObservation] else {
                    logger.warning("⚠️ No face observations returned")
                    safeResume(with: .success(false))
                    return
                }
                
                let faceCount = results.count
                logger.info("👤 Detected \(faceCount) face(s)")
                
                // Return true if at least one face found
                safeResume(with: .success(faceCount > 0))
            }
            
            // Configure request
            request.revision = VNDetectFaceRectanglesRequestRevision3
            
            // Perform detection on background queue
            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    try handler.perform([request])
                } catch {
                    logger.error("❌ Handler error: \(error.localizedDescription)")
                    safeResume(with: .failure(error))
                }
            }
        }
    }
    
    /// Detect faces with detailed information (position, quality, etc.)
    /// - Parameter imageData: Image data to analyze
    /// - Returns: Array of face observations with quality metrics
    static func detectFacesWithQuality(imageData: Data) async throws -> [FaceQuality] {
        guard let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else {
            throw FaceDetectionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            let lock = NSLock()
            
            func safeResume(with result: Result<[FaceQuality], Error>) {
                lock.lock()
                defer { lock.unlock() }
                
                guard !hasResumed else { return }
                hasResumed = true
                
                switch result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            let request = VNDetectFaceCaptureQualityRequest { request, error in
                if let error = error {
                    safeResume(with: .failure(error))
                    return
                }
                
                guard let results = request.results as? [VNFaceObservation] else {
                    safeResume(with: .success([]))
                    return
                }
                
                let qualities = results.compactMap { observation -> FaceQuality? in
                    guard let quality = observation.faceCaptureQuality else { return nil }
                    return FaceQuality(
                        quality: quality,
                        boundingBox: observation.boundingBox
                    )
                }
                
                safeResume(with: .success(qualities))
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    try handler.perform([request])
                } catch {
                    safeResume(with: .failure(error))
                }
            }
        }
    }
}

// MARK: - Models

struct FaceQuality {
    let quality: Float  // 0.0 to 1.0
    let boundingBox: CGRect
    
    var qualityPercentage: Int {
        Int(quality * 100)
    }
    
    var isGoodQuality: Bool {
        quality >= 0.5
    }
}

enum FaceDetectionError: Error, LocalizedError {
    case invalidImage
    case detectionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not process image"
        case .detectionFailed:
            return "Face detection failed"
        }
    }
}
