//
//  FileSizeView.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 02/12/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

private class SizePartView: UIView {
    let titleLabel = UILabel()
    let sizeLabel = UILabel()
    
    override var tintColor: UIColor! {
        didSet {
            titleLabel.textColor = tintColor
            sizeLabel.textColor = tintColor
        }
    }
    
    var size: Int = 0 {
        didSet {
            sizeLabel.text = ByteCountFormatter().string(fromByteCount: Int64(size))
        }
    }
    
    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }
    
    init(title: String, size: Int, color: UIColor) {
        super.init(frame: .zero)
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, sizeLabel])
        stackView.axis = .horizontal
        self.addSubview(stackView)
        stackView.addZeroBorderConstraints()
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5
        
        titleLabel.font = UIFont.gtEestiDisplay(.regular, size: 14)
        titleLabel.textAlignment = .right
        sizeLabel.font = UIFont.gtEestiDisplay(.bold, size: 14)
        
        defer {
            self.title = title
            self.size = size
            self.tintColor = color
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FileSizeView: UIView {
    let stackView = UIStackView()
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        self.addSubview(stackView)
        stackView.spacing = 8
        stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
    }
    
    func update(with firmware: DFUFirmware) {
        let subviewes = stackView.arrangedSubviews
        subviewes.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        let bootloader = Int(firmware.size.bootloader)
        let softDevice = Int(firmware.size.softdevice)
        let application = Int(firmware.size.application)
        
        if bootloader > 1 {
            self.stackView.addArrangedSubview(SizePartView(title: "Bootloader", size: bootloader, color: .firmwareBootloader))
        }
        
        if softDevice > 1 {
            self.stackView.addArrangedSubview(SizePartView(title: "Soft Device", size: softDevice, color: .firmwareSoftDevice))
        }
        
        if application > 1 {
            self.stackView.addArrangedSubview(SizePartView(title: "Application", size: application, color: .firmwareApplication))
        }
    }
}
