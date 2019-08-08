//
//  NORBaseViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 13/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORBaseViewController: UIViewController, UIAlertViewDelegate {
    
    func showAbout(message aMessage : String) {
        let alertView = UIAlertController(title: "About", message: aMessage, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alertView, animated: true)
    }
    
    func showError(message aMessage: String, title aTitle: String) {
        let alertView = UIAlertController(title: aTitle, message: aMessage, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alertView, animated: true)
    }
}
