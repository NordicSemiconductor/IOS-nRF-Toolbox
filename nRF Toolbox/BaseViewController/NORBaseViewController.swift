//
//  NORBaseViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 27/04/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORBaseViewController: UIViewController, UIAlertViewDelegate {

    func showAbout(message aMessage :String) {
        self.showAbout(message: aMessage, otherButtonTitle: nil)
    }

    func showAbout(message aMessage :String, otherButtonTitle aButtonTitle : String?) {
        let anAlertView = UIAlertView(title: "About", message: aMessage, delegate: self, cancelButtonTitle: "Ok", otherButtonTitles: (aButtonTitle)!)
        anAlertView.show()
    }

}