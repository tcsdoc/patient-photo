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
    
    // Simple save for transfer - no progress tracking needed for 640x480 images
    func saveImageForTransfer(_ image: UIImage, filename: String) async -> Bool {
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
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