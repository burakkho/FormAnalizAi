# Form Analizi AI - Video Processing

## 🎥 Video İşleme Stratejisi

Video processing, Form Analizi AI'ın kritik bir parçasıdır. Kullanıcıdan gelen videoları optimize edip Gemini API'ya göndermeye hazır hale getiririz.

## 📋 Video Gereksinimleri

### Input (Kullanıcıdan Gelen)
- **Format**: MOV, MP4, M4V (iOS standart formatlar)
- **Çözünürlük**: Sınırsız (4K, 1080p, 720p, vs)
- **FPS**: 24-240 fps
- **Süre**: Minimum 5 saniye, maksimum sınırsız
- **Boyut**: Maksimum ~500 MB (iOS video recorder limiti)

### Output (API'ya Gönderilen)
- **Format**: MP4
- **Çözünürlük**: 1280x720 (720p)
- **FPS**: 30
- **Süre**: İlk 30 saniye
- **Codec**: H.264
- **Bitrate**: ~2 Mbps
- **Target Boyut**: 5-10 MB

## 🛠️ VideoProcessingService

### Service Interface

```swift
// VideoProcessingServiceProtocol.swift

protocol VideoProcessingServiceProtocol {
    /// Video'yu optimize eder (720p, 30fps, max 30sn, compression)
    func optimizeVideo(_ url: URL) async throws -> Data
    
    /// Video'dan thumbnail oluşturur
    func generateThumbnail(_ url: URL) async throws -> Data
    
    /// Video geçerliliğini kontrol eder
    func validateVideo(_ url: URL) throws -> Bool
    
    /// Video metadata'sını çıkarır (duration, resolution, etc)
    func extractMetadata(_ url: URL) async throws -> VideoMetadata
}

struct VideoMetadata {
    let duration: TimeInterval
    let resolution: CGSize
    let fps: Float
    let fileSize: Int64
}

enum VideoProcessingError: LocalizedError {
    case invalidFormat
    case tooShort
    case tooLarge
    case exportFailed
    case thumbnailGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Desteklenmeyen video formatı"
        case .tooShort:
            return "Video en az 5 saniye olmalı"
        case .tooLarge:
            return "Video çok büyük (max 500 MB)"
        case .exportFailed:
            return "Video işlenemedi"
        case .thumbnailGenerationFailed:
            return "Önizleme oluşturulamadı"
        }
    }
}
```

### Implementation

```swift
// VideoProcessingService.swift
import AVFoundation
import UIKit

actor VideoProcessingService: VideoProcessingServiceProtocol {
    
    // MARK: - Validate Video
    
    func validateVideo(_ url: URL) throws -> Bool {
        let asset = AVAsset(url: url)
        
        // 1. Format check
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            throw VideoProcessingError.invalidFormat
        }
        
        // 2. Duration check (minimum 5 saniye)
        let duration = CMTimeGetSeconds(asset.duration)
        guard duration >= 5 else {
            throw VideoProcessingError.tooShort
        }
        
        // 3. File size check (max 500 MB)
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
        let maxSize: Int64 = 500 * 1024 * 1024 // 500 MB
        guard fileSize <= maxSize else {
            throw VideoProcessingError.tooLarge
        }
        
        return true
    }
    
    // MARK: - Extract Metadata
    
    func extractMetadata(_ url: URL) async throws -> VideoMetadata {
        let asset = AVAsset(url: url)
        
        // Load properties asynchronously
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoProcessingError.invalidFormat
        }
        
        let naturalSize = try await videoTrack.load(.naturalSize)
        let nominalFrameRate = try await videoTrack.load(.nominalFrameRate)
        
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
        
        return VideoMetadata(
            duration: durationSeconds,
            resolution: naturalSize,
            fps: nominalFrameRate,
            fileSize: fileSize
        )
    }
    
    // MARK: - Optimize Video
    
    func optimizeVideo(_ url: URL) async throws -> Data {
        // 1. Validate
        _ = try validateVideo(url)
        
        let asset = AVAsset(url: url)
        
        // 2. Duration limit (max 30 saniye)
        let duration = try await asset.load(.duration)
        let maxDuration = CMTime(seconds: 30, preferredTimescale: 600)
        let timeRange = CMTimeRange(
            start: .zero,
            duration: min(duration, maxDuration)
        )
        
        // 3. Export session oluştur
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPreset1280x720 // 720p preset
        ) else {
            throw VideoProcessingError.exportFailed
        }
        
        // 4. Output URL
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        // 5. Export settings
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = timeRange
        exportSession.shouldOptimizeForNetworkUse = true
        
        // 6. Video composition (30 fps enforce)
        let composition = AVMutableComposition()
        
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw VideoProcessingError.exportFailed
        }
        
        guard let assetVideoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoProcessingError.exportFailed
        }
        
        try compositionVideoTrack.insertTimeRange(
            timeRange,
            of: assetVideoTrack,
            at: .zero
        )
        
        // 7. Export
        await exportSession.export()
        
        // 8. Check status
        switch exportSession.status {
        case .completed:
            // Success - load data
            let data = try Data(contentsOf: outputURL)
            
            // Cleanup
            try? FileManager.default.removeItem(at: outputURL)
            
            return data
            
        case .failed, .cancelled:
            throw VideoProcessingError.exportFailed
            
        default:
            throw VideoProcessingError.exportFailed
        }
    }
    
    // MARK: - Generate Thumbnail
    
    func generateThumbnail(_ url: URL) async throws -> Data {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        // Settings
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 400, height: 400)
        
        // İlk frame'i al (1 saniye)
        let time = CMTime(seconds: 1, preferredTimescale: 600)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            
            guard let jpegData = uiImage.jpegData(compressionQuality: 0.8) else {
                throw VideoProcessingError.thumbnailGenerationFailed
            }
            
            return jpegData
        } catch {
            throw VideoProcessingError.thumbnailGenerationFailed
        }
    }
}
```

