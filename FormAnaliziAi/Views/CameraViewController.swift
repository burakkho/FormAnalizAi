//
//  CameraViewController.swift
//  FormAnaliziAi
//
//  Created by Burak Macbook Mini on 5.10.2025.
//

import SwiftUI
@preconcurrency import AVFoundation
import UIKit

// MARK: - Camera View (SwiftUI Wrapper)
struct CameraView: UIViewControllerRepresentable {
    @Binding var videoURL: URL?
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
        var onFinishRecording: @MainActor @Sendable (URL) -> Void
        var onCancel: @MainActor @Sendable () -> Void

        init(_ parent: CameraView) {
            self.onFinishRecording = { @MainActor url in
                parent.videoURL = url
                parent.dismiss()
            }
            self.onCancel = { @MainActor in
                parent.dismiss()
            }
        }

        func cameraDidFinishRecording(url: URL) {
            let handler = onFinishRecording
            Task { @MainActor in
                handler(url)
            }
        }

        func cameraDidCancel() {
            let handler = onCancel
            Task { @MainActor in
                handler()
            }
        }
    }
}

// MARK: - Camera Delegate Protocol
protocol CameraViewControllerDelegate: AnyObject {
    func cameraDidFinishRecording(url: URL)
    func cameraDidCancel()
}

// MARK: - Camera View Controller
@MainActor
class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?

    // Camera
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // UI Elements
    private let recordButton = UIButton()
    private let cancelButton = UIButton()
    private let timerLabel = UILabel()

    // ViewModel
    private let viewModel = CameraViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            await setupCamera()
        }
        setupUI()
        setupViewModel()
    }

    // MARK: - ViewModel Setup
    private func setupViewModel() {
        // Observe ViewModel state changes using Task
        Task { @MainActor [weak self] in
            while self != nil {
                try? await Task.sleep(nanoseconds: Constants.Timing.timerUpdateInterval)

                guard let self = self else { break }

                // Update timer label from ViewModel
                self.timerLabel.text = self.viewModel.formattedDuration

                // Handle max duration reached
                if self.viewModel.maxDurationReached && self.viewModel.isRecording {
                    self.stopRecording()
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    // MARK: - Camera Setup
    private func setupCamera() async {
        // Request camera permission
        let cameraAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        guard cameraAuthorized else {
            showPermissionDeniedAlert()
            return
        }

        // Request microphone permission
        let microphoneAuthorized = await AVCaptureDevice.requestAccess(for: .audio)
        // Continue even if microphone denied (video only mode)

        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high

        // Video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            Configuration.log("Failed to get video device", category: .video, level: .error)
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            guard captureSession?.canAddInput(videoInput) == true else {
                Configuration.log("Cannot add video input to capture session", category: .video, level: .error)
                return
            }
            captureSession?.addInput(videoInput)
        } catch {
            Configuration.log("Failed to create video input: \(error.localizedDescription)", category: .video, level: .error)
            return
        }

        // Audio input (only if authorized)
        if microphoneAuthorized {
            if let audioDevice = AVCaptureDevice.default(for: .audio) {
                do {
                    let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                    if captureSession?.canAddInput(audioInput) == true {
                        captureSession?.addInput(audioInput)
                    } else {
                        Configuration.log("Cannot add audio input to capture session", category: .video, level: .debug)
                    }
                } catch {
                    Configuration.log("Failed to create audio input: \(error.localizedDescription)", category: .video, level: .debug)
                }
            } else {
                Configuration.log("No audio device available", category: .video, level: .debug)
            }
        }

        // Video output
        videoOutput = AVCaptureMovieFileOutput()
        if let videoOutput = videoOutput,
           captureSession?.canAddOutput(videoOutput) == true {
            captureSession?.addOutput(videoOutput)
        }

        // Preview layer
        if let captureSession = captureSession {
            await MainActor.run {
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer?.videoGravity = .resizeAspectFill
            }
        }
    }

    @MainActor
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Kamera İzni Gerekli",
            message: "Form Analizi AI'nin video kaydedebilmesi için kamera erişimine ihtiyacı var. Lütfen Ayarlar > Gizlilik > Kamera'dan izin verin.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ayarlar", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel) { [weak self] _ in
            self?.delegate?.cameraDidCancel()
        })
        present(alert, animated: true)
    }

    private func setupUI() {
        view.backgroundColor = .black

        // Preview layer
        if let previewLayer = previewLayer {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }

        // Record button
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.backgroundColor = .red
        recordButton.layer.cornerRadius = 35
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        view.addSubview(recordButton)

        // Cancel button
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("İptal", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        view.addSubview(cancelButton)

        // Timer label
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.textColor = .white
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 24, weight: .semibold)
        timerLabel.textAlignment = .center
        timerLabel.text = "00:00"
        timerLabel.isHidden = true
        view.addSubview(timerLabel)

        // Constraints
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            recordButton.widthAnchor.constraint(equalToConstant: 70),
            recordButton.heightAnchor.constraint(equalToConstant: 70),

            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),

            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
    }

    // MARK: - Session Control
    private func startSession() {
        guard let session = captureSession else { return }
        Task.detached(priority: .userInitiated) {
            session.startRunning()
        }
    }

    private func stopSession() {
        guard let session = captureSession else { return }
        Task.detached(priority: .userInitiated) {
            session.stopRunning()
        }
    }

    // MARK: - Recording
    @objc private func recordButtonTapped() {
        if viewModel.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        guard let videoOutput = videoOutput else { return }

        // Create temporary file URL
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        // Start recording
        videoOutput.startRecording(to: outputURL, recordingDelegate: self)

        // Update UI
        recordButton.backgroundColor = .white
        timerLabel.isHidden = false

        // Start timer via ViewModel
        viewModel.startRecording()
    }

    private func stopRecording() {
        videoOutput?.stopRecording()

        // Stop timer via ViewModel
        viewModel.stopRecording()

        // Update UI
        recordButton.backgroundColor = .red
        timerLabel.isHidden = true
    }

    @objc private func cancelButtonTapped() {
        if viewModel.isRecording {
            stopRecording()
        }
        delegate?.cameraDidCancel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            Configuration.log("Recording failed: \(error.localizedDescription)", category: .video, level: .error)
            return
        }

        // Notify delegate on main actor
        Task { @MainActor [weak self] in
            self?.delegate?.cameraDidFinishRecording(url: outputFileURL)
        }
    }
}
