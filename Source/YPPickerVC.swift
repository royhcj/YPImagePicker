//
//  YYPPickerVC.swift
//  YPPickerVC
//
//  Created by Sacha Durand Saint Omer on 25/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import Foundation
import Stevia
import Photos

protocol ImagePickerDelegate: AnyObject {
    func noPhotos()
    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool
}

open class YPPickerVC: YPBottomPager, YPBottomPagerDelegate {
    
    let albumsManager = YPAlbumsManager()
    var shouldHideStatusBar = false
    var initialStatusBarHidden = false
    weak var imagePickerDelegate: ImagePickerDelegate?
    
    override open var prefersStatusBarHidden: Bool {
        return (shouldHideStatusBar || initialStatusBarHidden) && YPConfig.hidesStatusBar
    }
    
    /// Private callbacks to YPImagePicker
    public var didClose:(() -> Void)?
    public var didSelectItems: (([YPMediaItem]) -> Void)?
    
    enum Mode {
        case library
        case camera
        case video
    }
    
    private var libraryVC: YPLibraryVC?
    private var cameraVC: YPCameraVC?
    private var videoVC: YPVideoCaptureVC?
    
    var mode = Mode.camera
    
    var capturedImage: UIImage?
    
    var tempCapturePhoto: [UIImage] = []
    
    private var emptyAlert: UIAlertController?
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = YPConfig.colors.safeAreaBackgroundColor
        
        delegate = self
        
        // Force Library only when using `minNumberOfItems`.
        if YPConfig.library.minNumberOfItems > 1 {
            YPImagePickerConfiguration.shared.screens = [.library]
        }
        
        // Library
        if YPConfig.screens.contains(.library) {
            libraryVC = YPLibraryVC()
            libraryVC?.delegate = self
        }
        
        // Camera
        if YPConfig.screens.contains(.photo) {
            cameraVC = YPCameraVC()
            cameraVC?.didCapturePhoto = { [weak self] img in
                guard let self = self else { return }
                self.tempCapturePhoto.append(img)
                self.reloadCameraDoneEnabled()
                if self.tempCapturePhoto.count >= YPConfig.maxNumberOfCapture {
                    self.cameraDone()
                }
            }
            cameraVC?.hasNextCapture = { [weak self]  in
                guard let self = self else { return false }
                return self.tempCapturePhoto.count < YPConfig.maxNumberOfCapture
            }
        }
        
        // Video
        if YPConfig.screens.contains(.video) {
            videoVC = YPVideoCaptureVC()
            videoVC?.didCaptureVideo = { [weak self] videoURL in
                self?.didSelectItems?([YPMediaItem
                    .video(v: YPMediaVideo(thumbnail: thumbnailFromVideoPath(videoURL),
                                           videoURL: videoURL,
                                           fromCamera: true))])
            }
        }
        
        // Show screens
        var vcs = [UIViewController]()
        for screen in YPConfig.screens {
            switch screen {
            case .library:
                if let libraryVC = libraryVC {
                    vcs.append(libraryVC)
                }
            case .photo:
                if let cameraVC = cameraVC {
                    vcs.append(cameraVC)
                }
            case .video:
                if let videoVC = videoVC {
                    vcs.append(videoVC)
                }
            }
        }
        controllers = vcs
        
        // Select good mode
        if YPConfig.screens.contains(YPConfig.startOnScreen) {
            switch YPConfig.startOnScreen {
            case .library:
                mode = .library
            case .photo:
                mode = .camera
            case .video:
                mode = .video
            }
        }
        
        // Select good screen
        if let index = YPConfig.screens.firstIndex(of: YPConfig.startOnScreen) {
            startOnPage(index)
        }
        
        YPHelper.changeBackButtonIcon(self)
        YPHelper.changeBackButtonTitle(self)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraVC?.v.shotButton.isEnabled = true
        
        updateMode(with: currentController)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        shouldHideStatusBar = true
        initialStatusBarHidden = true
        UIView.animate(withDuration: 0.3) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    internal func pagerScrollViewDidScroll(_ scrollView: UIScrollView) { }
    
    func modeFor(vc: UIViewController) -> Mode {
        switch vc {
        case is YPLibraryVC:
            return .library
        case is YPCameraVC:
            return .camera
        case is YPVideoCaptureVC:
            return .video
        default:
            return .camera
        }
    }
    
    func pagerDidSelectController(_ vc: UIViewController) {
        if let vc = vc as? YPLibraryVC,
           vc.initialized,
           !vc.hasAvailablePhotos() {
            showEmptyAlert(true)
        }
        
        updateMode(with: vc)
    }
    