## 🎬 Video Capture (Kamera)

### CameraViewController (UIKit - UIViewRepresentable)

```swift
// CameraView.swift
import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedVideoURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func didCaptureVideo(url: URL) {
            parent.capturedVideoURL = url
            parent.dismiss()
        }
        
        func didCancelCapture() {
            parent.dismiss()
        }
    }
}

// MARK: - Camera View Controller

protocol CameraViewControllerDelegate: AnyObject {
    func didCaptureVideo(url: URL)
    func didCancelCapture()
}

class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var isRecording = false
    private var recordButton: UIButton!
    private var cancelButton: UIButton!
    private var timerLabel: UILabel!
    
    private var recordingStartTime: Date?
    private var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        setupUI()
    }
    
    private func setupCamera() {
        // 1. Capture session
        let session = AVCaptureSession()
        session.sessionPreset = .high // 1080p veya mevcut en yüksek
        
        // 2. Video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            return
        }
        
        session.addInput(videoInput)
        
        // 3. Audio input (opsiyonel ama iyi olur)
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        
        // 4. Movie file output
        let output = AVCaptureMovieFileOutput()
        
        // Max recording duration (30 saniye)
        output.maxRecordedDuration = CMTime(seconds: 30, preferredTimescale: 1)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        // 5. Preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        self.captureSession = session
        self.videoOutput = output
        self.previewLayer = previewLayer
        
        // 6. Start session
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    private func setupUI() {
        // Record button
        recordButton = UIButton(type: .custom)
        recordButton.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        recordButton.center = CGPoint(
            x: view.bounds.midX,
            y: view.bounds.height - 100
        )
        recordButton.backgroundColor = .white
        recordButton.layer.cornerRadius = 40
        recordButton.layer.borderWidth = 5
        recordButton.layer.borderColor = UIColor.red.cgColor
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        view.addSubview(recordButton)
        
        // Cancel button
        cancelButton = UIButton(type: .system)
        cancelButton.setTitle("İptal", for: .normal)
        cancelButton.frame = CGRect(x: 20, y: 50, width: 60, height: 40)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        // Timer label
        timerLabel = UILabel()
        timerLabel.text = "00:00"
        timerLabel.textColor = .white
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 24, weight: .medium)
        timerLabel.frame = CGRect(x: 0, y: 50, width: view.bounds.width, height: 40)
        timerLabel.textAlignment = .center
        timerLabel.isHidden = true
        view.addSubview(timerLabel)
    }
    
    @objc private func recordButtonTapped() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    @objc private func cancelTapped() {
        if isRecording {
            stopRecording()
        }
        delegate?.didCancelCapture()
    }
    
    private func startRecording() {
        guard let videoOutput = videoOutput else { return }
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        videoOutput.startRecording(to: outputURL, recordingDelegate: self)
        
        isRecording = true
        recordingStartTime = Date()
        
        // UI updates
        recordButton.backgroundColor = .red
        timerLabel.isHidden = false
        
        // Timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func stopRecording() {
        videoOutput?.stopRecording()
        
        isRecording = false
        recordingStartTime = nil
        
        // UI updates
        recordButton.backgroundColor = .white
        timerLabel.isHidden = true
        
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimer() {
        guard let startTime = recordingStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        captureSession?.stopRunning()
    }
}

// MARK: - Recording Delegate

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if let error = error {
            print("Recording error: \(error)")
            return
        }
        
        // Video kaydedildi
        delegate?.didCaptureVideo(url: outputFileURL)
    }
}
```

