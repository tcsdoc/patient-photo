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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
    
    private var firstName: String {
        let trimmed = patientName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return trimmed.components(separatedBy: .whitespaces).first ?? ""
    }
    
    private var portraitTitle: String {
        firstName.isEmpty ? "Here's the portrait" : "Here's \(firstName)'s portrait"
    }
    
    private var portraitReadyTitle: String {
        firstName.isEmpty ? "Portrait is ready" : "\(firstName)'s portrait is ready"
    }
    
    private var savedMessage: String {
        firstName.isEmpty
            ? "The portrait is in the folder you picked."
            : "\(firstName)'s portrait is in the folder you picked."
    }

    private var useSideBySideActions: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Staff Portrait")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.brandHeaderText)
                        Text("Headshots for ID cards and badges")
                            .font(.subheadline)
                            .foregroundColor(.brandHeaderSubtext)
                        Text("v\(appVersion)")
                            .font(.custom("HelveticaNeue-Medium", size: 13))
                            .foregroundColor(.brandHeaderSubtext.opacity(0.85))
                    }

                    Spacer(minLength: 0)
                }
                .brandContentColumn()
                .padding(.horizontal, BrandLayout.horizontalPadding)
                .padding(.top, 20)
                
                Divider()
                    .background(Color.brandCream.opacity(0.25))
            }
            .background(Color.brandHeaderBackground)
            
            // Main Content
            ScrollView {
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
                .brandContentColumn(maxWidth: stepContentMaxWidth)
                .padding(.horizontal, BrandLayout.horizontalPadding)
                .padding(.vertical, 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.brandScreenBackground)
        }
        .background(Color.brandScreenBackground)
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
    
    private var stepContentMaxWidth: CGFloat {
        switch currentStep {
        case .headshotValidation, .finalPreview:
            return BrandLayout.wideContentMaxWidth
        default:
            return BrandLayout.contentMaxWidth
        }
    }

    private var nameEntryView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 50))
                    .foregroundColor(.brandGold)

                Text("Who's getting their picture taken?")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.brandPrimaryText)
                    .multilineTextAlignment(.center)

                Text("We'll check the lighting and framing for you, so it's right the first time.")
                    .font(.body)
                    .foregroundColor(.brandSecondaryText)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 20) {
                TextField("First and last name", text: $patientName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title3)
                    .frame(maxWidth: .infinity)
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
                        Text("Take Photo")
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle(isEnabled: isPatientNameValid, fillWidth: true))
                .disabled(!isPatientNameValid)
            }
            .brandCard()
        }
        .padding(.top, 20)
    }
    
    private var transferView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.brandGold)

                Text(portraitReadyTitle)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.brandPrimaryText)
                    .multilineTextAlignment(.center)

                Text("Checked and ready to save.")
                    .font(.body)
                    .foregroundColor(.brandSecondaryText)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 20) {
                Button(action: { showingDocumentPicker = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save Photo")
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle(fillWidth: true))
            }
            .brandCard()
        }
    }
    
    private var headshotValidationView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                if isAnalyzingHeadshot {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.brandGold)
                    Text("Checking your shot…")
                        .font(.title3)
                        .foregroundColor(.brandSecondaryText)
                } else if let result = headshotResult {
                    Image(systemName: result.isValidHeadshot ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(result.isValidHeadshot ? .brandSuccess : .brandWarning)
                    
                    Text(result.isValidHeadshot ? "Looking great!" : "Almost there. Let's try that one again.")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.brandPrimaryText)
                        .multilineTextAlignment(.center)
                    
                    if let photo = currentPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: BrandLayout.photoPreviewMaxWidth)
                            .frame(maxHeight: 220)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(result.isValidHeadshot ? Color.brandGold : Color.brandWarning, lineWidth: 3)
                            )
                    }
                }
            }
            
            VStack(spacing: 15) {
                if let result = headshotResult {
                    if result.isValidHeadshot {
                        Button(action: processValidatedPhoto) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle")
                                Text("Use This Photo")
                            }
                        }
                        .buttonStyle(BrandPrimaryButtonStyle(fillWidth: true))
                    } else {
                        validationRetryActions

                        Button(action: processValidatedPhoto) {
                            HStack(spacing: 12) {
                                Image(systemName: "photo")
                                Text("Use Anyway")
                            }
                        }
                        .buttonStyle(BrandSecondaryButtonStyle(fillWidth: true))
                    }
                }
            }
            .brandCard()
        }
    }
    
    private var finalPreviewView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(.brandGold)
                
                Text(portraitTitle)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.brandPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("This is exactly how it will be saved.")
                    .font(.body)
                    .foregroundColor(.brandSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if let finalImage = finalProcessedImage {
                VStack(spacing: 15) {
                    Image(uiImage: finalImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: BrandLayout.photoPreviewMaxWidth)
                        .frame(maxHeight: 260)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.brandGold, lineWidth: 3)
                        )

                    Text("640 × 480 pixels · Original background · JPEG")
                        .font(.caption)
                        .foregroundColor(.brandSecondaryText)
                        .multilineTextAlignment(.center)
                }
            }

            finalPreviewActions
                .brandCard()
        }
    }

    @ViewBuilder
    private var validationRetryActions: some View {
        let tips = validationTipsBox
        let retakeButton = Button(action: {
            currentStep = .camera
            headshotResult = nil
        }) {
            HStack(spacing: 12) {
                Image(systemName: "camera.rotate")
                Text("Retake Photo")
            }
        }
        .buttonStyle(BrandPrimaryButtonStyle(fillWidth: !useSideBySideActions))

        if useSideBySideActions {
            HStack(alignment: .top, spacing: 16) {
                tips
                retakeButton
                    .frame(maxWidth: BrandLayout.buttonMaxWidth)
            }
        } else {
            VStack(spacing: 16) {
                tips
                retakeButton
            }
        }
    }

    private var validationTipsBox: some View {
        VStack(spacing: 10) {
            Text("Tips")
                .font(.headline)
                .foregroundColor(.brandPrimaryText)

            VStack(alignment: .leading, spacing: 5) {
                Text("• Center the face in the frame")
                Text("• Find soft, even light on the face")
                Text("• Just one person in the shot")
            }
            .font(.body)
            .foregroundColor(.brandSecondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.brandSecondaryButtonBackground)
        .cornerRadius(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var finalPreviewActions: some View {
        let retakeButton = Button(action: {
            currentStep = .camera
            finalProcessedImage = nil
            headshotResult = nil
        }) {
            HStack(spacing: 8) {
                Image(systemName: "camera.rotate")
                Text("Retake Photo")
            }
        }
        .buttonStyle(BrandSecondaryButtonStyle(fillWidth: !useSideBySideActions))

        let saveButton = Button(action: saveToServer) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down")
                Text("Save Photo")
            }
        }
        .buttonStyle(BrandPrimaryButtonStyle(fillWidth: !useSideBySideActions))

        if useSideBySideActions {
            HStack(spacing: 16) {
                retakeButton
                    .frame(maxWidth: .infinity)
                saveButton
                    .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: 16) {
                retakeButton
                saveButton
            }
        }
    }
    
    private var completeView: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.brandGold)
                
                Text("Saved!")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.brandPrimaryText)
                
                Text(savedMessage)
                    .font(.body)
                    .foregroundColor(.brandSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                Button(action: resetForAnotherPhoto) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera")
                        Text("Take Another")
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle(fillWidth: true))
            }
            .brandCard()
        }
    }
    
    private func resetForAnotherPhoto() {
        currentStep = .nameEntry
        patientName = ""
        currentPhoto = nil
        headshotResult = nil
        finalProcessedImage = nil
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
        
        // Choose image based on availability - use cropped if available, otherwise original
        let chosenImage: UIImage
        if let croppedImage = headshotResult?.croppedImage {
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
        // FIRST: Normalize image orientation using UIKit to ensure consistent orientation
        let normalizedImage = normalizeImageOrientation(image)
        
        // Use high-quality Core Image approach with normalized image
        guard let ciImage = CIImage(image: normalizedImage) else {
            // Fallback to original UIKit method if CIImage fails
            return resizeImageUIKit(normalizedImage, to: targetSize)
        }
        
        // Calculate scaling to preserve as much content as possible while fitting in target size  
        let sourceSize = ciImage.extent.size
        
        // Use "fit inside" scaling to preserve maximum content (no cropping)
        let scaleX = targetSize.width / sourceSize.width
        let scaleY = targetSize.height / sourceSize.height
        let scale = min(scaleX, scaleY) // Use smaller scale to ensure entire image fits
        
        // Apply scaling transformation
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        // Calculate position for final composition - bias toward preserving top/bottom content
        let xOffset = (targetSize.width - scaledImage.extent.width) / 2
        // Bias toward top of image (typical headshot orientation) - use less strict centering
        let yOffset = max(0, (targetSize.height - scaledImage.extent.height) * 0.3)
        let positionedImage = scaledImage.transformed(by: CGAffineTransform(translationX: xOffset, y: yOffset))
        
        // Create professional light gray background (enhances all skin tones)
        let backgroundGray = CIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.0) // Light gray #F0F0F0
        let grayBackground = CIImage(color: backgroundGray).cropped(to: CGRect(origin: .zero, size: targetSize))
        
        // Composite scaled image over gray background
        guard let compositeFilter = CIFilter(name: "CISourceOverCompositing") else {
            return resizeImageUIKit(image, to: targetSize)
        }
        
        compositeFilter.setValue(positionedImage, forKey: kCIInputImageKey)
        compositeFilter.setValue(grayBackground, forKey: kCIInputBackgroundImageKey)
        
        guard let outputImage = compositeFilter.outputImage else {
            return resizeImageUIKit(image, to: targetSize)
        }
        
        // Render with high quality context
        let context = CIContext(options: [
            .useSoftwareRenderer: false,
            .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        ])
        
        guard let cgImage = context.createCGImage(outputImage, from: CGRect(origin: .zero, size: targetSize)) else {
            return resizeImageUIKit(image, to: targetSize)
        }
        
        // Create final UIImage with normalized orientation (Core Image has already applied transformations)
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    }
    
    // Fallback high-quality UIKit resizing method
    private func resizeImageUIKit(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        // Use high-quality format for UIGraphicsImageRenderer
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0  // Force 1x scale for consistent output
        format.opaque = true  // Better performance for opaque images
        format.preferredRange = .standard  // Use standard color range
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        
        return renderer.image { context in
            // Enable high-quality interpolation
            context.cgContext.interpolationQuality = .high
            context.cgContext.setShouldAntialias(true)
            context.cgContext.setAllowsAntialiasing(true)
            
            // Calculate scaling to preserve as much content as possible (no cropping)
            let sourceSize = image.size
            
            // Use "fit inside" scaling to preserve maximum content
            let scaleX = targetSize.width / sourceSize.width
            let scaleY = targetSize.height / sourceSize.height
            let scale = min(scaleX, scaleY) // Use smaller scale to ensure entire image fits
            
            let scaledSize = CGSize(
                width: sourceSize.width * scale,
                height: sourceSize.height * scale
            )
            
            // Calculate position for positioning - bias toward preserving top/bottom content
            let xOffset = (targetSize.width - scaledSize.width) / 2
            // Bias toward top of image (typical headshot orientation) - use less strict centering
            let yOffset = max(0, (targetSize.height - scaledSize.height) * 0.3)
            let drawRect = CGRect(x: xOffset, y: yOffset, width: scaledSize.width, height: scaledSize.height)
            
            // Fill background with professional light gray
            UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.0).setFill() // Light gray #F0F0F0
            UIRectFill(CGRect(origin: .zero, size: targetSize))
            
            // Draw the image with high quality
            image.draw(in: drawRect)
        }
    }
    
    /// Normalizes image orientation by redrawing the image with correct pixel orientation
    /// This ensures both Core Image and UIKit paths have properly oriented pixels
    private func normalizeImageOrientation(_ image: UIImage) -> UIImage {
        // If already .up orientation, return as-is
        if image.imageOrientation == .up {
            return image
        }
        
        // Calculate the proper size after orientation transformation
        let size = image.size
        
        // Create a bitmap context and draw the image with proper orientation
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: size))
        
        // Get the normalized image with .up orientation
        guard let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return image // Fallback to original if normalization fails
        }
        
        return normalizedImage
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
