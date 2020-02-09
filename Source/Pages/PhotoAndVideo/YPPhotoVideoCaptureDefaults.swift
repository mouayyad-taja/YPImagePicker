//
//  File.swift
//  YPImagePicker
//
//  Created by Mouayyad Taja on 2/5/20.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation

extension YPPhotoVideoCapture {
    
    // MARK: - Setup
    
    private func setupCaptureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high//.hd1920x1080
        let cameraPosition: AVCaptureDevice.Position = YPConfig.usesFrontCamera ? .front : .back
        let aDevice = deviceForPosition(cameraPosition)
        if let d = aDevice {
            deviceInput = try? AVCaptureDeviceInput(device: d)
        }
        if let videoInput = deviceInput {
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }
            if session.canAddOutput(output) {
                session.addOutput(output)
                configure()
            }
            
            // Add audio recording
            for device in AVCaptureDevice.devices(for: .audio) {
                if let audioInput = try? AVCaptureDeviceInput(device: device) {
                    if session.canAddInput(audioInput) {
                        session.addInput(audioInput)
                    }
                }
            }
            
            let timeScale: Int32 = 30 // FPS
            let maxDuration =
                CMTimeMakeWithSeconds(self.videoRecordingTimeLimit, preferredTimescale: timeScale)
            videoOutput.maxRecordedDuration = maxDuration
            videoOutput.minFreeDiskSpaceLimit = 1024 * 1024
            if (YPConfig.video.fileType == .mp4) {
                videoOutput.movieFragmentInterval = .invalid // Allows audio for MP4s over 10 seconds.
            }
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
            //session.sessionPreset = .high
        }
        session.commitConfiguration()
        isCaptureSessionSetup = true
    }
    
    // MARK: - Start/Stop Camera
    
    func start(with previewView: UIView, withVideoRecordingLimit: TimeInterval,  completion: @escaping () -> Void) {
        self.previewView = previewView
        self.videoRecordingTimeLimit = withVideoRecordingLimit
        sessionQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            if !strongSelf.isCaptureSessionSetup {
                strongSelf.setupCaptureSession()
            }
            strongSelf.startCamera(completion: {
                completion()
            })
        }
    }
    
    func startCamera(completion: @escaping (() -> Void)) {
        if !session.isRunning {
            sessionQueue.async { [weak self] in
                // Re-apply session preset
                self?.session.sessionPreset = .high//.hd1920x1080
                let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
                switch status {
                case .notDetermined, .restricted, .denied:
                    self?.session.stopRunning()
                case .authorized:
                    self?.session.startRunning()
                    completion()
                    self?.tryToSetupPreview()
                @unknown default:
                    fatalError()
                }
            }
        }
    }
    
    func stopCamera() {
        if session.isRunning {
            sessionQueue.async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }
    
    func refresh(){
        self.session.sessionPreset = .high
        self.currentCameraMode = .camera
    }
    
    // MARK: - Preview
    
    func tryToSetupPreview() {
        if !isPreviewSetup {
            setupPreview()
            isPreviewSetup = true
        }
    }
    
    func setupPreview() {
        videoLayer = AVCaptureVideoPreviewLayer(session: session)
        DispatchQueue.main.async {
            self.videoLayer.frame = self.previewView.bounds
            self.videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.previewView.layer.addSublayer(self.videoLayer)
        }
    }
    
//    func hide(){
//        self.videoLayer?.isHidden = true
//    }
//    func show(){
//        self.videoLayer?.isHidden = false
//    }
    // MARK: - Focus
    
    func focus(on point: CGPoint) {
        setFocusPointOnDevice(device: device!, point: point)
    }
    
    // MARK: - Zoom
    
    func zoom(began: Bool, scale: CGFloat) {
        guard let device = device else {
            return
        }
        
        if began {
            initVideoZoomFactor = device.videoZoomFactor
            return
        }
        
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            
            var minAvailableVideoZoomFactor: CGFloat = 1.0
            if #available(iOS 11.0, *) {
                minAvailableVideoZoomFactor = device.minAvailableVideoZoomFactor
            }
            var maxAvailableVideoZoomFactor: CGFloat = device.activeFormat.videoMaxZoomFactor
            if #available(iOS 11.0, *) {
                maxAvailableVideoZoomFactor = device.maxAvailableVideoZoomFactor
            }
            maxAvailableVideoZoomFactor = min(maxAvailableVideoZoomFactor, YPConfig.maxCameraZoomFactor)
            
            let desiredZoomFactor = initVideoZoomFactor * scale
            device.videoZoomFactor = max(minAvailableVideoZoomFactor, min(desiredZoomFactor, maxAvailableVideoZoomFactor))
        }
        catch let error {
            print("💩 \(error)")
        }
    }
    
    // MARK: - Flip
    
    func flipCamera(completion: @escaping () -> Void) {
        sessionQueue.async { [weak self] in
            self?.flip()
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    private func flip() {
        session.beginConfiguration()
        
        session.resetInputs()
        guard let di = deviceInput else { return }
        deviceInput = flippedDeviceInputForInput(di)
        guard let deviceInput = deviceInput else { return }
        if session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        }
        
        // Re Add audio recording
        for device in AVCaptureDevice.devices(for: .audio) {
            if let audioInput = try? AVCaptureDeviceInput(device: device) {
                if self.session.canAddInput(audioInput) {
                    self.session.addInput(audioInput)
                }
            }
        }
        session.commitConfiguration()
    }
    
    // MARK: - Orientation
    
    func setCurrentOrienation() {
        let connection = output.connection(with: .video)
        let orientation = YPDeviceOrientationHelper.shared.currentDeviceOrientation
        switch orientation {
        case .portrait:
            connection?.videoOrientation = .portrait
        case .portraitUpsideDown:
            connection?.videoOrientation = .portraitUpsideDown
        case .landscapeRight:
            connection?.videoOrientation = .landscapeLeft
        case .landscapeLeft:
            connection?.videoOrientation = .landscapeRight
        default:
            connection?.videoOrientation = .portrait
        }
    }
    
    
    // MARK: - Torch
    
    public func hasTorch() -> Bool {
        return device?.hasTorch ?? false
    }
    
    public func currentTorchMode() -> AVCaptureDevice.TorchMode {
        guard let device = device else {
            return .off
        }
        if !device.hasTorch {
            return .off
        }
        return device.torchMode
    }
    
    public func toggleTorch() {
        device?.tryToggleTorch()
    }
    
    public func setTorch(torchMode: AVCaptureDevice.TorchMode) {
        device?.trySetTorch(torchMode: torchMode)
    }
    
    
    // MARK: - Recording
    
    public func startRecording() {
        self.currentCameraMode = .video
        self.session.sessionPreset = .high
        self.setTorch(torchMode: self.currentFlashMode.torchMode())
        let outputURL = YPVideoProcessor.makeVideoPathURL(temporaryFolder: true, fileName: "recordedVideoRAW")
        
        checkOrientation { [weak self] orientation in
            guard let strongSelf = self else {
                return
            }
            if let connection = strongSelf.videoOutput.connection(with: .video) {
                if let orientation = orientation, connection.isVideoOrientationSupported {
                    connection.videoOrientation = orientation
                }
                if let recordingDelegate = strongSelf as? AVCaptureFileOutputRecordingDelegate {
                    strongSelf.videoOutput.startRecording(to: outputURL, recordingDelegate: recordingDelegate)
                }
            }
        }
    }
    
    public func stopRecording() {
        videoOutput.stopRecording()
    }
    
    

    
    // MARK: - Orientation

    /// This enables to get the correct orientation even when the device is locked for orientation \o/
    private func checkOrientation(completion: @escaping(_ orientation: AVCaptureVideoOrientation?)->()) {
        motionManager.accelerometerUpdateInterval = 5
        motionManager.startAccelerometerUpdates( to: OperationQueue() ) { [weak self] data, _ in
            self?.motionManager.stopAccelerometerUpdates()
            guard let data = data else {
                completion(nil)
                return
            }
            let orientation: AVCaptureVideoOrientation = abs(data.acceleration.y) < abs(data.acceleration.x)
                ? data.acceleration.x > 0 ? .landscapeLeft : .landscapeRight
                : data.acceleration.y > 0 ? .portraitUpsideDown : .portrait
            DispatchQueue.main.async {
                completion(orientation)
            }
        }
    }
}

@available(iOS 10.0, *)
extension PostiOS10PhotoVideoCapture: AVCaptureFileOutputRecordingDelegate {
    
    public func fileOutput(_ captureOutput: AVCaptureFileOutput,
                           didStartRecordingTo fileURL: URL,
                           from connections: [AVCaptureConnection]) {
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(tick),
                                     userInfo: nil,
                                     repeats: true)
        dateVideoStarted = Date()
    }
    
    public func fileOutput(_ captureOutput: AVCaptureFileOutput,
                           didFinishRecordingTo outputFileURL: URL,
                           from connections: [AVCaptureConnection],
                           error: Error?) {
        YPVideoProcessor.cropToSquare(filePath: outputFileURL) { [weak self] url in
            guard let _self = self, let u = url else { return }
            _self.didCaptureVideo?(u)
        }
        timer.invalidate()
    }
    
    // MARK: - Recording Progress    
    @objc func tick() {
        let timeElapsed = Date().timeIntervalSince(dateVideoStarted)
        let progress: Float = Float(timeElapsed) / Float(videoRecordingTimeLimit)
        DispatchQueue.main.async {
            self.videoRecordingProgress?(progress, timeElapsed)
        }
    }
}

