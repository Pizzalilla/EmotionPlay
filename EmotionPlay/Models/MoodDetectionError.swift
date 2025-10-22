//
//  MoodDetectionError.swift
//  EmotionPlay
//
//  Error types for mood detection
//

import Foundation

enum MoodDetectionError: Error, Identifiable {
    case noFaceDetected
    case lowConfidence(Double)
    case invalidImage
    case processingFailed(String)
    
    var id: String {
        switch self {
        case .noFaceDetected: return "noFace"
        case .lowConfidence: return "lowConf"
        case .invalidImage: return "invalid"
        case .processingFailed: return "failed"
        }
    }
    
    var title: String {
        switch self {
        case .noFaceDetected:
            return "No Face Detected"
        case .lowConfidence:
            return "Unclear Result"
        case .invalidImage:
            return "Invalid Photo"
        case .processingFailed:
            return "Something Went Wrong"
        }
    }
    
    var message: String {
        switch self {
        case .noFaceDetected:
            return "We couldn't detect a face in this photo. Please try again with a clear photo of yourself."
        case .lowConfidence(let conf):
            return "We're only \(Int(conf * 100))% confident about this mood. Try a photo with a clearer facial expression."
        case .invalidImage:
            return "This doesn't appear to be a valid photo. Please select a different image."
        case .processingFailed(let msg):
            return "We couldn't analyze this photo: \(msg)"
        }
    }
    
    var suggestions: [String] {
        switch self {
        case .noFaceDetected:
            return [
                "Use a photo with your face clearly visible",
                "Make sure there's good lighting",
                "Face the camera directly"
            ]
        case .lowConfidence:
            return [
                "Try a photo with a clearer expression",
                "Ensure good lighting conditions",
                "Use a recent, high-quality photo"
            ]
        case .invalidImage:
            return [
                "Select a photo from your library",
                "Take a new photo with your camera",
                "Make sure the file isn't corrupted"
            ]
        case .processingFailed:
            return [
                "Check your internet connection",
                "Try a different photo",
                "Restart the app if the issue persists"
            ]
        }
    }
}