    func updateMode(with vc: UIViewController) {
        stopCurrentCamera()
        
        // Set new mode
        mode = modeFor(vc: vc)
        
        // Re-trigger permission check
        if let vc = vc as? YPLibraryVC {
            vc.checkPermission()
        } else if let cameraVC = vc as? YPCameraVC {
            cameraVC.start()
        } else if let videoVC = vc as? YPVideoCaptureVC {
            videoVC.start()
        }
    
        updateUI()
    }
    
    func stopCurrentCamera() {
        switch mode {
        case .library:
            libraryVC?.pausePlayer()
        case .camera:
            cameraVC?.stopCamera()
        case .video:
            videoVC?.stopCamera()
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shouldHideStatusBar = false
        stopAll()
    }
    
    @objc
    func navBarTapped() {
        let vc = YPAlbumVC(albumsManager: albumsManager, librarySelectionCount: libraryVC?.selection.count ?? 0)
        let navVC = UINavigationController(rootViewController: vc)
        navVC.navigationBar.tintColor = .ypLabel
        
        vc.didSelectAlbum = { [weak self] album in
            self?.libraryVC?.setAlbum(album)
            self?.setLibraryTitleView(title: album.title,subtitle: YPConfig.wordings.libarySubitle)
            navVC.dismiss(animated: true, completion: nil)
        }
        present(navVC, animated: true, completion: nil)
    }
    func setLibraryTitleView(title: String,subtitle: String?) {
//        let containerView = UIView()
//        containerView.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        
        
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.spacing = 3
//        containerView.addSubview(stackView)
//        stackView.fillContainer()
        
        let titleStackView = UIStackView()
        titleStackView.alignment = .center
        titleStackView.axis = .horizontal
        titleStackView.spacing = 5
        stackView.addArrangedSubview(titleStackView)
        
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = YPConfig.fonts.pickerTitleFont
        titleLabel.textColor = YPConfig.colors.navigationTintColor
        titleStackView.addArrangedSubview(titleLabel)
        
        if YPConfig.library.options == nil {
            let arrow = UIImageView()
            arrow.image = YPConfig.icons.arrowDownIcon
            arrow.image = arrow.image?.withRenderingMode(.alwaysTemplate)
            arrow.tintColor = YPConfig.colors.navigationTintColor
            
            let attributes = UINavigationBar.appearance().titleTextAttributes
            if let attributes = attributes, let foregroundColor = attributes[.foregroundColor] as? UIColor {
                arrow.image = arrow.image?.withRenderingMode(.alwaysTemplate)
                arrow.tintColor = foregroundColor
            }
            titleStackView.addArrangedSubview(arrow)
            
            stackView.isUserInteractionEnabled = true
            let tapImageGesture = UITapGestureRecognizer(target: self, action: #selector(navBarTapped))
            stackView.addGestureRecognizer(tapImageGesture)
        }
        if let subtitle = subtitle, YPConfig.maxNumberOfCapture > 0  {
            let promptLabel = UILabel()
            promptLabel.text = subtitle
            promptLabel.font = YPConfig.fonts.pickerSubTitleFont
            promptLabel.textColor = YPConfig.colors.navigationTintColor
            stackView.addArrangedSubview(promptLabel)
        }
        
        navigationItem.titleView = stackView
    }
    
    func setCameraTitleView(title: String,subtitle: String?) {
        guard let subtitle = subtitle, YPConfig.maxNumberOfCapture > 0 else {
            navigationItem.titleView = nil
            self.title = cameraVC?.title
            return
        }
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.spacing = 3
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = YPConfig.fonts.pickerTitleFont
        titleLabel.textColor = YPConfig.colors.navigationTintColor
        stackView.addArrangedSubview(titleLabel)
        
        let promptLabel = UILabel()
        promptLabel.text = subtitle
        promptLabel.font = YPConfig.fonts.pickerSubTitleFont
        promptLabel.textColor = YPConfig.colors.navigationTintColor
        stackView.addArrangedSubview(promptLabel)
        
   
        navigationItem.titleView = stackView
    }
    
    func updateUI() {
		if !YPConfig.hidesCancelButton {
			// Update Nav Bar state.
			navigationItem.leftBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.cancel,
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(close))
		}
        switch mode {
        case .library:
            navigationItem.titleView = nil
            setLibraryTitleView(title: libraryVC?.title ?? "", subtitle: YPConfig.wordings.libarySubitle)
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.next,
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(done))
            navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor

            // Disable Next Button until minNumberOfItems is reached.
            navigationItem.rightBarButtonItem?.isEnabled =
				libraryVC!.selection.count >= YPConfig.library.minNumberOfItems

        case .camera:
            setCameraTitleView(title: cameraVC?.title ?? "", subtitle: YPConfig.wordings.cameraSubitle)
           
            reloadCameraDoneEnabled()
        case .video:
            navigationItem.titleView = nil
            title = videoVC?.title
            navigationItem.rightBarButtonItem = nil
        }

        let textAttributes = [NSAttributedString.Key.foregroundColor:YPConfig.colors.navigationTintColor]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .normal)
        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .disabled)
        navigationItem.leftBarButtonItem?.setFont(font: YPConfig.fonts.leftBarButtonFont, forState: .normal)
    }
    
    func reloadCameraDoneEnabled() {
        if YPConfig.maxNumberOfCapture > 1, self.tempCapturePhoto.count > 0 {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.next,
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(cameraDone))
            navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
        } else {
            navigationItem.rightBarButtonItem = nil
        }
        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .normal)
        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .disabled)
        
        let title = YPConfig.wordings.cameraTitle + (self.tempCapturePhoto.count > 0 ? "(\(tempCapturePhoto.count))" : "")
        setCameraTitleView(title: title, subtitle: YPConfig.wordings.cameraSubitle)
    }
    
    @objc
    func close() {
        // Cancelling exporting of all videos
        if let libraryVC = libraryVC {
            libraryVC.mediaManager.forseCancelExporting()
        }
        self.didClose?()
    }
    
    // When pressing "Next"
    @objc
    func done() {
        guard let libraryVC = libraryVC else { print("⚠️ YPPickerVC >>> YPLibraryVC deallocated"); return }
        
        if mode == .library {
            libraryVC.doAfterPermissionCheck { [weak self] in
                libraryVC.selectedMedia(photoCallback: { photo in
                    self?.didSelectItems?([YPMediaItem.photo(p: photo)])
                }, videoCallback: { video in
                    self?.didSelectItems?([YPMediaItem
                        .video(v: video)])
                }, multipleItemsCallback: { items in
                    self?.didSelectItems?(items)
                })
            }
        }
        
    }
    @objc
    func cameraDone() {
        let didSelectItems = self.tempCapturePhoto.map { YPMediaItem.photo(p: YPMediaPhoto(image: $0, fromCamera: true)) }
        self.didSelectItems?(didSelectItems)
        self.tempCapturePhoto.removeAll()
    }
    
    func stopAll() {
        libraryVC?.v.assetZoomableView.videoView.deallocate()
        videoVC?.stopCamera()
        cameraVC?.stopCamera()
    }
}

