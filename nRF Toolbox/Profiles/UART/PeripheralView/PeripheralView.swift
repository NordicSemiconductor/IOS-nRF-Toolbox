//
//  PeripheralView.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 17/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol PeripheralViewDelegate: class {
    func requestConnect()
}

class PeripheralView: UIView, XibInstantiable {
    @IBOutlet var peripheralName: UILabel!
    @IBOutlet var connectButton: NordicButton!
    
    @IBOutlet private var container: UIView!
    
    weak var delegate: PeripheralViewDelegate?
    private var isConnected: Bool = false
    
    @IBAction func connectionPressed() {
        delegate?.requestConnect()
    }
    
    func connected(peripheral name: String) {
        peripheralName.text = name
        peripheralName.font = UIFont.gtEestiDisplay(.regular, size: 22)
        peripheralName.textColor = UIColor.Text.systemText
        
        connectButton.setTitle("Reconnect", for: .normal)
        connectButton.style = .destructive
        isConnected = true
    }
    
    func disconnect() {
        peripheralName.text = "Not connected"
        peripheralName.font = UIFont.gtEestiDisplay(.light, size: 22)
        peripheralName.textColor = UIColor.Text.secondarySystemText
        
        connectButton.setTitle("Connect", for: .normal)
        connectButton.style = .mainAction
        isConnected = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        guard let view = loadViewFromNib() else { return }
        view.frame = self.bounds
        self.addSubview(view)
        container = view
    }

    func loadViewFromNib() -> UIView? {
        let nibName = String(describing: type(of: self))
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
}
