//
//  ModernIcon.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 12/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit.UIImage

struct ModernIcon: Codable, Equatable {
    private (set) var name: String
    init(name: String) {
        self.name = name
    }
    
    init(digit: Int) {
        name = "\(digit)"
    }
    
    func add(_ icon: ModernIcon) -> ModernIcon {
        return ModernIcon(name: "\(name).\(icon.name)")
    }
    
    func callAsFunction(_ icon: ModernIcon) -> ModernIcon {
        return ModernIcon(name: "\(name).\(icon.name)")
    }
    
    @available(iOS 13.0, *)
    var image: UIImage? {
        return UIImage(systemName: name)
    }
}
