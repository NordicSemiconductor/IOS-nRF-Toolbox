//
//  NORBaseViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 13/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORBaseViewController: UIViewController, UIAlertViewDelegate {
    
    func showAbout(message aMessage : String, otherButtonTitle aButtonTitle : String?) {
        var alertView : UIAlertView?

        if aButtonTitle == nil {
            alertView = UIAlertView(title: "About", message: aMessage, delegate: self, cancelButtonTitle: "OK")
        }else{
            alertView = UIAlertView(title: "About", message: aMessage, delegate: self, cancelButtonTitle: "OK", otherButtonTitles: aButtonTitle!)
        }

        alertView?.show()
    }
    
    func showAbout(message aMessage : String){
        self.showAbout(message: aMessage, otherButtonTitle: nil)
    }
}
