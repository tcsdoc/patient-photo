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
    @StateObject private var photoManager = PhotoManager()
    
    enum Step {
        case nameEntry, photo, photoReady, transferComplete
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
                            .bold()
                        Text("Capture and Save to Server")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("v\(appVersion)")
                            .font(.custom("HelveticaNeue-Medium", size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
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
                case .photoReady:
                    photoReadyView
                case .transferComplete:
                    transferCompleteView
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
            DocumentPicker(
                sourceFileURL: photoManager.shareRecentFile() ?? URL(fileURLWithPath: ""),
                isPresented: $showingDocumentPicker,
                photoManager: photoManager,
                onExportComplete: { currentStep = .transferComplete }
            )
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
    
    private var nameEntryView: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(.systemTeal).opacity(0.18), Color(.systemGreen).opacity(0.12)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 40) {
                VStack(spacing: 20) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Enter Patient Name")
                        .font(.title2)
                        .bold()
                    
                    Text("Photos will be captured and ready to save to server")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBlue).opacity(0.08))
                        .shadow(color: Color(.systemBlue).opacity(0.10), radius: 8, x: 0, y: 4)
                    VStack(spacing: 20) {
                        TextField("Patient Name", text: $patientName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title3)
                            .frame(width: 300)
                            .multilineTextAlignment(.center)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                            .onChange(of: patientName) { newValue in
                                patientName = String(newValue.prefix(16))
                            }
                        
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
                            .frame(height: 60)
                            .frame(width: 300)
                            .multilineTextAlignment(.center)
                            .background(patientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(patientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(32)
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var photoReadyView: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Image(systemName: isSaving ? "photo.badge.checkmark" : "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(isSaving ? .orange : .green)
                
                Text(isSaving ? "Saving Photo..." : "Photo Ready to Save")
                    .font(.title2)
                    .bold()
                
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
                                    .font(.custom("HelveticaNeue-Medium", size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Text("✅ Photo captured (640x480)")
                                .font(.body)
                                .foregroundColor(.green)
                            
                            Text("Ready to save to server")
                                .font(.custom("HelveticaNeue-Medium", size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if !isSaving && !photoManager.isSaving {
                VStack {
                    // Save to Server button
                    Button(action: { showingDocumentPicker = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "icloud.and.arrow.up")
                                .font(.title3)
                            Text("Save to Server")
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                        .frame(width: 220)
                        .frame(height: 60)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBlue).opacity(0.08))
                        .shadow(color: Color(.systemBlue).opacity(0.10), radius: 8, x: 0, y: 4)
                )
            }
        }
    }
    
    private var transferCompleteView: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("Transfer Complete")
                    .font(.title2)
                    .bold()
                
                VStack(spacing: 8) {
                    Text("Your photo has been successfully transferred to the server.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Patient: \(lastCopiedPatient)")
                        .font(.title3)
                        .fontWeight(.medium)
                }
            }
            
            VStack(spacing: 15) {
                Button(action: {
                    exit(0)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark")
                            .font(.title3)
                        Text("Exit")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .frame(width: 220)
                    .frame(height: 60)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBlue).opacity(0.08))
                    .shadow(color: Color(.systemBlue).opacity(0.10), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    private func handleImagePicked() {
        guard let image = currentPhoto else { return }
        
        lastCopiedPatient = patientName
        currentStep = .photoReady
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
    let photoManager: PhotoManager
    let onExportComplete: () -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Use asCopy: true to always copy, not move
        let picker = UIDocumentPickerViewController(forExporting: [sourceFileURL], asCopy: true)
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
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
                self.parent.isPresented = false
                self.parent.onExportComplete()
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
    

}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
