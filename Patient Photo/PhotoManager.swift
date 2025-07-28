//
//  PhotoManager.swift
//  Patient Photo
//
//  Created by mark on 7/3/25.
//

import Foundation
import UIKit

class PhotoManager: ObservableObject {
    private(set) var transferFileURL: URL?
    
    // High-quality save for transfer - optimized for medical documentation
    func saveImageForTransfer(_ image: UIImage, filename: String) async -> Bool {
        // Convert image to JPEG data with high quality (0.95 for medical documentation)
        guard let imageData = image.jpegData(compressionQuality: 0.95) else {
            return false
        }
        
        do {
            // Get the app's Documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(filename)
            
            // Write the image data
            try imageData.write(to: fileURL)
            
            // Store URL for transfer
            await MainActor.run {
                self.transferFileURL = fileURL
            }
            
            return true
            
        } catch {
            await MainActor.run {
                self.transferFileURL = nil
            }
            return false
        }
    }
    
    // Clean up after successful transfer
    func cleanupAfterTransfer() {
        guard let fileURL = transferFileURL else { return }
        
        try? FileManager.default.removeItem(at: fileURL)
        transferFileURL = nil
    }
} 