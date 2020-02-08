//
//  YPFiltersEditingView.swift
//  YPImagePicker
//
//  Created by Mouayyad Taja on 2/8/20.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import Stevia

class YPFiltersEditingView: UIView {
    
    let actionsStackView = UIStackView()
    let backButton = UIButton()
    let effectButton = UIButton()
    let textButton = UIButton()
    let cropButton = UIButton()
    
    let bottomContainerView = UIView()
    let nextButton = UIButton()

    let imageView = UIImageView()
    var collectionView: UICollectionView!
    var filtersLoader: UIActivityIndicatorView!

    fileprivate let collectionViewContainer: UIView = UIView()
    
    convenience init() {
        self.init(frame: CGRect.zero)
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout())
        filtersLoader = UIActivityIndicatorView(style: .gray)
        filtersLoader.hidesWhenStopped = true
        filtersLoader.startAnimating()
        filtersLoader.color = YPConfig.colors.tintColor
        
        sv(
            imageView,
            backButton,
            actionsStackView,
            collectionViewContainer.sv(
                filtersLoader,
                collectionView
            ),
            bottomContainerView.sv(
                nextButton
            )
        )
        
        let isIphone4 = UIScreen.main.bounds.height == 480
        let sideMargin: CGFloat = isIphone4 ? 20 : 0
        let actionSideMargin: CGFloat = 8
        
        if #available(iOS 11.0, *) {
            actionsStackView.Top == safeAreaLayoutGuide.Top
            bottomContainerView.Bottom == safeAreaLayoutGuide.Bottom
        } else {
            actionsStackView.top(0)
            bottomContainerView.bottom(0)
        }
        imageView.Top == actionsStackView.Top
        imageView.Bottom == bottomContainerView.Top

        actionsStackView-actionSideMargin-|
        actionsStackView.height(30)
        actionsStackView.addArrangedSubview(cropButton)
        actionsStackView.addArrangedSubview(effectButton)
        actionsStackView.addArrangedSubview(textButton)
        
        effectButton.heightEqualsWidth()
        
        
        
        backButton.Top == actionsStackView.Top
        |-actionSideMargin-backButton
        backButton.height(30)
        backButton.heightEqualsWidth()
        
        |-sideMargin-imageView-sideMargin-|
        |-sideMargin-collectionViewContainer-sideMargin-|
        
        
        |bottomContainerView|
        bottomContainerView.height(50)

        nextButton-32-|
        nextButton.centerVertically()
        nextButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)

        collectionViewContainer.height(100)
        |collectionView|
        collectionView.Height == collectionViewContainer.Height - 1
        collectionView.bottom(0)
        
        
        filtersLoader.CenterY == collectionView.CenterY
        filtersLoader.centerHorizontally()
        
        collectionViewContainer.Bottom == imageView.Bottom//  bottomMargin
        self.toggleEffectsCollection(show: false, animated: false)
        
        
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionViewContainer.clipsToBounds = true
        
        
        actionsStackView.style { (aSV) in
            aSV.axis = .horizontal
            aSV.distribution = .fillEqually
            aSV.spacing = 8
        }
        
        nextButton.style { (b) in
            
            b.setTitle(YPConfig.wordings.next, for: .normal)
            b.backgroundColor = .offWhiteOrBlack
            b.setTitleColor(.darkGray, for: .normal)
            b.layer.cornerRadius = b.frame.height / 2.0
        }
        
        backButton.setImage(YPConfig.icons.filterBackButtonIcon, for: .normal)
        effectButton.setImage(YPConfig.icons.effectsImage, for: .normal)
        textButton.setImage(YPConfig.icons.textImage, for: .normal)
        cropButton.setImage(YPConfig.icons.cropImage, for: .normal)
        
        backButton.imageView?.contentMode = .scaleAspectFit
        effectButton.imageView?.contentMode = .scaleAspectFit
        textButton.imageView?.contentMode = .scaleAspectFit
        cropButton.imageView?.contentMode = .scaleAspectFit
        
    }
    var showCollection = true
    func toggleEffectsCollection(show:Bool? = nil, animated: Bool = true){
        let showCollection :Bool = (show != nil ) ? show! : !self.showCollection
        let height = collectionViewContainer.heightConstraint?.constant ?? 0
        self.collectionViewContainer.isHidden = false
        if let bottom = collectionView.bottomConstraint{
            let animate = {
                bottom.constant = showCollection ? 0 : height
                self.layoutIfNeeded()
            }
            let completion = {
                self.collectionViewContainer.isHidden = !showCollection
                self.showCollection = showCollection
            }
            
            if animated {
                UIView.animate(withDuration: 0.5, animations: {
                    animate()
                }){_ in completion()  }
            }else {
                animate()
                completion()
            }
            
        }
    }
    func layout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        layout.itemSize = CGSize(width: 75, height: 100)
        return layout
    }
}
