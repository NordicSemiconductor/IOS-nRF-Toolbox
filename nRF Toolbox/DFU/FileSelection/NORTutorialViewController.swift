//
//  TutorialViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 13/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORTutorialViewController: UIViewController {

    //MARK: - View Actions
    
    @IBAction func openURLButtonTapped(sender: AnyObject) {
        self.hanleOpenURLButtonTapped()
    }
    
    
    //MARK: - NORTutorialViewController
    func hanleOpenURLButtonTapped() {
        let url = NSURL(string: "https://github.com/NordicSemiconductor/pc-nrfutil")!
        UIApplication.sharedApplication().openURL(url)
    }
}
