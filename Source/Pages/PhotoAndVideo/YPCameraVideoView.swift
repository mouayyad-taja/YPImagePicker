//
//  YPCameraVideoView.swift
//  YPImagePicker
//
//  Created by Mouayyad Taja on 2/7/20.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import Foundation

import UIKit
import Stevia

class YPCameraVideoView: UIView, UIGestureRecognizerDelegate {
    
    let topContainerView = UIView()
    let topView = UIView()
    let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
    let previewViewContainer = UIView()
    
    let buttonsContainer = UIView()
    let shotButton = UIButton()
    let flipButton = UIButton()
    let galleryButton = UIButton()

    let flashButton = UIButton()
    let closeButton = UIButton()
    let timeElapsedLabel = UILabel()
    let progressBar = UIProgressView()
    
    
    let hintLabel = UILabel()
    
    convenience init(overlayView: UIView? = nil) {
        self.init(frame: .zero)
        
        if let overlayView = overlayView {
            // View Hierarchy
            sv(
                previewViewContainer,
                overlayView,
                hintLabel,
                progressBar,
                timeElapsedLabel,
                flipButton,
                buttonsContainer.sv(
                    shotButton
                )
            )
        } else {
            // View Hierarchy
            sv(
                topContainerView.sv(
                    topView.sv(
                        timeElapsedLabel,
                        flashButton,
                        closeButton
                    )
                ),
                hintLabel,
                previewViewContainer,
                progressBar,
                buttonsContainer.sv(
                    shotButton,
                    flipButton,
                    galleryButton
                )
            )
        }
        
        // Layout
        let isIphone4 = UIScreen.main.bounds.height == 480
        let sideMargin: CGFloat = isIphone4 ? 20 : 0
        let timeElapsedMargin :CGFloat = 5
        let hintLabelMargin :CGFloat = 16

        if YPConfig.onlySquareImagesFromCamera {
            layout(
                0,
                |-sideMargin-previewViewContainer-sideMargin-|,
                -2,
                |progressBar|,
                0,
                |buttonsContainer|,
                |hintLabel|,
                0
            )
            
            previewViewContainer.heightEqualsWidth()
        }
        else {
            layout(
                0,
                |topContainerView|,
                |progressBar|,
                -2,
                |-sideMargin-previewViewContainer-sideMargin-|,
                -2,
                |hintLabel|,
                0
            )
            
            
            topContainerView.fillHorizontally()
            topContainerView.Top == self.Top

            if #available(iOS 11.0, *) {
                topView.Top == topContainerView.safeAreaLayoutGuide.Top
            } else {
                topView.top(0)
            }
            topView.bottom(0)
            topView.fillHorizontally()
            (topView.Height >= 45).priority = UILayoutPriority(rawValue: 999)
            
            
            previewViewContainer.Top == topContainerView.Bottom
            previewViewContainer.Bottom == hintLabel.Top - hintLabelMargin
            previewViewContainer.fillHorizontally()


            
            buttonsContainer.fillHorizontally()
            buttonsContainer.height(75)
            buttonsContainer.Bottom == previewViewContainer.Bottom - 16
        }
        
        overlayView?.followEdges(previewViewContainer)
        
        flashButton.size(30)-(8)-|
        flashButton.centerVertically()


        |-(8)-closeButton.size(30)
        closeButton.centerVertically()

        
        
        
        
        timeElapsedLabel.top(timeElapsedMargin)
        timeElapsedLabel.centerHorizontally()
        timeElapsedLabel.bottom(timeElapsedMargin)
        timeElapsedLabel.setContentCompressionResistancePriority(.required, for: NSLayoutConstraint.Axis.vertical)
        
        
        if #available(iOS 11.0, *) {
            hintLabel.Bottom == safeAreaLayoutGuide.Bottom// hintLabelMargin
        } else {
            hintLabel.bottom(hintLabelMargin)
        }
        hintLabel.setContentCompressionResistancePriority(.required, for: NSLayoutConstraint.Axis.vertical)
        hintLabel.centerHorizontally()

        
        
        shotButton.centerVertically()
        shotButton.size(75).centerHorizontally()
        
        
        flipButton.centerVertically()
        flipButton.size(30)-(15+sideMargin)-|
        

        galleryButton.centerVertically()
        |-(15+sideMargin)-galleryButton.size(30)
        
                
        // Style
        previewViewContainer.style { (p) in
            p.layer.cornerRadius = 15
            p.clipsToBounds = true
            p.backgroundColor = .ypLabel
        }
        backgroundColor = YPConfig.colors.photoVideoScreenBackgroundColor

        timeElapsedLabel.style { l in
            l.textColor = .white
            l.text = "00:00"
            l.isHidden = true
            l.font = .monospacedDigitSystemFont(ofSize: 15, weight: .medium)
            l.numberOfLines = 2
        }
        progressBar.style { p in
            p.trackTintColor = .clear
            p.tintColor = YPConfig.colors.progressBarRecordingColor
            p.layer.cornerRadius = 15
            p.clipsToBounds = true
        }
        
        hintLabel.style { l in
            l.textColor = YPConfig.colors.hintTextColor
            l.backgroundColor = .clear
            l.text = YPConfig.wordings.cameraVideoHint
            l.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
            l.textAlignment = .center
        }
        topView.style { (tv) in
            tv.backgroundColor = .clear
        }
        
        flashButton.setImage(YPConfig.icons.flashOffIcon, for: .normal)
        flipButton.setImage(YPConfig.icons.loopIcon, for: .normal)
        shotButton.setImage(YPConfig.icons.capturePhotoImage, for: .normal)
        closeButton.setImage(YPConfig.icons.closeImage, for: .normal)
        galleryButton.setImage(YPConfig.icons.galleryImage, for: .normal)
        
        flashButton.imageView?.contentMode = .scaleAspectFit
        flipButton.imageView?.contentMode = .scaleAspectFit
        shotButton.imageView?.contentMode = .scaleAspectFit
        closeButton.imageView?.contentMode = .scaleAspectFit
        galleryButton.imageView?.contentMode = .scaleAspectFit
    }
    
    
    func hideVideo(){
        self.timeElapsedLabel.isHidden = true
        self.closeButton.isHidden = false
        self.flashButton.isHidden = false
    }
    
    func showVideo(){
        self.timeElapsedLabel.isHidden = false
        self.closeButton.isHidden = true
        self.flashButton.isHidden = true
    }
    
}
