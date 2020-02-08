
//
//  YPPhotoEditingVC.swift
//  YPImagePicker
//
//  Created by Mouayyad Taja on 2/8/20.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import UIKit


class YPPhotoEditingVC: UIViewController , IsMediaFilterVC, UIGestureRecognizerDelegate {
    
    required public init(inputPhoto: YPMediaPhoto, isFromSelectionVC: Bool) {
        super.init(nibName: nil, bundle: nil)
        
        self.inputPhoto = inputPhoto
//        self.isFromSelectionVC = isFromSelectionVC
    }
    
    public var inputPhoto: YPMediaPhoto!
//    public var isFromSelectionVC = false

    public var didSave: ((YPMediaItem) -> Void)?
    public var didCancel: (() -> Void)?


    fileprivate let filters: [YPFilter] = YPConfig.filters

    fileprivate var selectedFilter: YPFilter?
    
    fileprivate var filteredThumbnailImagesArray: [UIImage] = []
    fileprivate var thumbnailImageForFiltering: CIImage? // Small image for creating filters thumbnails
    fileprivate var currentlySelectedImageThumbnail: UIImage? // Used for comparing with original image when tapped

    fileprivate var v = YPFiltersEditingView()

    override open var prefersStatusBarHidden: Bool { return YPConfig.hidesStatusBar }
    override open func loadView() { view = v }
    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Life Cycle ♻️

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup of main image an thumbnail images
        v.imageView.image = inputPhoto.image
        
        
        // Setup of Collection View
        v.collectionView.register(YPFilterCollectionViewCell.self, forCellWithReuseIdentifier: "FilterCell")
        v.collectionView.dataSource = self
        v.collectionView.delegate = self

        view.backgroundColor = YPConfig.colors.filterBackgroundColor
        
        //Setup buttons
        linkButtons()
        
        // Setup of Navigation Bar
//        title = YPConfig.wordings.filter
//        if isFromSelectionVC {
//            navigationItem.leftBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.cancel,
//                                                               style: .plain,
//                                                               target: self,
//                                                               action: #selector(cancel))
//        }
//        setupRightBarButton()
        