## 📂 Video Gallery Picker

```swift
// VideoPickerView.swift
import SwiftUI
import PhotosUI

struct VideoPickerView: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPickerView
        
        init(_ parent: VideoPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else {
                parent.dismiss()
                return
            }
            
            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    guard let url = url, error == nil else {
                        return
                    }
                    
                    // Copy to temporary location
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(url.pathExtension)
                    
                    do {
                        try FileManager.default.copyItem(at: url, to: tempURL)
                        
                        DispatchQueue.main.async {
                            self.parent.selectedVideoURL = tempURL
                            self.parent.dismiss()
                        }
                    } catch {
                        print("Error copying video: \(error)")
                    }
                }
            }
        }
    }
}
```

## ⚡ Performance Optimizations

### 1. Background Processing

```swift
// Video processing'i background thread'de yap
Task.detached(priority: .userInitiated) {
    let optimizedData = try await videoProcessingService.optimizeVideo(url)
    
    await MainActor.run {
        // UI update
        self.processedVideo = optimizedData
    }
}
```

### 2. Memory Management

```swift
// Video data'yı kullandıktan sonra temizle
func cleanupTemporaryFiles() {
    let tempDir = FileManager.default.temporaryDirectory
    
    do {
        let tempFiles = try FileManager.default.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: nil
        )
        
        for file in tempFiles {
            try? FileManager.default.removeItem(at: file)
        }
    } catch {
        print("Error cleaning temp files: \(error)")
    }
}
```

### 3. Progress Tracking

```swift
// Export progress tracking
func optimizeVideoWithProgress(_ url: URL, progress: @escaping (Float) -> Void) async throws -> Data {
    // ... setup code ...
    
    // Progress observer
    let progressObserver = exportSession.observe(\.progress, options: [.new]) { session, _ in
        DispatchQueue.main.async {
            progress(session.progress)
        }
    }
    
    await exportSession.export()
    
    progressObserver.invalidate()
    
    // ... rest of code ...
}
```

## 🔐 Privacy & Permissions

### Info.plist Entries

```xml
<key>NSCameraUsageDescription</key>
<string>Egzersiz videolarınızı çekmek için kamera erişimi gerekiyor.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Video ses kaydı için mikrofon erişimi gerekiyor.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Galerinizdeki egzersiz videolarını seçmek için erişim gerekiyor.</string>
```

### Permission Handling

```swift
// PermissionManager.swift
import AVFoundation
import Photos

actor PermissionManager {
    
    func requestCameraPermission() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
    
    func requestPhotoLibraryPermission() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
    
    func checkPermissions() async -> (camera: Bool, photos: Bool) {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let photosStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        return (
            camera: cameraStatus == .authorized,
            photos: photosStatus == .authorized || photosStatus == .limited
        )
    }
}
```

## 🧪 Testing

### Unit Tests

```swift
class VideoProcessingServiceTests: XCTestCase {
    var sut: VideoProcessingService!
    
    override func setUp() {
        super.setUp()
        sut = VideoProcessingService()
    }
    
    func testValidateVideo_ValidVideo_ReturnsTrue() async throws {
        let testVideoURL = Bundle.main.url(forResource: "test_video", withExtension: "mp4")!
        
        let result = try sut.validateVideo(testVideoURL)
        
        XCTAssertTrue(result)
    }
    
    func testOptimizeVideo_4KVideo_Returns720p() async throws {
        let testVideoURL = Bundle.main.url(forResource: "4k_test", withExtension: "mp4")!
        
        let optimizedData = try await sut.optimizeVideo(testVideoURL)
        
        XCTAssertLessThan(optimizedData.count, 15_000_000) // < 15 MB
    }
}
```

---

**Not**: Video processing CPU-intensive bir işlemdir. Kullanıcıya progress göster ve işlemi background thread'de yap.
