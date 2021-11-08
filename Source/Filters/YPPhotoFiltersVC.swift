//
//  YPPhotoFiltersVC.swift
//  photoTaking
//
//  Created by Sacha Durand Saint Omer on 21/10/16.
//  Copyright © 2016 octopepper. All rights reserved.
//

import UIKit

protocol IsMediaFilterVC: class {
    var didSave: ((YPMediaItem) -> Void)? { get set }
    var didCancel: (() -> Void)? { get set }
}

open class YPPhotoFiltersVC: UIViewController, IsMediaFilterVC, UIGestureRecognizerDelegate {
    
    required public init(inputPhoto: YPMediaPhoto, isFromSelectionVC: Bool) {
        super.init(nibName: nil, bundle: nil)
        
        self.inputPhoto = inputPhoto
        self.isFromSelectionVC = isFromSelectionVC
    }
    
    public var inputPhoto: YPMediaPhoto!
    public var isFromSelectionVC = false

    public var didSave: ((YPMediaItem) -> Void)?
    public var didCancel: (() -> Void)?

    fileprivate let filters: [YPFilter] = YPConfig.filters

    fileprivate var selectedFilter: YPFilter?
    
    fileprivate var filteredThumbnailImagesArray: [UIImage] = []
    fileprivate var thumbnailImageForFiltering: CIImage? // Small image for creating filters thumbnails
    fileprivate var currentlySelectedImageThumbnail: UIImage? // Used for comparing with original image when tapped
    fileprivate var currentRotation: CGFloat = 0
    fileprivate var rotatedOriginalImage: UIImage = UIImage()

    fileprivate var v = YPFiltersView()

    override open var prefersStatusBarHidden: Bool { return YPConfig.hidesStatusBar }
    override open func loadView() { view = v }
    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Life Cycle ♻️

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // Re-select original filter
        if let filterName = inputPhoto.appliedFilterName,
           let index = self.filters.firstIndex(where: { $0.name == filterName }) {
            selectedFilter = filters[index]
        }
        
        // Restore Rotation
        currentRotation = inputPhoto.appliedRotation ?? 0
        
        // Setup of main image an thumbnail images
        v.imageView.image = inputPhoto.image
        rotatedOriginalImage = inputPhoto.rotatedOriginalImage
        setThumnailImageForFiltering(rotatedOriginalImage)
        
        // Setup of Collection View
        v.collectionView.register(YPFilterCollectionViewCell.self, forCellWithReuseIdentifier: "FilterCell")
        v.collectionView.dataSource = self
        v.collectionView.delegate = self

        view.backgroundColor = YPConfig.colors.filterBackgroundColor
        
