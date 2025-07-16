# Patient Photo App

**Version 1.3.1** | **App Store Ready** | **Medical Photography Solution**

A streamlined iOS app designed for medical professionals to capture patient photos and transfer them to a server for healthcare documentation purposes.

## 📱 Overview

Patient Photo is a specialized medical app that simplifies the process of capturing, processing, and transferring patient photographs. Built with privacy and compliance in mind, it's optimized for healthcare environments and ready for App Store distribution.

## ✨ Key Features

- **📸 Professional Photo Capture**: Rear camera only for consistent medical documentation
- **🎯 Standardized Output**: 640x480 JPEG format with optimized compression
- **🏥 Medical-Focused UI**: Clean, professional interface designed for healthcare settings
- **📁 Server Integration**: Seamless transfer via iOS Files app to network storage
- **🔒 Privacy Compliant**: Proper camera permissions with medical-focused descriptions
- **📲 iPad Optimized**: Designed specifically for tablet use in clinical environments

## 🚀 Quick Start

### System Requirements
- **Device**: iPad (Mini, Air, Pro)
- **iOS**: 15.6 or later
- **Storage**: Minimal (< 10MB)
- **Network**: Wi-Fi access to server (192.168.1.24)

### Installation
1. Install from App Store (coming soon) or via developer deployment
2. Trust developer certificate if installing via Xcode
3. Grant camera permissions when prompted
4. Configure Files app with server connection

## 🎯 Workflow

The app follows a simple 4-step process:

```
1. ENTER PATIENT NAME
   ↓
2. CAPTURE PHOTO (Auto-opens camera)
   ↓
3. TRANSFER TO SERVER (Via Files app)
   ↓
4. COMPLETE (Option to start new photo)
```

### Step-by-Step Usage

1. **Patient Name Entry**
   - Enter patient name (up to 16 characters)
   - Tap "Take Photo" to proceed

2. **Photo Capture**
   - Camera opens automatically
   - Uses rear camera for consistency
   - Tap capture when ready

3. **Photo Processing**
   - Automatically resizes to 640x480
   - Converts to JPEG format
   - Creates filename: `PatientName.jpg`

4. **Server Transfer**
   - Tap "Save to Server"
   - iOS Files app opens
   - Navigate to server location
   - Save file to complete transfer

5. **Completion**
   - Success confirmation displayed
   - Choose "New Photo" or "Start Over"

## 🔧 Technical Specifications

### App Architecture
- **Language**: Swift 5.0
- **Framework**: SwiftUI
- **Target**: iOS 15.6+
- **Bundle ID**: `com.marlixholdings.Patient-Photo`
- **Category**: Medical

### Image Processing
- **Resolution**: 640x480 pixels
- **Format**: JPEG
- **Compression**: 0.8 quality ratio
- **Aspect Ratio**: Maintained with white background fill
- **File Size**: ~50-150KB per image

### Privacy & Permissions
- **Camera Access**: Required for photo capture
- **Purpose**: "This medical app requires camera access to capture patient photos for healthcare documentation purposes"
- **No Photo Library Access**: App doesn't access existing photos

## 🏥 Medical Use Case

### Designed For
- **Dermatology**: Skin condition documentation
- **Wound Care**: Progress tracking
- **General Practice**: Patient identification
- **Dental**: Oral health documentation
- **Research**: Clinical study photography

### Compliance Features
- **HIPAA Considerations**: Local processing, no cloud storage
- **File Management**: Automatic cleanup after transfer
- **Professional Output**: Consistent image quality
- **Audit Trail**: Filename includes patient identifier

## 🔒 App Store Compliance

### ✅ Compliance Checklist
- [x] No private APIs used
- [x] Proper camera permission handling
- [x] Professional privacy descriptions
- [x] Medical app category set
- [x] Clean app lifecycle management
- [x] No forced app termination
- [x] Production-ready code quality

### Privacy Policy Requirements
When submitting to App Store, include:
- Camera usage for medical photography
- Local storage and automatic cleanup
- No personal data collection
- Server transfer via user action only

## 🛠 Development Setup

### Prerequisites
- Xcode 15.0+
- iOS 15.6+ deployment target
- Apple Developer Account
- Device for testing

### Build Instructions
```bash
# Clone repository
git clone https://github.com/tcsdoc/patient-photo.git
cd patient-photo

# Open in Xcode
open "Patient Photo.xcodeproj"

# Build and run
# Select target device
# Command+R to build and run
```

### Configuration
1. Update `DEVELOPMENT_TEAM` in project settings
2. Configure provisioning profile
3. Adjust bundle identifier if needed
4. Set deployment target as required

## 📁 Project Structure

```
Patient Photo/
├── ContentView.swift          # Main UI and workflow logic
├── PhotoManager.swift         # Image processing and file management
├── ImagePicker.swift          # Camera interface wrapper
├── Patient_PhotoApp.swift     # App entry point
└── Assets.xcassets/           # App icons and visual assets
    ├── AppIcon.appiconset/    # App icons for different sizes
    └── AccentColor.colorset/  # App accent color
```

## 🔄 Version History

### Version 1.3.1 (Current)
- **App Store Compliance**: Removed private API usage
- **Enhanced Privacy**: Improved permission descriptions
- **UX Improvements**: Professional app lifecycle management
- **Bug Fixes**: Proper filename handling without timestamps

### Version 1.3.0
- **Simplified Workflow**: Removed unnecessary buttons and features
- **UI Cleanup**: Streamlined interface for medical use
- **Performance**: Optimized for 640x480 image processing

### Version 1.2.5
- Initial medical app version
- Basic photo capture and transfer functionality

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Common Issues
- **Camera not working**: Check privacy permissions in Settings
- **Files app issues**: Ensure server connection is configured
- **App crashes**: Verify iOS version compatibility

### Contact
- **Repository**: [GitHub Issues](https://github.com/tcsdoc/patient-photo/issues)
- **Email**: Support available through GitHub

## 🎯 Roadmap

### Planned Features
- [ ] Batch photo processing
- [ ] Enhanced metadata support
- [ ] Multi-language support
- [ ] Dark mode optimization
- [ ] Accessibility improvements

### Medical Enhancements
- [ ] DICOM format support
- [ ] Integration with EMR systems
- [ ] Advanced image annotations
- [ ] Quality assurance checks

---

**Built for Healthcare Professionals** | **Ready for App Store** | **Version 1.3.1** 