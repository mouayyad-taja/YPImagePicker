//
//  YPCameraVideoHelper.swift
//  YPImagePicker
//
//  Created by Mouayyad Taja on 2/5/20.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import CoreMotion


protocol YPPhotoVideoCapture: class {
    
    // Public api
    func start(with previewView: UIView, withVideoRecordingLimit: TimeInterval, completion: @escaping () -> Void)
    func stopCamera()
    func focus(on point: CGPoint)
    func zoom(began: Bool, scale: CGFloat)
    func tryToggleFlash()
    var hasFlash: Bool { get }
    var currentFlashMode: YPFlashMode { get }
    func flipCamera(completion: @escaping () -> Void)
    func shoot(completion: @escaping (Data) -> Void)
    var videoLayer: AVCaptureVideoPreviewLayer! { get set }
    var device: AVCaptureDevice? { get }
    
    
    // Used by Default extension
    var previewView: UIView! { get set }
    var isCaptureSessionSetup: Bool { get set }
    var isPreviewSetup: Bool { get set }
    var sessionQueue: DispatchQueue { get }
    var session: AVCaptureSession { get }
    var output: AVCaptureOutput { get }
    var deviceInput: AVCaptureDeviceInput? { get set }
    var initVideoZoomFactor: CGFloat { get set }
    func configure()
    
    var currentCameraMode: CameraMode! { get set }
    var cameraMode: CameraMode{ get }
    
    var currentCameraPosition: AVCaptureDevice.Position { get }
    
    
    //video attribute
    var isRecording: Bool  { get }//{ return videoOutput.isRecording }
    var didCaptureVideo: ((URL) -> Void)? { get set }
    var videoRecordingProgress: ((Float, TimeInterval) -> Void)? { get set }

    var timer : Timer { get set }
    var dateVideoStarted :Date { get set }
//    var videoInput: AVCaptureDeviceInput? { get set }
    var videoOutput : AVCaptureMovieFileOutput { get set }
    var videoRecordingTimeLimit: TimeInterval { get set }
    var motionManager : CMMotionManager { get set }

}
extension YPPhotoVideoCapture {
    
    
    public var currentCameraPosition: AVCaptureDevice.Position {
        if let deviceInput = self.deviceInput {
            return deviceInput.device.position
        }
        return .unspecified
    }
}
func newPhotoVideoCapture() -> YPPhotoVideoCapture {
    if #available(iOS 10.0, *) {
        return PostiOS10PhotoVideoCapture()
    } else {
        return PreiOS10PhotoVideoCapture()
    }
}

enum CameraMode {
   case camera
   case video
   
   var isCamera: Bool {
       return self == .camera
   }
   var isVideo: Bool {
       return self == .video
   }
}
