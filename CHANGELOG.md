# Changelog

All notable changes to the Patient Photo app will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.1] - 2025-07-16

### 🚀 App Store Compliance Release

#### Added
- Professional camera permission description for medical use
- App Store compliant app lifecycle management
- Enhanced privacy descriptions in project configuration

#### Changed
- **BREAKING**: Replaced problematic exit button with "Start Over" functionality
- Removed photo library usage permission (not needed)
- Updated camera permission description to be more medical-focused
- Improved button text from "Exit App" to "Start Over"
- Enhanced user experience with proper app state management

#### Removed
- Private API usage (`UIApplication.shared.perform(#selector(NSXPCConnection.suspend))`)
- Unnecessary photo library access permission
- Forced app termination functionality

#### Fixed
- App Store rejection risk due to private API usage
- Privacy permission descriptions now properly explain medical use case
- Improved app compliance with Apple Human Interface Guidelines

#### Technical
- Updated `INFOPLIST_KEY_NSCameraUsageDescription` for medical compliance
- Removed `INFOPLIST_KEY_NSPhotoLibraryUsageDescription` 
- Code cleanup and optimization for production release

---

## [1.3.0] - 2025-07-15

### 🎯 Simplified Medical Workflow

#### Added
- Streamlined 4-step workflow: Name → Camera → Transfer → Complete
- Enhanced UI with medical-focused design
- Professional gradient backgrounds and styling
- Version display in app header

#### Changed
- **BREAKING**: Removed "New Patient" button from Photo Ready screen
- **BREAKING**: Removed instructional text for cleaner interface
- **BREAKING**: Simplified to single "Save to Server" button
- Increased button spacing for better iPad usability
- Updated app display name to "Patient Photo"

#### Removed
- Exit button from Photo Ready screen
- New Patient workflow and reset functionality
- Instructional text: "Navigate to your server location and save the photo file"
- Complex verification workflows
- Unnecessary progress tracking features

#### Fixed
- Button spacing and layout issues on iPad
- Simplified user experience for medical professionals
- Reduced cognitive load with streamlined interface

#### Technical
- Cleaned up unused code and components
- Optimized for medical use case
- Improved state management efficiency

---

## [1.2.5] - 2025-07-02

### 🏥 Initial Medical App Version

#### Added
- Basic photo capture functionality with rear camera
- Patient name entry with 16-character limit
- 640x480 image processing and JPEG compression
- Files app integration for server transfer
- iOS 15.6+ compatibility
- iPad-optimized interface

#### Features
- Camera-only photo capture (no photo library)
- Automatic image resizing to 640x480 pixels
- JPEG format with 0.8 compression quality
- White background fill for consistent aspect ratio
- Simple filename generation with patient name
- Document picker integration for file transfer
- Basic error handling and user feedback

#### Technical
- SwiftUI-based user interface
- MVVM architecture pattern
- Proper memory management
- Clean separation of concerns
- Medical app category configuration

---

## Development Notes

### App Store Submission Checklist
- [x] Remove all private API usage
- [x] Implement proper privacy permissions
- [x] Add professional permission descriptions
- [x] Ensure medical app category is set
- [x] Test on physical devices
- [x] Verify no forced app termination
- [x] Clean code and remove debug artifacts
- [x] Update version numbers consistently

### Future Considerations
- DICOM format support for medical imaging standards
- Integration with Electronic Health Records (EHR) systems
- Enhanced metadata for medical documentation
- Batch processing capabilities
- Advanced image quality assurance
- Multi-language support for international use
- Accessibility improvements for healthcare professionals

### Breaking Changes Summary
- **1.3.1**: App lifecycle management changes (exit → start over)
- **1.3.0**: Removed New Patient workflow and simplified UI
- **1.2.5**: Initial release baseline

---

*For detailed technical documentation, see [README.md](README.md)* 