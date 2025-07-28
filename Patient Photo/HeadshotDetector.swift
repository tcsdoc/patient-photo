//
//  HeadshotDetector.swift
//  Patient Photo
//
//  Created by AI Assistant on 2025-07-16.
//

import Vision
import UIKit

class HeadshotDetector {
    
    struct HeadshotResult {
        let isValidHeadshot: Bool
        let faceCount: Int
        let faceArea: CGFloat
        let faceBoundingBox: CGRect?
        let croppedImage: UIImage?
        let backgroundRemovedImage: UIImage?
        let message: String
    }
    
    /// Analyzes an image to determine if it's a valid headshot and removes background
    /// - Parameter image: The UIImage to analyze
    /// - Returns: HeadshotResult with analysis details and background-removed image
    static func analyzeHeadshot(_ image: UIImage) async -> HeadshotResult {
        guard let cgImage = image.cgImage else {
            return HeadshotResult(
                isValidHeadshot: false,
                faceCount: 0,
                faceArea: 0,
                faceBoundingBox: nil,
                croppedImage: nil,
                backgroundRemovedImage: nil,
                message: "Unable to process image"
            )
        }
        
        // Perform background removal first
        let backgroundRemovedImage = await removeBackground(from: image)
        
        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error = error {
                    print("Face detection error: \(error)")
                    continuation.resume(returning: HeadshotResult(
                        isValidHeadshot: false,
                        faceCount: 0,
                        faceArea: 0,
                        faceBoundingBox: nil,
                        croppedImage: nil,
                        backgroundRemovedImage: backgroundRemovedImage,
                        message: "Face detection failed"
                    ))
                    return
                }
                
                guard let results = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: HeadshotResult(
                        isValidHeadshot: false,
                        faceCount: 0,
                        faceArea: 0,
                        faceBoundingBox: nil,
                        croppedImage: nil,
                        backgroundRemovedImage: backgroundRemovedImage,
                        message: "No face detection results"
                    ))
                    return
                }
                
                let faceCount = results.count
                
                // Check for exactly one face
                guard faceCount == 1 else {
                    let message = faceCount == 0 ? "No face detected" : "Multiple faces detected (\(faceCount))"
                    continuation.resume(returning: HeadshotResult(
                        isValidHeadshot: false,
                        faceCount: faceCount,
                        faceArea: 0,
                        faceBoundingBox: nil,
                        croppedImage: nil,
                        backgroundRemovedImage: backgroundRemovedImage,
                        message: message
                    ))
                    return
                }
                
                let face = results[0]
                let faceBoundingBox = face.boundingBox
                
                // Convert Vision coordinates to image coordinates
                let imageWidth = CGFloat(cgImage.width)
                let imageHeight = CGFloat(cgImage.height)
                
                // Vision uses normalized coordinates (0-1), Y-flipped
                let faceRect = CGRect(
                    x: faceBoundingBox.minX * imageWidth,
                    y: (1 - faceBoundingBox.maxY) * imageHeight,
                    width: faceBoundingBox.width * imageWidth,
                    height: faceBoundingBox.height * imageHeight
                )
                
                let faceArea = faceBoundingBox.width * faceBoundingBox.height
                let imageArea: CGFloat = 1.0 // Normalized area
                let faceAreaPercentage = faceArea / imageArea
                
                // Headshot criteria
                let minFaceArea: CGFloat = 0.10  // Face should occupy at least 10% of image
                let maxFaceArea: CGFloat = 0.80  // But not more than 80% (too close)
                
                let isValidSize = faceAreaPercentage >= minFaceArea && faceAreaPercentage <= maxFaceArea
                
                // Additional criteria: face should be reasonably centered
                let faceCenterX = faceBoundingBox.midX
                let faceCenterY = faceBoundingBox.midY
                let isReasonablyCentered = abs(faceCenterX - 0.5) < 0.3 && abs(faceCenterY - 0.5) < 0.3
                
                let isValidHeadshot = isValidSize && isReasonablyCentered
                
                // Create cropped image if valid
                var croppedImage: UIImage?
                if isValidHeadshot {
                    croppedImage = cropToHeadshot(image: image, faceRect: faceRect)
                }
                
                // Generate appropriate message
                let message: String
                if isValidHeadshot {
                    message = "Perfect headshot! ✅"
                } else if !isValidSize {
                    if faceAreaPercentage < minFaceArea {
                        message = "Face too small - move a bit closer"
                    } else {
                        message = "Face too large - move back"
                    }
                } else {
                    message = "Center face in frame"
                }
                
                continuation.resume(returning: HeadshotResult(
                    isValidHeadshot: isValidHeadshot,
                    faceCount: faceCount,
                    faceArea: faceAreaPercentage,
                    faceBoundingBox: faceRect,
                    croppedImage: croppedImage,
                    backgroundRemovedImage: backgroundRemovedImage,
                    message: message
                ))
            }
            
            // Configure request for better face detection
            request.revision = VNDetectFaceRectanglesRequestRevision3
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Error performing face detection: \(error)")
                continuation.resume(returning: HeadshotResult(
                    isValidHeadshot: false,
                    faceCount: 0,
                    faceArea: 0,
                    faceBoundingBox: nil,
                    croppedImage: nil,
                    backgroundRemovedImage: backgroundRemovedImage,
                    message: "Detection error: \(error.localizedDescription)"
                ))
            }
        }
    }
    
    /// Removes background from image using person segmentation
    /// - Parameter image: Original image
    /// - Returns: Image with background removed (transparent) or nil if segmentation fails
    static func removeBackground(from image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        return await withCheckedContinuation { continuation in
            let request = VNGeneratePersonSegmentationRequest { request, error in
                if let error = error {
                    print("Person segmentation error: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let result = request.results?.first as? VNPixelBufferObservation else {
                    print("No person segmentation results")
                    continuation.resume(returning: nil)
                    return
                }
                
                let maskPixelBuffer = result.pixelBuffer
                
                // Create masked image with white background
                let maskedImage = createMaskedImage(from: cgImage, mask: maskPixelBuffer)
                continuation.resume(returning: maskedImage)
            }
            
            // Configure for highest quality
            request.qualityLevel = .accurate
            request.outputPixelFormat = kCVPixelFormatType_OneComponent8
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Error performing person segmentation: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    /// Creates an image with white background using the segmentation mask
    /// - Parameters:
    ///   - cgImage: Original image
    ///   - mask: Segmentation mask from Vision
    /// - Returns: Image with white background, preserving original quality and dimensions
    private static func createMaskedImage(from cgImage: CGImage, mask: CVPixelBuffer) -> UIImage? {
        let originalImage = CIImage(cgImage: cgImage)
        let maskImage = CIImage(cvPixelBuffer: mask)
        
        // Ensure mask covers the full original image dimensions
        let scaleX = originalImage.extent.width / maskImage.extent.width
        let scaleY = originalImage.extent.height / maskImage.extent.height
        
        // Use uniform scaling to maintain aspect ratio
        let scale = min(scaleX, scaleY)
        let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        // Center the mask if needed
        let offsetX = (originalImage.extent.width - scaledMask.extent.width) / 2
        let offsetY = (originalImage.extent.height - scaledMask.extent.height) / 2
        let centeredMask = scaledMask.transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
        
        // Create clean white background exactly matching original dimensions
        let whiteBackground = CIImage(color: CIColor.white).cropped(to: originalImage.extent)
        
        // Use a simpler masking approach that preserves quality
        guard let multiplyFilter = CIFilter(name: "CIMultiplyCompositing") else { return nil }
        
        // First, create the person cutout
        multiplyFilter.setValue(originalImage, forKey: kCIInputImageKey)
        multiplyFilter.setValue(centeredMask, forKey: kCIInputBackgroundImageKey)
        
        guard let maskedPerson = multiplyFilter.outputImage else { return nil }
        
        // Then blend the masked person onto white background
        guard let blendFilter = CIFilter(name: "CISourceOverCompositing") else { return nil }
        blendFilter.setValue(maskedPerson, forKey: kCIInputImageKey)
        blendFilter.setValue(whiteBackground, forKey: kCIInputBackgroundImageKey)
        
        guard let finalImage = blendFilter.outputImage else { return nil }
        
        // Convert back to UIImage with high quality settings
        let context = CIContext(options: [
            .useSoftwareRenderer: false,
            .highQualityResampling: true
        ])
        
        guard let cgOutputImage = context.createCGImage(finalImage, from: originalImage.extent) else { return nil }
        
        // Preserve original image orientation and scale
        let originalUIImage = UIImage(cgImage: cgImage)
        return UIImage(cgImage: cgOutputImage, scale: originalUIImage.scale, orientation: originalUIImage.imageOrientation)
    }
    
    /// Crops image to focus on the detected face with proper headshot framing
    /// - Parameters:
    ///   - image: Original image
    ///   - faceRect: Detected face rectangle
    /// - Returns: Cropped image optimized for headshot
    private static func cropToHeadshot(image: UIImage, faceRect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        // Expand face rect to include shoulders/neck area (typical headshot framing)
        let expandedWidth = faceRect.width * 1.8  // 80% wider
        let expandedHeight = faceRect.height * 2.2  // 120% taller
        
        let expandedX = faceRect.midX - (expandedWidth / 2)
        let expandedY = faceRect.midY - (expandedHeight * 0.4) // Face in upper portion
        
        let expandedRect = CGRect(
            x: max(0, expandedX),
            y: max(0, expandedY),
            width: min(expandedWidth, CGFloat(cgImage.width) - max(0, expandedX)),
            height: min(expandedHeight, CGFloat(cgImage.height) - max(0, expandedY))
        )
        
        // Crop the image
        guard let croppedCGImage = cgImage.cropping(to: expandedRect) else { return nil }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    /// Quick validation function for basic use cases
    /// - Parameter image: Image to validate
    /// - Returns: True if image contains a properly sized, centered face
    static func isValidHeadshot(_ image: UIImage) async -> Bool {
        let result = await analyzeHeadshot(image)
        return result.isValidHeadshot
    }
} 