        YPHelper.changeBackButtonIcon(self)
        YPHelper.changeBackButtonTitle(self)
        self.showEffects()

    }
    
    // MARK: Setup - ⚙️
    private func linkButtons() {
       v.effectButton.addTarget(self, action: #selector(effectsButtonTapped), for: .touchUpInside)
       v.cropButton.addTarget(self, action: #selector(cropButtonTapped), for: .touchUpInside)
       v.textButton.addTarget(self, action: #selector(textButtonTapped), for: .touchUpInside)
        v.backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        v.nextButton.addTarget(self, action: #selector(save), for: .touchUpInside)

        
        // Touch preview to see original image.
        let touchDownGR = UILongPressGestureRecognizer(target: self,
                                                       action: #selector(handleTouchDown))
        touchDownGR.minimumPressDuration = 0
        touchDownGR.delegate = self
        v.imageView.addGestureRecognizer(touchDownGR)
        v.imageView.isUserInteractionEnabled = true
    }
//    fileprivate func setupRightBarButton() {
//        let rightBarButtonTitle = isFromSelectionVC ? YPConfig.wordings.done : YPConfig.wordings.next
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: rightBarButtonTitle,
//                                                            style: .done,
//                                                            target: self,
//                                                            action: #selector(save))
//        navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
//    }
    
    // MARK: - Methods 🏓

    @objc
    fileprivate func handleTouchDown(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            v.imageView.image = inputPhoto.originalImage
        case .ended:
            v.imageView.image = self.inputPhoto.image// ?? inputPhoto.originalImage
        default: ()
        }
    }
    
    fileprivate func thumbFromImage(_ img: UIImage) -> CIImage {
        let k = img.size.width / img.size.height
        let scale = UIScreen.main.scale
        let thumbnailHeight: CGFloat = 100 * scale
        let thumbnailWidth = thumbnailHeight * k
        let thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailHeight)
        UIGraphicsBeginImageContext(thumbnailSize)
        img.draw(in: CGRect(x: 0, y: 0, width: thumbnailSize.width, height: thumbnailSize.height))
        let smallImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return smallImage!.toCIImage()!
    }
    
    func showEffects(){
        if filteredThumbnailImagesArray.isEmpty {
            thumbnailImageForFiltering = thumbFromImage(inputPhoto.image)
            DispatchQueue.global().async {
                self.filteredThumbnailImagesArray = self.filters.map { filter -> UIImage in
                    if let applier = filter.applier,
                        let thumbnailImage = self.thumbnailImageForFiltering,
                        let outputImage = applier(thumbnailImage) {
                        return outputImage.toUIImage()
                    } else {
                        return self.inputPhoto.originalImage
                    }
                }
                DispatchQueue.main.async {
                    self.v.collectionView.reloadData()
                    self.v.collectionView.selectItem(at: IndexPath(row: 0, section: 0),
                                                animated: false,
                                                scrollPosition: UICollectionView.ScrollPosition.bottom)
                    self.v.filtersLoader.stopAnimating()
                }
            }
        }
    }
    
    func updateFilter(){
        if let f = self.selectedFilter,
            let applier = f.applier,
            let ciImage = self.inputPhoto.originalImage.toCIImage(),
            let modifiedFullSizeImage = applier(ciImage) {
            self.inputPhoto.modifiedImage = modifiedFullSizeImage.toUIImage()
        }else {
            self.inputPhoto.modifiedImage = nil
        }
        v.imageView.image = self.inputPhoto.image
    }
    // MARK: - Actions 🥂
    
    @objc
    func cancel() {
        didCancel?()
    }
    
    @objc
    func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc
    func effectsButtonTapped() {
        v.toggleEffectsCollection()
        if v.showCollection {
            self.showEffects()
        }
    }
    
    @objc
    func textButtonTapped() {
        //TODO
    }
    
    @objc
    func cropButtonTapped() {
        let nav = UINavigationController()
        nav.modalPresentationStyle = .fullScreen
        let cropVC = YPCropVC(image: inputPhoto.originalImage   , ratio: 1)
        cropVC.didFinishCropping = { croppedImage in
            self.inputPhoto.originalImage = croppedImage
//            self.v.imageView.image = self.inputPhoto.modifiedImage
//            photo.modifiedImage = croppedImage
//            completion(photo)
            self.updateFilter()
            nav.dismiss(animated: true, completion: nil)
        }
        cropVC.didCancel = {
            nav.dismiss(animated: true, completion: nil)
        }
        nav.viewControllers = [cropVC]
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc
    func save() {
        guard let didSave = didSave else { return print("Don't have saveCallback") }
        self.navigationItem.rightBarButtonItem = YPLoaders.defaultLoader

        DispatchQueue.global().async {
            if let f = self.selectedFilter,
                let applier = f.applier,
                let ciImage = self.inputPhoto.originalImage.toCIImage(),
                let modifiedFullSizeImage = applier(ciImage) {
                self.inputPhoto.modifiedImage = modifiedFullSizeImage.toUIImage()
            } else {
                self.inputPhoto.modifiedImage = nil
            }
            DispatchQueue.main.async {
                didSave(YPMediaItem.photo(p: self.inputPhoto))
//                self.setupRightBarButton()
            }
        }
    }
}

extension YPPhotoEditingVC: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredThumbnailImagesArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let filter = filters[indexPath.row]
        let image = filteredThumbnailImagesArray[indexPath.row]
        if let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: "FilterCell",
                                 for: indexPath) as? YPFilterCollectionViewCell {
            cell.name.text = filter.name
            cell.imageView.image = image
            return cell
        }
        return UICollectionViewCell()
    }
}

extension YPPhotoEditingVC: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedFilter = filters[indexPath.row]
//        currentlySelectedImageThumbnail = filteredThumbnailImagesArray[indexPath.row]
//        self.v.imageView.image = currentlySelectedImageThumbnail
        updateFilter()
    }
}
