//
//  NORBaseRevealViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 11/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import SWRevealViewController

class NORBaseRevealViewController: SWRevealViewController, UIAlertViewDelegate {

    func ShowAbout(message aMessage : String){
        let alertView = UIAlertView(title: "About", message: aMessage, delegate: self, cancelButtonTitle: "OK")
        alertView.show()
    }
}
