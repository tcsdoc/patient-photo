//
//  PhotoManager.swift
//  Patient Photo
//
//  Created by mark on 7/3/25.
//

import Foundation
import UIKit

class PhotoManager: ObservableObject {
    @Published var saveProgress: Double = 0.0
    @Published var isSaving: Bool = false
    @Published var lastError: String = ""
    
    func saveImage(_ image: UIImage, filename: String) async -> Bool {
        await MainActor.run {
            isSaving = true
            saveProgress = 0.0
            lastError = ""
        }
        
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            await MainActor.run {
                lastError = "Failed to convert image to JPEG"
                isSaving = false
            }
            return false
        }
        
        return await saveToDocuments(imageData: imageData, filename: filename)
    }
    
    // Save file to app's Documents directory where it can be accessed via Files app
    private func saveToDocuments(imageData: Data, filename: String) async -> Bool {
        await MainActor.run { saveProgress = 0.3 }
        
        do {
            // Get the app's Documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(filename)
            
            await MainActor.run { saveProgress = 0.7 }
            
            // Write the image data
            try imageData.write(to: fileURL)
            
            await MainActor.run {
                saveProgress = 1.0
                isSaving = false
                lastError = "Photo saved successfully to Files app."
            }
            
            return true
            
        } catch {
            await MainActor.run {
                lastError = "Failed to save file: \(error.localizedDescription)"
                isSaving = false
            }
            return false
        }
    }
    
    // Get the path to the saved file
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // Get list of saved files in Documents directory
    func getSavedFiles() -> [String] {
        do {
            let documentsPath = getDocumentsDirectory()
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            return files.compactMap { url in
                if url.pathExtension.lowercased() == "jpg" {
                    return url.lastPathComponent
                }
                return nil
            }.sorted(by: >)
        } catch {
            return []
        }
    }
    
    // Get the most recent file saved
    func getMostRecentFile() -> String? {
        let files = getSavedFiles()
        return files.first
    }
    
    // Get formatted save status
    func getSaveStatusMessage() -> String {
        if isSaving {
            let percentage = Int(saveProgress * 100)
            return "Saving... \(percentage)%"
        } else {
            return "Ready"
        }
    }
    
    // Cleanup old files (keep only last 10)
    func cleanupOldFiles() {
        let files = getSavedFiles()
        if files.count > 10 {
            let documentsPath = getDocumentsDirectory()
            let filesToDelete = Array(files.dropFirst(10))
            
            for filename in filesToDelete {
                let fileURL = documentsPath.appendingPathComponent(filename)
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
    
    // Create a share URL for the most recent file
    func shareRecentFile() -> URL? {
        guard let recentFile = getMostRecentFile() else { return nil }
        return getDocumentsDirectory().appendingPathComponent(recentFile)
    }
} 