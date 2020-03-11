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
        self.name = "\(digit)"
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

extension ModernIcon {
    static let circle = ModernIcon(name: "circle")
    static let fill = ModernIcon(name: "fill")
    static let end = ModernIcon(name: "end")
    static let alt = ModernIcon(name: "alt")
    static let grid = ModernIcon(name: "grid")
    static let threeXthree = ModernIcon(name: "3x3")
    static let trash = ModernIcon(name: "trash")
    static let bolt = ModernIcon(name: "bolt")
    static let list = ModernIcon(name: "list")
    static let dash = ModernIcon(name: "dash")
    
    static let play = ModernIcon(name: "play")
    static let pause = ModernIcon(name: "pause")
    static let stop = ModernIcon(name: "stop")
    static let backward = ModernIcon(name: "backward")
    static let forward = ModernIcon(name: "forward")
    static let `repeat` = ModernIcon(name: "repeat")
    static let chevron = ModernIcon(name: "chevron")
    static let record = ModernIcon(name: "recordingtape")
    
    static let up = ModernIcon(name: "up")
    static let down = ModernIcon(name: "down")
    static let left = ModernIcon(name: "left")
    static let right = ModernIcon(name: "right")
    
    static let checkmark = ModernIcon(name: "checkmark")
    static let line = ModernIcon(name: "line")
    static let horizontal = ModernIcon(name: "horizontal")
    static let decrease = ModernIcon(name: "decrease")
    static let circlePath = ModernIcon(name: "circlepath")
    static let arrow = ModernIcon(name: "arrow")
    
    static let exclamationmark = ModernIcon(name: "exclamationmark")
    static let triangle = ModernIcon(name: "triangle")
}
