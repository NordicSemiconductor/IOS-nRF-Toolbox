//
//  NordicButton.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 04/12/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

struct NordicButtonConfigurator {
    var isHidden: Bool = false
    var normalTitle: String
    var style: NordicButton.Style = .default
}

class NordicButton: UIButton {
    
    struct Style: RawRepresentable, Equatable {
        let rawValue: Int
        
        static let `default` = Style(rawValue: 1)
        static let mainAction = Style(rawValue: 2)
        static let destructive = Style(rawValue: 3)
        
        var tintColor: UIColor {
            return .nordicDarkGray
        }
        
        var bgColor: UIColor {
            switch self {
            case .default: return .clear
            case .mainAction: return .nordicBlue
            case .destructive: return .nordicRedDark
            default: return .clear
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            setupBrandView()
        }
    }
    
    var style: Style = .default {
        didSet {
            tintColor = style.tintColor
            self.setupBrandView()
        }
    }
    
    var normalTitle: String? {
        get { title(for: .normal) }
        set { setTitle(newValue, for: .normal) }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBrandView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBrandView()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.style = .default
    }
    
    private func setupBrandView() {
        cornerRadius = min(frame.width, frame.height) / 2
        borderWidth = 1
        
        guard isEnabled else {
            setTitleColor(UIColor.Text.inactive, for: .normal)
            borderColor = UIColor.Text.inactive
            backgroundColor = .clear
            return
        }
        
        borderColor = style.tintColor
        setTitleColor(style.tintColor, for: .normal)
        backgroundColor = style.bgColor
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        cornerRadius = min(frame.width, frame.height) / 2
        layer.masksToBounds = true
    }
    
    func apply(configurator: NordicButtonConfigurator) {
        isHidden = configurator.isHidden
        setTitle(configurator.normalTitle, for: .normal)
        style = configurator.style
    }
}
