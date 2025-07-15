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
    @State private var showingImportPicker = false
    @State private var showingVerificationInstructions = false
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
            DocumentPicker(
                sourceFileURL: photoManager.shareRecentFile() ?? URL(fileURLWithPath: ""), // Pass a dummy URL if no file
                isPresented: $showingDocumentPicker,
                hasTransferredToServer: $hasTransferredToServer,
                photoManager: photoManager,
                onExportComplete: { showingVerificationInstructions = true }
            )
        }
        .sheet(isPresented: $showingImportPicker) {
            DocumentImportPicker(
                isPresented: $showingImportPicker,
                photoManager: photoManager
            )
        }
        .sheet(isPresented: $showingVerificationInstructions) {
            VerificationInstructionsView(
                isPresented: $showingVerificationInstructions,
                showingImportPicker: $showingImportPicker
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
    
    private var successView: some View {
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
                VStack(spacing: 15) {
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
                    
                    Text("If you don’t see your photo on the server, tap “Save to Server” again to retry the transfer.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    
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
                            .frame(width: 120)
                            .frame(height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Spacer().frame(minWidth: 40)
                        
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
                            .frame(width: 120)
                            .frame(height: 50)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
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
            
            // Record the successful transfer
            if let recentFile = parent.photoManager.getMostRecentFile() {
                let patientName = recentFile.replacingOccurrences(of: ".jpg", with: "")
                print("[DEBUG] Attempting to record transfer for file: \(recentFile), patient: \(patientName)")
                parent.photoManager.recordTransfer(filename: recentFile, patientName: patientName)
            }
            
            // Mark as transferred and dismiss the sheet
            DispatchQueue.main.async {
                self.parent.hasTransferredToServer = true
                self.parent.isPresented = false
                self.parent.onExportComplete() // Call the closure
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

// MARK: - Document Import Picker
struct DocumentImportPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let photoManager: PhotoManager
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentImportPicker
        var alertController: UIAlertController?
        
        init(_ parent: DocumentImportPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // File was selected for verification
            guard let url = urls.first else {
                DispatchQueue.main.async { self.parent.isPresented = false }
                return
            }
            let filename = url.lastPathComponent
            let alert = UIAlertController(title: "File Verified", message: "File found on server: \(filename)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                DispatchQueue.main.async { self.parent.isPresented = false }
            })
            controller.present(alert, animated: true)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            DispatchQueue.main.async { self.parent.isPresented = false }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.jpeg])
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        picker.title = "Verify photo transferred"
        DispatchQueue.main.async {
            picker.navigationItem.prompt = "Browse to verify your file is present on the server. Tap any file to confirm."
        }
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        uiViewController.navigationItem.prompt = "Browse to verify your file is present on the server. Tap any file to confirm."
    }
}

struct VerificationInstructionsView: View {
    @Binding var isPresented: Bool
    @Binding var showingImportPicker: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Text("Verify Your Photo Transfer")
                .font(.title2)
                .bold()
            Text("In the next window, verify you see the photo transferred. If not, tap on 'Cancel' and then tap 'Save to Server' again to retry the transfer. You do not need to retake the picture unless you want a new photo.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
            Button(action: {
                isPresented = false
                showingImportPicker = true
            }) {
                Text("Continue")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}
