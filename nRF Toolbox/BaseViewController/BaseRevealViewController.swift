//
//  BaseRevealViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 11/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import SWRevealViewController

class BaseRevealViewController: SWRevealViewController, UIAlertViewDelegate {

    func ShowAbout(message aMessage : String){
        let alertView = UIAlertController(title: "About", message: aMessage, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alertView, animated: true)
    }
}