extension YPPickerVC: YPLibraryViewDelegate {
    
    public func libraryViewDidTapNext() {
        libraryVC?.isProcessing = true
        DispatchQueue.main.async {
            self.v.scrollView.isScrollEnabled = false
            self.libraryVC?.v.fadeInLoader()
            self.navigationItem.rightBarButtonItem = YPLoaders.defaultLoader
        }
    }
    
    public func libraryViewStartedLoadingImage() {
		//TODO remove to enable changing selection while loading but needs cancelling previous image requests.
        libraryVC?.isProcessing = true
        DispatchQueue.main.async {
            self.libraryVC?.v.fadeInLoader()
        }
    }
    
    public func libraryViewFinishedLoading() {
        libraryVC?.isProcessing = false
        DispatchQueue.main.async {
            self.v.scrollView.isScrollEnabled = YPConfig.isScrollToChangeModesEnabled
            self.libraryVC?.v.hideLoader()
            self.updateUI()
        }
    }
    
    public func libraryViewDidToggleMultipleSelection(enabled: Bool) {
        var offset = v.header.frame.height
        if #available(iOS 11.0, *) {
            offset += v.safeAreaInsets.bottom
        }
        
        v.header.bottomConstraint?.constant = enabled ? offset : 0
        v.layoutIfNeeded()
        updateUI()
    }
    
    public func noPhotosForOptions() {
        showEmptyAlert(true)
    }
    
    public func libraryDidChange(isEmpty: Bool) {
        showEmptyAlert(isEmpty)
    }
    
    private func showEmptyAlert(_ showing: Bool) {
        if showing,
           emptyAlert == nil {
            let alert = UIAlertController(title: "無法開啟圖庫", message: "您的圖庫未發現照片，請確認後再啟用。", preferredStyle: .alert)
            alert.addAction(.init(title: "關閉", style: .cancel, handler: { _ in
                self.imagePickerDelegate?.noPhotos()
                self.showPage(1)
                self.emptyAlert = nil
            }))
            present(alert, animated: true)
            emptyAlert = alert
        } else {
            emptyAlert?.dismiss(animated: true, completion: nil)
            emptyAlert = nil
        }
    }
    
    public func libraryViewShouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool {
        return imagePickerDelegate?.shouldAddToSelection(indexPath: indexPath, numSelections: numSelections) ?? true
    }
}
