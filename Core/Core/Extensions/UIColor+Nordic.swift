/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



import UIKit

public extension UIColor {

    convenience init(r: Int, g: Int, b: Int, a: Int = 100) {
        let red = CGFloat(r) / 255
        let green = CGFloat(g) / 255
        let blue = CGFloat(b) / 255
        let alpha = CGFloat(a) / 100
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
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
    
    static let nordicYellow: UIColor = {
        if #available(iOS 11.0, *) {
            return UIColor(named: "NordicFall")!
        } else {
            return #colorLiteral(red: 0.9759542346, green: 0.5849055648, blue: 0.2069504261, alpha: 1)
        }
    }()
    
    static let nordicFall: UIColor = {
        if #available(iOS 11.0, *) {
            return UIColor(named: "NordicFall")!
        } else {
            return #colorLiteral(red: 0.9759542346, green: 0.5849055648, blue: 0.2069504261, alpha: 1)
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
            return UIColor(named: "NordicDarkGrey")!
        } else {
            return #colorLiteral(red: 0.2590435743, green: 0.3151275516, blue: 0.353839159, alpha: 1)
        }
    }()
    
    static let nordicGrey4: UIColor = {
        if #available(iOS 11, *) {
            return UIColor(named: "NordicGray4")!
        } else {
            return UIColor(red: 0.82, green: 0.82, blue: 0.839, alpha: 1)
        }
    }()

    static let nordicGrey5: UIColor = {
        if #available(iOS 11, *) {
            return UIColor(named: "NordicGray5")!
        } else {
            return UIColor(red: 0.89, green: 0.89, blue: 0.91, alpha: 1)
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
    
    static let nordicTextViewColor = dynamicColor(light: .white, dark: .black)
    static let nordicTextViewBordorColor: UIColor = {
        let light = UIColor(r: 205, g: 204, b: 205)
        let dark = UIColor(r: 50, g: 50, b: 50)
        return dynamicColor(light: light, dark: dark)
    }()
}

// MARK: - System Colors
extension UIColor {
    public struct NavigationBar {
        public static let barTint: UIColor = {
            let dark: UIColor
            if #available(iOS 13.0, *) {
                dark = .systemBackground
            } else {
                SystemLog(category: .ui, type: .fault).fault("iOS version not supported")
            }
            
            return .dynamicColor(light: .nordicBlue, dark: dark)
        }()
    }
}

// MARK: - Buttons
extension UIColor {
    public struct Button {
        public static let action: UIColor = {
            let dark: UIColor
            if #available(iOS 13.0, *) {
                dark = .systemBlue
            } else {
                dark = .black
            }
            
            return .dynamicColor(light: .nordicLake, dark: dark)
        }()
        
        public static let destructive: UIColor = {
            let dark: UIColor
            if #available(iOS 13.0, *) {
                dark = .systemRed
            } else {
                dark = .black 
            }
            
            return .dynamicColor(light: .nordicRed, dark: dark)
        }()
    }
}

// MARK: - Text Colors
public extension UIColor {
    struct Text {
        public static let systemText: UIColor = {
            if #available(iOS 13.0, *) {
                return .label
            } else {
                return .black
            }
        }()
        
        public static let secondarySystemText: UIColor = {
            if #available(iOS 13, *) {
                return .secondaryLabel
            } else {
                return .nordicDarkGray
            }
        }()
        
        public static let inactive: UIColor = {
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
    
    public static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection) -> UIColor in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        } else {
            return light
        }
    }
}


