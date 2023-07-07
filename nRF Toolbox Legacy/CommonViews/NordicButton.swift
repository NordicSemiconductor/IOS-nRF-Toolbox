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
            case .default: return .nordicLake
            default: return UIColor.Text.systemText
            }
        }
        
        var bgColor: UIColor {
            switch self {
            case .default, .destructive: return .clear
            case .mainAction: return .nordicLake
            default: return .clear
            }
        }
        
        var borderColor: UIColor {
            switch self {
            case .destructive: return .nordicRed
            case .mainAction, .default: return .nordicLake
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
        style = .default
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
