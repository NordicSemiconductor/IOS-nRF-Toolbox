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
            switch self {
            case .mainAction: return .white
            case .destructive: return .nordicRed
            case .default: return .nordicDarkGray
            default: return UIColor.Text.systemText
            }
        }
        
        var bgColor: UIColor {
            switch self {
            case .default, .destructive: return .clear
            case .mainAction: return .nordicBlue
            default: return .clear
            }
        }
        
        var borderColor: UIColor {
            switch self {
            case .destructive: return .nordicRed
            case .mainAction, .default: return .nordicBlue
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
            borderColor = style.borderColor
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
        cornerRadius = 4
        borderWidth = 1
        
        guard isEnabled else {
            setTitleColor(UIColor.Text.inactive, for: .normal)
            borderColor = UIColor.Text.inactive
            backgroundColor = .clear
            return
        }
        
        borderColor = style.borderColor
        setTitleColor(style.tintColor, for: .normal)
        backgroundColor = style.bgColor
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        cornerRadius = 4
        layer.masksToBounds = true
    }
    
    func apply(configurator: NordicButtonConfigurator) {
        isHidden = configurator.isHidden
        setTitle(configurator.normalTitle, for: .normal)
        style = configurator.style
    }
}
