//
//  File.swift
//  YPImagePicker
//
//  Created by Mouayyad Taja on 2/5/20.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import CoreMotion

class PreiOS10PhotoVideoCapture: YPPhotoVideoCapture {
    
    internal var currentCameraMode: CameraMode! = .camera
    var cameraMode: CameraMode{ return currentCameraMode}
    
    let sessionQueue = DispatchQueue(label: "YPCameraVideoVCSerialQueue", qos: .background)
    let session = AVCaptureSession()
    var deviceInput: AVCaptureDeviceInput?
    var device: AVCaptureDevice? { return deviceInput?.device }
    private let imageOutput = AVCaptureStillImageOutput()
    var output: AVCaptureOutput { return imageOutput }
    var isCaptureSessionSetup: Bool = false
    var isPreviewSetup: Bool = false
    var previewView: UIView!
    var videoLayer: AVCaptureVideoPreviewLayer!
    var currentFlashMode: YPFlashMode = .off
    var hasFlash: Bool {
        guard let device = device else { return false }
        return device.hasFlash
    }
    var initVideoZoomFactor: CGFloat = 1.0
    
    
    
    var isRecording: Bool { return videoOutput.isRecording }
    var didCaptureVideo: ((URL) -> Void)?
    var videoRecordingProgress: ((Float, TimeInterval) -> Void)?
    
    internal var timer = Timer()
    internal var dateVideoStarted = Date()
//    internal var videoInput: AVCaptureDeviceInput?
    internal var videoOutput = AVCaptureMovieFileOutput()
    internal var videoRecordingTimeLimit: TimeInterval = 0
    internal var motionManager = CMMotionManager()
    
    // MARK: - Configuration
    
    func configure() { }
    
    // MARK: - Flash
    
    func tryToggleFlash() {
        guard let device = device else { return }
        guard device.hasFlash else { return }
        do {
            try device.lockForConfiguration()
            switch device.flashMode {
            case .auto:
                currentFlashMode = .on
                device.flashMode = .on
            case .on:
                currentFlashMode = .off
                device.flashMode = .off
            case .off:
                currentFlashMode = .auto
                device.flashMode = .auto
            @unknown default:
                fatalError()
            }
            device.unlockForConfiguration()
        } catch _ { }
    }
    
    // MARK: - Shoot
    
    func shoot(completion: @escaping (Data) -> Void) {
        DispatchQueue.global(qos: .default).async {
            self.setCurrentOrienation()
            if let connection = self.output.connection(with: .video) {
                self.imageOutput.captureStillImageAsynchronously(from: connection) { buffer, _ in
                    if let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer!) {
                        completion(data)
                    }
                }
            }
        }
    }
}

