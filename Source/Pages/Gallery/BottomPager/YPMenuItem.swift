//
//  YPMenuItem.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 24/01/2018.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import Stevia

final class YPMenuItem: UIView {
    
    var textLabel = UILabel()
    var button = UIButton()
    var indicatorView = UIView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    func setup() {
        backgroundColor = YPImagePickerConfiguration.shared.colors.bottomMenuItemBackgroundColor
        
        sv(
            textLabel,
            button,
            indicatorView
        )
        
        textLabel.centerInContainer()
        
        button.fillContainer()
        
        textLabel.style { l in
            l.textAlignment = .center
            l.font = YPConfig.fonts.menuItemFont
            l.textColor = YPImagePickerConfiguration.shared.colors.bottomMenuItemUnselectedTextColor
            l.adjustsFontSizeToFitWidth = true
            l.numberOfLines = 2
        }
        indicatorView.style { bottomView in
            bottomView.backgroundColor = YPImagePickerConfiguration.shared.colors.bottomMenuItemIndicatorColor
            bottomView.layer.cornerRadius = 1.5
        }
        
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: indicatorView, attribute: .top, relatedBy: .equal, toItem: textLabel, attribute: .bottom, multiplier: 1.0, constant: 1).isActive = true
        NSLayoutConstraint(item: indicatorView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 3).isActive = true
        NSLayoutConstraint(item: indicatorView, attribute: .leading, relatedBy: .equal, toItem: textLabel, attribute: .leading, multiplier: 1.0, constant: 4).isActive = true
        NSLayoutConstraint(item: indicatorView, attribute: .trailing, relatedBy: .equal, toItem: textLabel, attribute: .trailing, multiplier: 1.0, constant: -4).isActive = true
    }

    func select() {
        textLabel.textColor = YPImagePickerConfiguration.shared.colors.bottomMenuItemSelectedTextColor
        indicatorView.isHidden = false
    }
    
    func deselect() {
        textLabel.textColor = YPImagePickerConfiguration.shared.colors.bottomMenuItemUnselectedTextColor
        indicatorView.isHidden = true
    }
}
