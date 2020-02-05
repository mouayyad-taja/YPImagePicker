//
//  YPCameraVideoVC.swift
//  YPImagePicker
//
//  Created by Mouayyad Taja on 2/4/20.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import UIKit

class YPCameraVideoVC: UIViewController, UIGestureRecognizerDelegate, YPPermissionCheckable {
    
    public var didCapturePhoto: ((UIImage) -> Void)?
    
    //public attriutes
    var isInited = false
    let v: YPCameraView!
    
    //camera attributes
    let photoCapture = newPhotoVideoCapture()
    var videoZoomFactor: CGFloat = 1.0
    
    
    //video attributes
    public var didCaptureVideo: ((URL) -> Void)?
    //    private let videoHelper = YPVideoCaptureHelper()
    //        private let v = YPCameraView(overlayView: nil)
    private var viewState = ViewState()
    
    
    override public func loadView() { view = v }
    
    
    // MARK: - Init
    
    public required init() {
        self.v = YPCameraView(overlayView: nil)//YPCameraView(overlayView: YPConfig.overlayView)
        super.init(nibName: nil, bundle: nil)
        //        title = YPConfig.wordings.videoTitle
        //        title = YPConfig.wordings.cameraTitle
        
        //init video
        photoCapture.didCaptureVideo = { [weak self] videoURL in
            self?.didCaptureVideo?(videoURL)
            self?.resetVisualState()
        }
        photoCapture.videoRecordingProgress = { [weak self] progress, timeElapsed in
            self?.updateState {
                $0.progress = progress
                $0.timeElapsed = timeElapsed
            }
        }
        
        //init camera
        YPDeviceOrientationHelper.shared.startDeviceOrientationNotifier { _ in }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        YPDeviceOrientationHelper.shared.stopDeviceOrientationNotifier()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        v.timeElapsedLabel.isHidden = true // hide the time elapsed label since we're in the camera screen.
        
        v.flashButton.isHidden = true
        
        setupButtons()
        linkButtons()
        
        
    }
    
    func start() {
        v.shotButton.isEnabled = false
        
        doAfterPermissionCheck { [weak self] in
            guard let strongSelf = self else {
                return
            }
            self?.photoCapture.start(with: strongSelf.v.previewViewContainer, withVideoRecordingLimit: YPConfig.video.recordingTimeLimit, completion: {
                DispatchQueue.main.async {
                    strongSelf.v.shotButton.isEnabled = true
                    strongSelf.isInited = true
                    strongSelf.refreshFlashButton()
                }
            })
        }
    }
    
    func refresh(){
        if isInited {
            self.photoCapture.refresh()
            self.setupButtons()
            self.linkButtons()
            self.v.shotButton.isEnabled = true
            self.refreshFlashButton()
            v.timeElapsedLabel.isHidden = self.photoCapture.cameraMode.isCamera // hide the time elapsed label since we're in the camera screen.
        }
    }
    
    
    
    // MARK: - Setup
    
    private func setupButtons() {
        v.flashButton.setImage(YPConfig.icons.flashOffIcon, for: .normal)
        v.flipButton.setImage(YPConfig.icons.loopIcon, for: .normal)
        if self.photoCapture.cameraMode.isCamera {
            v.shotButton.setImage(YPConfig.icons.capturePhotoImage, for: .normal)
        }else {
            v.shotButton.setImage(YPConfig.icons.captureVideoImage, for: .normal)
        }
        
    }
    
