//
//  NORBaseViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 13/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORBaseViewController: UIViewController, UIAlertViewDelegate {
    
    func showMessage(message aMessage: String, title aTitle: String, otherButtonTitle aButtonTitle : String?) {
        var alertView : UIAlertView?

        if aButtonTitle != nil {
            alertView = UIAlertView(title: aTitle, message: aMessage, delegate: self, cancelButtonTitle: "OK", otherButtonTitles: aButtonTitle!)
        } else {
            alertView = UIAlertView(title: aTitle, message: aMessage, delegate: self, cancelButtonTitle: "OK")
        }

        alertView?.show()
    }
    
    func showAbout(message aMessage : String) {
        self.showMessage(message: aMessage, title: "About", otherButtonTitle: nil)
    }
    
    func showError(message aMessage: String, title aTitle: String) {
        self.showMessage(message: aMessage, title: aTitle, otherButtonTitle: nil)
    }
}
