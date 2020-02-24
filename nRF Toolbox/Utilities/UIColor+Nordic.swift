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
    
    static let nordicGreen: UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor.dynamicColor(light: UIColor(named: "NordicGreen")!, dark: .systemGreen)
        } else if #available(iOS 11.0, *) {
            return UIColor(named: "NordicGreen")!
        } else {
            return #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
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
    
    static let nordicAlmostWhite: UIColor = {
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
    
    static let nordicLabel: UIColor = {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }()
    
    static let nordicBackground: UIColor = {
        if #available(iOS 13, *) {
            return .systemBackground
        } else {
            return .white
        }
    }()
    
    static let nordicSecondaryBackground: UIColor = {
        if #available(iOS 13, *) {
            return .secondarySystemBackground
        } else {
            return .nordicAlmostWhite
        }
    }()
}

// MARK: - System Colors
extension UIColor {
    struct NavigationBar {
        static let barTint: UIColor = {
            let dark: UIColor
            if #available(iOS 13.0, *) {
                dark = .systemBackground
            } else {
                Log(category: .ui, type: .fault).fault("iOS version not supported")
            }
            
            return .dynamicColor(light: .nordicBlue, dark: dark)
        }()
    }
}

// MARK: - Buttons
extension UIColor {
    struct Button {
        static let action: UIColor = {
            let dark: UIColor
            if #available(iOS 13.0, *) {
                dark = .systemBlue
            } else {
                dark = .black
            }
            
            return .dynamicColor(light: .nordicLake, dark: dark)
        }()
        
        static let destructive: UIColor = {
            let dark: UIColor
            if #available(iOS 13.0, *) {
                dark = .systemRed
            } else {
                dark = .black 
            }
            
            return .dynamicColor(light: .nordicRedDark, dark: dark)
        }()
    }
}

// MARK: - Text Colors
extension UIColor {
    struct Text {
        static let systemText: UIColor = {
            if #available(iOS 13.0, *) {
                return .label
            } else {
                return .black
            }
        }()
        
        static let secondarySystemText: UIColor = {
            if #available(iOS 13, *) {
                return .secondaryLabel
            } else {
                return .nordicDarkGray
            }
        }()
        
        static let inactive: UIColor = {
            if #available(iOS 13, *) {
                return .systemGray4
            } else {
                return .nordicAlmostWhite
            }
        }()
    }
}

extension UIColor {
    typealias RGBA = (Int, Int, Int, CGFloat)
    
    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection) -> UIColor in
                return traitCollection.userInterfaceStyle == .light ? light : dark
            }
        } else {
            return light
        }
    }
}