        // Setup of Navigation Bar
        title = YPConfig.wordings.filter
        navigationController?.navigationBar.barTintColor = YPConfig.colors.navigationBarTintColor
        navigationController?.navigationBar.tintColor = YPConfig.colors.navigationTintColor
        navigationController?.navigationBar.setTitleAttributes(font: YPConfig.fonts.navigationBarTitleFont, color: YPConfig.colors.navigationTintColor)
        if isFromSelectionVC {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.cancel,
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(cancel))
            navigationItem.leftBarButtonItem?.setFont(font: YPConfig.fonts.leftBarButtonFont, forState: .normal)
        }
        setupRightBarButton()
        
        YPHelper.changeBackButtonIcon(self)
        YPHelper.changeBackButtonTitle(self)
        
        // Touch preview to see original image.
        let touchDownGR = UILongPressGestureRecognizer(target: self,
                                                       action: #selector(handleTouchDown))
        touchDownGR.minimumPressDuration = 0
        touchDownGR.delegate = self
        v.imageView.addGestureRecognizer(touchDownGR)
        v.imageView.isUserInteractionEnabled = true
        
        v.rotateButton?.addTarget(self, action: #selector(onRotationButtonClicked(sender:)), for: .touchUpInside)
    }
    
    private func setThumnailImageForFiltering(_ image: UIImage) {
        thumbnailImageForFiltering = thumbFromImage(image)
        DispatchQueue.global().async {
            self.filteredThumbnailImagesArray = self.filters.map { filter -> UIImage in
                if let applier = filter.applier,
                    let thumbnailImage = self.thumbnailImageForFiltering,
                    let outputImage = applier(thumbnailImage) {
                    return outputImage.toUIImage()
                } else {
                    return image
                }
            }
            DispatchQueue.main.async {
                let selected: IndexPath = {
                    if let filterName = self.selectedFilter?.name,
                       let index = self.filters.firstIndex(where: { $0.name == filterName }) {
                        return IndexPath(row: index, section: 0)
                    } else {
                        return self.v.collectionView.indexPathsForSelectedItems?.first
                            ?? IndexPath(row: 0, section: 0)
                    }
                }()
                self.v.collectionView.reloadData()
                self.v.collectionView.selectItem(at: selected,
                                            animated: false,
                                            scrollPosition: UICollectionView.ScrollPosition.bottom)
                self.v.filtersLoader.stopAnimating()
                
                if self.currentlySelectedImageThumbnail == nil {
                    self.currentlySelectedImageThumbnail = self.filteredThumbnailImagesArray[selected.row]
                }
            }
        }
    }
    
    // MARK: Setup - ⚙️
    
    fileprivate func setupRightBarButton() {
        let rightBarButtonTitle = YPConfig.wordings.done
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: rightBarButtonTitle,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(save))
        navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .normal)
        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .disabled)
    }
    
    // MARK: - Methods 🏓

    @objc
    fileprivate func handleTouchDown(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            v.imageView.image = rotatedOriginalImage
        case .ended:
            v.imageView.image = currentlySelectedImageThumbnail ?? inputPhoto.rotatedOriginalImage
        default: ()
        }
    }
    
    @objc
    fileprivate func onRotationButtonClicked(sender: Any) {
        currentRotation += -CGFloat.pi / 2
//        var image = inputPhoto.originalImage.rotated(by: currentRotation)
        var image = rotatedOriginalImage.rotated(by: -CGFloat.pi / 2)
        rotatedOriginalImage = image
        setThumnailImageForFiltering(image)
        
        currentlySelectedImageThumbnail = currentlySelectedImageThumbnail?.rotated(by: -CGFloat.pi / 2)
        v.imageView.image = currentlySelectedImageThumbnail ?? image
    }
    
    fileprivate func thumbFromImage(_ img: UIImage) -> CIImage {
        let k = img.size.width / img.size.height
        let scale = UIScreen.main.scale
        let thumbnailHeight: CGFloat = 300 * scale
        let thumbnailWidth = thumbnailHeight * k
        let thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailHeight)
        UIGraphicsBeginImageContext(thumbnailSize)
        img.draw(in: CGRect(x: 0, y: 0, width: thumbnailSize.width, height: thumbnailSize.height))
        let smallImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return smallImage!.toCIImage()!
    }
    
    // MARK: - Actions 🥂

    @objc
    func cancel() {
        didCancel?()
    }
    
    @objc
    func save() {
        guard let didSave = didSave else { return print("Don't have saveCallback") }
        self.navigationItem.rightBarButtonItem = YPLoaders.defaultLoader

        DispatchQueue.global().async {
            let image = self.rotatedOriginalImage//self.inputPhoto.rotatedOriginalImage//.rotated(by: self.currentRotation)
            if let f = self.selectedFilter,
                let applier = f.applier,
                let ciImage = image.toCIImage(),
                let modifiedFullSizeImage = applier(ciImage) {
                self.inputPhoto.modifiedImage = modifiedFullSizeImage.toUIImage()
                self.inputPhoto.appliedFilterName = f.name
                self.inputPhoto.appliedRotation = self.currentRotation == 0 ? nil : self.currentRotation
            } else {
                //self.inputPhoto.modifiedImage = nil
            }
            DispatchQueue.main.async {
                didSave(YPMediaItem.photo(p: self.inputPhoto))
                self.setupRightBarButton()
            }
        }
    }
}

extension YPPhotoFiltersVC: UICollectionViewDataSource {
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

extension YPPhotoFiltersVC: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedFilter = filters[indexPath.row]
        currentlySelectedImageThumbnail = filteredThumbnailImagesArray[indexPath.row]
        self.v.imageView.image = currentlySelectedImageThumbnail
    }
}
