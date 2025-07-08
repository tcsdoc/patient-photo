//
//  ContentView.swift
//  Patient Photo
//
//  Created by mark on 7/2/25.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var patientName = ""
    @State private var currentStep: Step = .nameEntry
    @State private var currentPhoto: UIImage?
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var lastCopiedPatient = ""
    @State private var saveStatus = "Ready"
    @State private var isSaving = false
    @State private var showingDocumentPicker = false
    @State private var hasTransferredToServer = false
    @StateObject private var photoManager = PhotoManager()
    
    enum Step {
        case nameEntry, photo, success
    }
    
    // Get app version from bundle
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Patient Photo")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Capture and Save to Server")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("v\(appVersion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    // Save Status
                    HStack(spacing: 8) {
                        Circle()
                            .fill(saveStatusColor)
                            .frame(width: 8, height: 8)
                        Text(photoManager.isSaving ? photoManager.getSaveStatusMessage() : saveStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Divider()
            }
            .background(Color(.systemGray6))
            
            // Main Content
            VStack(spacing: 30) {
                switch currentStep {
                case .nameEntry:
                    nameEntryView
                case .photo:
                    EmptyView()
                case .success:
                    successView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $currentPhoto, onImagePicked: handleImagePicked)
        }
        .sheet(isPresented: $showingDocumentPicker) {
            if let fileURL = photoManager.shareRecentFile() {
                DocumentPicker(sourceFileURL: fileURL, isPresented: $showingDocumentPicker, hasTransferredToServer: $hasTransferredToServer)
            }
        }
        .onChange(of: currentStep) { newStep in
            if newStep == .photo {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingImagePicker = true
                }
            }
        }
        .alert("Save to Server", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var saveStatusColor: Color {
        if photoManager.isSaving {
            return .orange
        }
        
        switch saveStatus {
        case "Ready", "Photo Saved":
            return .green
        case "Saving...":
            return .orange
        default:
            return .gray
        }
    }
    
    private var nameEntryView: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Enter Patient Name")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Photos will be captured and ready to save to server")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                TextField("Patient Name", text: $patientName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title3)
                    .frame(height: 60)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                
                Button(action: {
                    if !patientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        currentStep = .photo
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera")
                            .font(.title3)
                        Text("Take Photo")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(patientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(patientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private var successView: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Image(systemName: isSaving ? "photo.badge.checkmark" : "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(isSaving ? .orange : .green)
                
                Text(isSaving ? "Saving Photo..." : "Photo Saved!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    Text("Patient: \(lastCopiedPatient)")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    if isSaving || photoManager.isSaving {
                        VStack(spacing: 8) {
                            Text("Saving to Files app...")
                                .font(.body)
                                .foregroundColor(.orange)
                            
                            if photoManager.isSaving {
                                ProgressView(value: photoManager.saveProgress)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .frame(width: 200)
                                
                                Text("\(Int(photoManager.saveProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Text("✅ Photo captured (640x480)")
                                .font(.body)
                                .foregroundColor(.green)
                            
                            Text("Ready to save to server")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if !isSaving && !photoManager.isSaving {
                VStack(spacing: 15) {
                    // Save to Server button
                    Button(action: {
                        showingDocumentPicker = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: hasTransferredToServer ? "checkmark.icloud" : "icloud.and.arrow.up")
                                .font(.title3)
                            Text(hasTransferredToServer ? "Transferred to Server" : "Save to Server")
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(hasTransferredToServer ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(hasTransferredToServer)
                    
                    // Secondary actions
                    HStack(spacing: 15) {
                        Button(action: {
                            resetForNewPatient()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.body)
                                Text("New Patient")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            exit(0)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark")
                                    .font(.body)
                                Text("Exit")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }
    
    private func handleImagePicked() {
        guard let image = currentPhoto else { return }
        
        lastCopiedPatient = patientName
        currentStep = .success
        isSaving = true
        saveStatus = "Saving..."
        
        // Resize the image to 640x480 before saving
        let resizedImage = resizeImage(image, to: CGSize(width: 640, height: 480))
        
        // Save resized photo to device
        Task {
            let filename = createFilename()
            let success = await photoManager.saveImage(resizedImage, filename: filename)
            
            await MainActor.run {
                isSaving = false
                saveStatus = success ? "Photo Saved" : "Save Failed"
            }
        }
    }
    
}

struct DocumentPicker: UIViewControllerRepresentable {
    let sourceFileURL: URL
    @Binding var isPresented: Bool
    @Binding var hasTransferredToServer: Bool
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Create a document picker that will export the file to a chosen location
        let picker = UIDocumentPickerViewController(forExporting: [sourceFileURL])
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        
        // Set the delegate to handle the completion
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // File was successfully saved to the chosen location
            print("File saved to: \(urls)")
            // Mark as transferred and dismiss the sheet
            DispatchQueue.main.async {
                self.parent.hasTransferredToServer = true
                self.parent.isPresented = false
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // User cancelled the operation
            print("Document picker cancelled")
            // Dismiss the sheet
            DispatchQueue.main.async {
                self.parent.isPresented = false
            }
        }
    }
}

// MARK: - Helper Functions
extension ContentView {
    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        // Calculate the aspect ratio
        let sourceSize = image.size
        let sourceAspectRatio = sourceSize.width / sourceSize.height
        let targetAspectRatio = targetSize.width / targetSize.height
        
        var scaledSize: CGSize
        
        if sourceAspectRatio > targetAspectRatio {
            // Source is wider, fit to height
            scaledSize = CGSize(width: targetSize.height * sourceAspectRatio, height: targetSize.height)
        } else {
            // Source is taller, fit to width
            scaledSize = CGSize(width: targetSize.width, height: targetSize.width / sourceAspectRatio)
        }
        
        // Create graphics context
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        // Calculate center position for cropping
        let xOffset = (targetSize.width - scaledSize.width) / 2
        let yOffset = (targetSize.height - scaledSize.height) / 2
        let drawRect = CGRect(x: xOffset, y: yOffset, width: scaledSize.width, height: scaledSize.height)
        
        // Fill background with white (in case image doesn't fill entire area)
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: targetSize))
        
        // Draw the image
        image.draw(in: drawRect)
        
        // Get the resized image
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        
        return resizedImage
    }
    
    private func createFilename() -> String {
        return "\(lastCopiedPatient).jpg"
    }
    
    private func resetForNewPatient() {
        patientName = ""
        currentPhoto = nil
        lastCopiedPatient = ""
        currentStep = .nameEntry
        saveStatus = "Ready"
        isSaving = false
        hasTransferredToServer = false
        photoManager.cleanupOldFiles()
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