    private func linkButtons() {
        v.flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchUpInside)
        v.shotButton.addTarget(self, action: #selector(shotButtonTapped), for: .touchUpInside)
        v.flipButton.addTarget(self, action: #selector(flipButtonTapped), for: .touchUpInside)
        
        let longPressGesture = UILongPressGestureRecognizer.init(target: self, action: #selector(handleLongPress))
        v.shotButton.addGestureRecognizer(longPressGesture);
        
        
        // Focus
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.focusTapped(_:)))
        tapRecognizer.delegate = self
        v.previewViewContainer.addGestureRecognizer(tapRecognizer)
        
        // Zoom
        let pinchRecongizer = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(_:)))
        pinchRecongizer.delegate = self
        v.previewViewContainer.addGestureRecognizer(pinchRecongizer)
    }
    
    
    // MARK: - Focus
    
    @objc
    func focusTapped(_ recognizer: UITapGestureRecognizer) {
        guard isInited else {
            return
        }
        doAfterPermissionCheck { [weak self] in
            self?.focus(recognizer: recognizer)
        }
    }
    
    
    func focus(recognizer: UITapGestureRecognizer) {
        
        let point = recognizer.location(in: v.previewViewContainer)
        
        // Focus the capture
        let viewsize = v.previewViewContainer.bounds.size
        let newPoint = CGPoint(x: point.x/viewsize.width, y: point.y/viewsize.height)
        
        //        if self.cameraMode.isCamera {
        photoCapture.focus(on: newPoint)
        //        }
        
        //TODO Done
        //        if self.cameraMode.isVideo {
        //            videoHelper.focus(onPoint: newPoint)
        //        }
        
        // Animate focus view
        v.focusView.center = point
        YPHelper.configureFocusView(v.focusView)
        v.addSubview(v.focusView)
        YPHelper.animateFocusView(v.focusView)
    }
    
    
    // MARK: - Zoom
    
    @objc
    func pinch(_ recognizer: UIPinchGestureRecognizer) {
        guard isInited else {
            return
        }
        
        doAfterPermissionCheck { [weak self] in
            self?.zoom(recognizer: recognizer)
        }
    }
    
    func zoom(recognizer: UIPinchGestureRecognizer) {
        //        if self.cameraMode.isCamera {
        photoCapture.zoom(began: recognizer.state == .began, scale: recognizer.scale)
        //        }
        
        //TODO Done
        //        if self.cameraMode.isVideo {
        //            videoHelper.zoom(began: recognizer.state == .began, scale: recognizer.scale)
        //        }
    }
    
    // MARK: - Flip Camera
    
    @objc
    func flipButtonTapped() {
        doAfterPermissionCheck { [weak self] in
            self?.flip()
        }
    }
    
    @objc
    private func flip() {
        
        self.photoCapture.flipCamera {
            self.refreshFlashButton()
        }
        
        //TODO Done
        //        videoHelper.flipCamera {
        
        //            self.refreshFlashButton()
        //            self.updateState {
        //                $0.flashMode = self.flashModeFrom(videoHelper: self.videoHelper)
        //            }
        //        }
    }
    
    //    @objc
    //    func shotButtonTapped() {
    //        doAfterPermissionCheck { [weak self] in
    //            self?.shoot()
    //        }
    //    }
    
    func shoot() {
        // Prevent from tapping multiple times in a row
        // causing a crash
        v.shotButton.isEnabled = false
        
        photoCapture.shoot { imageData in
            
            guard let shotImage = UIImage(data: imageData) else {
                return
            }
            
            self.photoCapture.stopCamera()
            
            var image = shotImage
            // Crop the image if the output needs to be square.
            if YPConfig.onlySquareImagesFromCamera {
                image = self.cropImageToSquare(image)
            }
            
            // Flip image if taken form the front camera.
            if let device = self.photoCapture.device, device.position == .front {
                image = self.flipImage(image: image)
            }
            
            DispatchQueue.main.async {
                let noOrietationImage = image.resetOrientation()
                self.didCapturePhoto?(noOrietationImage.resizedImageIfNeeded())
            }
        }
    }
    
    func cropImageToSquare(_ image: UIImage) -> UIImage {
        let orientation: UIDeviceOrientation = YPDeviceOrientationHelper.shared.currentDeviceOrientation
        var imageWidth = image.size.width
        var imageHeight = image.size.height
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            // Swap width and height if orientation is landscape
            imageWidth = image.size.height
            imageHeight = image.size.width
        default:
            break
        }
        
        // The center coordinate along Y axis
        let rcy = imageHeight * 0.5
        let rect = CGRect(x: rcy - imageWidth * 0.5, y: 0, width: imageWidth, height: imageWidth)
        let imageRef = image.cgImage?.cropping(to: rect)
        return UIImage(cgImage: imageRef!, scale: 1.0, orientation: image.imageOrientation)
    }
    
    // Used when image is taken from the front camera.
    func flipImage(image: UIImage!) -> UIImage! {
        let imageSize: CGSize = image.size
        UIGraphicsBeginImageContextWithOptions(imageSize, true, 1.0)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.rotate(by: CGFloat(Double.pi/2.0))
        ctx.translateBy(x: 0, y: -imageSize.width)
        ctx.scaleBy(x: imageSize.height/imageSize.width, y: imageSize.width/imageSize.height)
        ctx.draw(image.cgImage!, in: CGRect(x: 0.0,
                                            y: 0.0,
                                            width: imageSize.width,
                                            height: imageSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    @objc
    func flashButtonTapped() {
        photoCapture.tryToggleFlash()
        refreshFlashButton()
        
        //TODO Done
        //videoHelper.toggleTorch()
        //        updateState {
        //            $0.flashMode = self.flashModeFrom(videoHelper: self.videoHelper)
        //        }
    }
    
    func refreshFlashButton() {
        let flashImage = photoCapture.currentFlashMode.flashImage()
        v.flashButton.setImage(flashImage, for: .normal)
        v.flashButton.isHidden = !photoCapture.hasFlash
    }
    
    
    
    // MARK: - Shoot Tapped
    @objc
    func shotButtonTapped() {
        doAfterPermissionCheck { [weak self] in
            self?.shoot()
            //TODO Done
            //self?.toggleRecording()
        }
    }
    
    // MARK: - Toggle Recording
    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            debugPrint("long press started")
            self.startVideo()
        }
        else if gestureRecognizer.state == UIGestureRecognizer.State.ended {
            debugPrint("longpress ended")
            self.endVideo()
        }
    }
    
    private func toggleRecording() {
        photoCapture.isRecording ? stopRecording() : startRecording()
    }
    
    private func startRecording() {
        photoCapture.startRecording()
        updateState {
            $0.isRecording = true
            $0.flashMode = self.flashModeFrom(videoHelper: self.photoCapture)
        }
    }
    
    private func stopRecording() {
        photoCapture.stopRecording()
        updateState {
            $0.isRecording = false
        }
    }
    
    public func stopCamera() {
        //        if self.photoCapture.isCamera {
        photoCapture.stopCamera()
        //        }
        
        //        //TODO Done
        //        if self.cameraMode.isVideo {
        //            videoHelper.stopCamera()
        //        }
    }
    
    
    
    // MARK: - Camera State
    
    func startVideo(){
        //        guard self.viewState.canUseVideo else {
        //            return
        //        }
        v.timeElapsedLabel.isHidden = false // show the time elapsed label since we're in the video screen.
        self.refreshState()
        toggleRecording()
    }
    
    func endVideo(){
        guard self.viewState.isRecording else {
            return
        }
        v.shotButton.isEnabled = false
        toggleRecording()
    }
    
    
    func refreshState() {
        // Init view state with video helper's state
        updateState {
            $0.isRecording = self.photoCapture.isRecording
            $0.flashMode = self.flashModeFrom(videoHelper: self.photoCapture)
        }
    }
    // MARK: - UI State
    
    enum FlashMode {
        case noFlash
        case off
        case on
        case auto
    }
    
    struct ViewState {
        var canUseVideo = false
        var isRecording = false
        var flashMode = FlashMode.noFlash
        var progress: Float = 0
        var timeElapsed: TimeInterval = 0
    }
    
    private func updateState(block:(inout ViewState) -> Void) {
        block(&viewState)
        updateUIWith(state: viewState)
    }
    
    private func updateUIWith(state: ViewState) {
        func flashImage(for torchMode: FlashMode) -> UIImage {
            switch torchMode {
            case .noFlash: return UIImage()
            case .on: return YPConfig.icons.flashOnIcon
            case .off: return YPConfig.icons.flashOffIcon
            case .auto: return YPConfig.icons.flashAutoIcon
            }
        }
        v.flashButton.setImage(flashImage(for: state.flashMode), for: .normal)
        v.flashButton.isEnabled = !state.isRecording
        v.flashButton.isHidden = state.flashMode == .noFlash
        v.shotButton.setImage(state.isRecording ? YPConfig.icons.captureVideoOnImage : YPConfig.icons.captureVideoImage,
                              for: .normal)
        v.flipButton.isEnabled = !state.isRecording
        v.progressBar.progress = state.progress
        v.timeElapsedLabel.text = YPHelper.formattedStrigFrom(state.timeElapsed)
        
        // Animate progress bar changes.
        UIView.animate(withDuration: 1, animations: v.progressBar.layoutIfNeeded)
    }
    
    private func resetVisualState() {
        updateState {
            $0.isRecording = self.photoCapture.isRecording
            $0.flashMode = self.flashModeFrom(videoHelper: self.photoCapture)
            $0.progress = 0
            $0.timeElapsed = 0
        }
    }
    
    private func flashModeFrom(videoHelper: YPPhotoVideoCapture) -> FlashMode {
        if videoHelper.hasTorch() {
            switch videoHelper.currentTorchMode() {
            case .off: return .off
            case .on: return .on
            case .auto: return .auto
            @unknown default:
                fatalError()
            }
        } else {
            return .noFlash
        }
    }
}
