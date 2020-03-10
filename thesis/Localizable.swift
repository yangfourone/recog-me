//
//  Localizable.swift
//  thesis
//
//  Created by yangfourone on 2020/3/10.
//  Copyright © 2020 41. All rights reserved.
//

import UIKit

extension String {
    var localized : String {
        return NSLocalizedString(self, comment: "")
    }
    
}

protocol  Localizable {
    var localizedKey: String? {
        get set
    }
}

extension UILabel : Localizable {
    
    @IBInspectable var localizedKey: String? {
        get { return nil }
        set(key) {
            self.text = key?.localized
        }
    }
}

extension UIButton : Localizable {
    
    @IBInspectable var localizedKey: String? {
        get { return nil }
        set(key) {
             self.setTitle(key?.localized, for:.normal)
        }
    }
}

extension UITextField : Localizable {
    
    @IBInspectable var localizedKey: String? {
        get { return nil }
        set(key) {
             self.placeholder = key?.localized
        }
    }
}
