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

protocol PeripheralViewDelegate: AnyObject {
    func requestConnect()
    func requestDisconnect()
}

class PeripheralView: UIView, XibInstantiable {
    @IBOutlet var peripheralName: UILabel!
    @IBOutlet var connectButton: NordicButton!
    
    @IBOutlet private var container: UIView!
    
    weak var delegate: PeripheralViewDelegate?
    private var isConnected: Bool = false
    
    @IBAction func connectionPressed() {
        if case .destructive = connectButton.style {
            delegate?.requestDisconnect()
        } else {
            delegate?.requestConnect()
        }
    }
    
    func connected(peripheral name: String) {
        peripheralName.text = name
        peripheralName.font = UIFont.gtEestiDisplay(.regular, size: 22)
        peripheralName.textColor = UIColor.Text.systemText
        
        connectButton.setTitle("Disconnect", for: .normal)
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
        view.frame = bounds
        addSubview(view)
        container = view
    }

    func loadViewFromNib() -> UIView? {
        let nibName = String(describing: type(of: self))
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
}
