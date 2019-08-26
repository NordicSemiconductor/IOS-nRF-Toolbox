//
//  UIColor+Nordic.swift
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 07/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

extension UIColor {
    
    static let nordicBlue: UIColor = {
        if #available(iOS 11.0, *) {
            return UIColor(named: "NordicBlue")!
        } else {
            return #colorLiteral(red: 0, green: 0.7181802392, blue: 0.8448022008, alpha: 1)
        }
        }()!
    
    static let nordicLake: UIColor = {
        if #available(iOS 11.0, *) {
            return UIColor(named: "NordicLake")!
        } else {
            return #colorLiteral(red: 0, green: 0.5483048558, blue: 0.8252354264, alpha: 1)
        }
        }()!
    
    static let nordicRed: UIColor = {
        if #available(iOS 11.0, *) {
            return UIColor(named: "NordicRed")!
        } else {
            return #colorLiteral(red: 0.9567440152, green: 0.2853084803, blue: 0.3770255744, alpha: 1)
        }
        }()!
    
    static let nordicFall: UIColor = {
        if #available(iOS 11.0, *) {
            return UIColor(named: "NordicFall")!
        } else {
            return #colorLiteral(red: 0.9759542346, green: 0.5849055648, blue: 0.2069504261, alpha: 1)
        }
    }()
    
    static let nordicRedDark: UIColor = {
        if #available(iOS 11.0, *) {
            return UIColor(named: "NordicRedDark")!
        } else {
            return #colorLiteral(red: 0.8138422955, green: 0.24269408, blue: 0.3188471754, alpha: 1)
        }
    }()
    
    static let nordicDarkGray: UIColor = {
        if #available(iOS 11.0, *) {
            return UIColor(named: "NordicDarkGray")!
        } else {
            return #colorLiteral(red: 0.2590435743, green: 0.3151275516, blue: 0.353839159, alpha: 1)
        }
    }()
    
    static let nordicMediumGray: UIColor = {
        if #available(iOS 11.0, *) {
            return UIColor(named: "NordicMediumGray")!
        } else {
            return #colorLiteral(red: 0.5353743434, green: 0.5965531468, blue: 0.6396299005, alpha: 1)
        }
    }()
    
    static let nordicLightGray: UIColor = {
        if #available(iOS 11.0, *) {
            return UIColor(named: "NordicLightGray")!
        } else {
            return #colorLiteral(red: 0.8790807724, green: 0.9051030278, blue: 0.9087315202, alpha: 1)
        }
    }()
    
    static let almostWhite: UIColor = {
        if #available(iOS 11.0, *) {
            return UIColor(named: "AlmostWhite")!
        } else {
            return #colorLiteral(red: 0.8550526997, green: 0.8550526997, blue: 0.8550526997, alpha: 1)
        }
    }()
    
    static let tableViewSeparator: UIColor = {
        if #available(iOS 11.0, *) {
            return UIColor(named: "TableViewSeparator")!
        } else {
            return #colorLiteral(red: 0.8243665099, green: 0.8215891719, blue: 0.8374734521, alpha: 1)
        }
    }()
    
    static let tableViewBackground: UIColor = {
        if #available(iOS 11.0, *) {
            return UIColor(named: "TableViewBackground")!
        } else {
            return #colorLiteral(red: 0.9499699473, green: 0.9504894614, blue: 0.965736568, alpha: 1)
        }
    }()
}
