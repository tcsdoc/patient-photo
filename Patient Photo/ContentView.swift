//
//  ContentView.swift
//  Patient Photo
//
//  Created by mark on 7/2/25.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import Vision

struct ContentView: View {
    @State private var patientName = ""
    @State private var currentStep: Step = .nameEntry
    @State private var currentPhoto: UIImage?
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false
    @StateObject private var photoManager = PhotoManager()
    
    // Headshot validation states
    @State private var headshotResult: HeadshotDetector.HeadshotResult?
    @State private var isAnalyzingHeadshot = false
    @State private var showHeadshotGuidance = false
    @State private var useBackgroundRemoved = false
    @State private var finalProcessedImage: UIImage?
    
    enum Step {
        case nameEntry, camera, headshotValidation, finalPreview, transfer, complete
    }
    
    // Get app version from bundle
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    // Computed property for name validation
    private var isPatientNameValid: Bool {
        !patientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                        Text("AI-Powered Headshot Capture")
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
                case .camera:
                    EmptyView()
                case .headshotValidation:
                    headshotValidationView
                case .finalPreview:
                    finalPreviewView
                case .transfer:
                    transferView
                case .complete:
                    completeView
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
                sourceFileURL: photoManager.transferFileURL ?? URL(fileURLWithPath: ""),
                isPresented: $showingDocumentPicker,
                onExportComplete: { 
                    photoManager.cleanupAfterTransfer()
                    currentStep = .complete 
                }
            )
        }
        .onChange(of: currentStep) { newStep in
            if newStep == .camera {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingImagePicker = true
                }
            }
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
                    
                    Text("AI will analyze photo quality and ensure proper headshot framing")
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
                            if isPatientNameValid {
                                currentStep = .camera
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
                            .background(isPatientNameValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!isPatientNameValid)
                    }
                    .padding(32)
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var transferView: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("Headshot Ready to Transfer")
                    .font(.title2)
                    .bold()
                
                VStack(spacing: 8) {
                    Text("Patient: \(patientName)")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text("✅ AI-validated headshot (640x480)")
                        .font(.body)
                        .foregroundColor(.green)
                    
                    Text("Professional quality confirmed")
                        .font(.custom("HelveticaNeue-Medium", size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            VStack {
                Button(action: { showingDocumentPicker = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.title3)
                        Text("Save to Server")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .frame(minWidth: 280)
                    .frame(height: 60)
                    .padding(.horizontal, 20)
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
    
    private var headshotValidationView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                if isAnalyzingHeadshot {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Analyzing Photo...")
                        .font(.title3)
                        .foregroundColor(.secondary)
                } else if let result = headshotResult {
                    // Show photo analysis results
                    Image(systemName: result.isValidHeadshot ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(result.isValidHeadshot ? .green : .orange)
                    
                    Text(result.message)
                        .font(.title3)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    // Show photo preview with background removal toggle
                    if let photo = currentPhoto {
                        VStack(spacing: 15) {
                            // Background removal toggle (always show option)
                            HStack {
                                Text("Background Removal:")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Toggle("Remove Background", isOn: $useBackgroundRemoved)
                                    .labelsHidden()
                                    .disabled(result.backgroundRemovedImage == nil)
                            }
                            .padding(.horizontal)
                            
                            // Image preview
                            let displayImage = useBackgroundRemoved ? (result.backgroundRemovedImage ?? photo) : photo
                            
                            Image(uiImage: displayImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(result.isValidHeadshot ? Color.green : Color.orange, lineWidth: 3)
                                )
                            
                            // Show background removal status
                            if result.backgroundRemovedImage != nil {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Clean white background ready")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("Background removal unavailable - using original")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Show headshot details
                    VStack(spacing: 8) {
                        HStack {
                            Text("Faces detected:")
                            Spacer()
                            Text("\(result.faceCount)")
                                .fontWeight(.medium)
                        }
                        
                        if result.faceCount > 0 {
                            HStack {
                                Text("Face coverage:")
                                Spacer()
                                Text("\(Int(result.faceArea * 100))%")
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            
            // Action buttons
            VStack(spacing: 15) {
                if let result = headshotResult {
                    if result.isValidHeadshot {
                        // Use this photo
                        Button(action: processValidatedPhoto) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle")
                                    .font(.title3)
                                Text("Use This Photo")
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                            .frame(minWidth: 280)
                            .frame(height: 60)
                            .padding(.horizontal, 20)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    } else {
                        // Show guidance and retake option
                        VStack(spacing: 10) {
                            Text("💡 Headshot Tips:")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("• Position face in center of frame")
                                Text("• Ensure good lighting on face")
                                Text("• Face can be close or distant (10-80% of image)")
                                Text("• Only one person in photo")
                            }
                            .font(.body)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBlue).opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Retake photo option
                    Button(action: {
                        currentStep = .camera
                        headshotResult = nil
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.rotate")
                                .font(.title3)
                            Text("Retake Photo")
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                        .frame(minWidth: 280)
                        .frame(height: 60)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Use anyway option (for non-ideal photos)
                    if !result.isValidHeadshot {
                        Button(action: processValidatedPhoto) {
                            HStack(spacing: 12) {
                                Image(systemName: "photo")
                                    .font(.title3)
                                Text("Use Anyway")
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                            .frame(minWidth: 280)
                            .frame(height: 60)
                            .padding(.horizontal, 20)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
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
    
    private var finalPreviewView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Final Preview")
                    .font(.title2)
                    .bold()
                
                Text("This is exactly what will be saved to the server")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Show final processed image
            if let finalImage = finalProcessedImage {
                VStack(spacing: 15) {
                    Text("Patient: \(patientName)")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    // Final image preview with dimensions
                    VStack(spacing: 10) {
                        Image(uiImage: finalImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 240)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 3)
                            )
                        
                        // Show final specifications
                        VStack(spacing: 5) {
                            HStack {
                                Text("Dimensions:")
                                Spacer()
                                Text("640 × 480 pixels")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Background:")
                                Spacer()
                                Text(useBackgroundRemoved ? "White (removed)" : "Original")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("File format:")
                                Spacer()
                                Text("JPEG")
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Action buttons
            VStack(spacing: 15) {
                // Save to server button
                Button(action: saveToServer) {
                    HStack(spacing: 12) {
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.title3)
                        Text("Save to Server")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .frame(minWidth: 280)
                    .frame(height: 60)
                    .padding(.horizontal, 20)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Go back to make changes
                Button(action: {
                    currentStep = .headshotValidation
                    finalProcessedImage = nil
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.left.circle")
                            .font(.title3)
                        Text("Make Changes")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .frame(minWidth: 280)
                    .frame(height: 60)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
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
    
    private var completeView: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("Transfer Complete")
                    .font(.title2)
                    .bold()
                
                VStack(spacing: 8) {
                    Text("Photo successfully transferred to server.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Patient: \(patientName)")
                        .font(.title3)
                        .fontWeight(.medium)
                }
            }
            
            VStack(spacing: 15) {
                Button(action: {
                    // Reset for new photo instead of exiting
                    currentStep = .nameEntry
                    patientName = ""
                    currentPhoto = nil
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                        Text("New Photo")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .frame(width: 220)
                    .frame(height: 60)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    // App Store compliant: Reset to beginning instead of exit
                    // Apple guidelines discourage programmatic app termination
                    currentStep = .nameEntry
                    patientName = ""
                    currentPhoto = nil
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                        Text("Start Over")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .frame(width: 220)
                    .frame(height: 60)
                    .background(Color.gray)
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
        
        // Move to headshot validation step first
        currentStep = .headshotValidation
        
        // Analyze headshot quality
        Task {
            await MainActor.run {
                isAnalyzingHeadshot = true
            }
            
            let result = await HeadshotDetector.analyzeHeadshot(image)
            
            await MainActor.run {
                headshotResult = result
                isAnalyzingHeadshot = false
            }
        }
    }
    
    private func processValidatedPhoto() {
        guard let image = currentPhoto else { return }
        
        // Choose image based on user preference and availability
        let chosenImage: UIImage
        if useBackgroundRemoved, let backgroundRemovedImage = headshotResult?.backgroundRemovedImage {
            chosenImage = backgroundRemovedImage
        } else if let croppedImage = headshotResult?.croppedImage {
            chosenImage = croppedImage
        } else {
            chosenImage = image
        }
        
        // Create the final processed image (640x480) for preview
        let resizedImage = resizeImage(chosenImage, to: CGSize(width: 640, height: 480))
        finalProcessedImage = resizedImage
        
        // Move to final preview step
        currentStep = .finalPreview
    }
    
    private func saveToServer() {
        guard let finalImage = finalProcessedImage else { return }
        
        // Save photo for transfer
        Task {
            let filename = createFilename()
            let success = await photoManager.saveImageForTransfer(finalImage, filename: filename)
            
            await MainActor.run {
                if success {
                    currentStep = .transfer
                }
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let sourceFileURL: URL
    @Binding var isPresented: Bool
    let onExportComplete: () -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [sourceFileURL], asCopy: true)
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            DispatchQueue.main.async {
                self.parent.isPresented = false
                self.parent.onExportComplete()
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            DispatchQueue.main.async {
                self.parent.isPresented = false
            }
        }
    }
}

// MARK: - Helper Functions
extension ContentView {
    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: UIGraphicsImageRendererFormat.default())
        
        return renderer.image { _ in
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
            
            // Calculate center position for cropping
            let xOffset = (targetSize.width - scaledSize.width) / 2
            let yOffset = (targetSize.height - scaledSize.height) / 2
            let drawRect = CGRect(x: xOffset, y: yOffset, width: scaledSize.width, height: scaledSize.height)
            
            // Fill background with white
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: targetSize))
            
            // Draw the image
            image.draw(in: drawRect)
        }
    }
    
    private func createFilename() -> String {
        return "\(patientName).jpg"
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
