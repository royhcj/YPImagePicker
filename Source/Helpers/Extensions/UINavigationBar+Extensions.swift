//
//  UINavigationBar+Extensions.swift
//  YPImagePicker
//
//  Created by Sebastiaan Seegers on 02/03/2020.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import UIKit
import Foundation

extension UINavigationBar {

    func setTitleAttributes(font: UIFont?, color: UIColor) {
        guard let font = font  else { return }
        self.titleTextAttributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor:color]
    }
}
