//
//  TutorialViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 13/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController {

    //MARK: - View Actions
    
    @IBAction func openURLButtonTapped(_ sender: AnyObject) {
        self.hanleOpenURLButtonTapped()
    }
    
    
    //MARK: - TutorialViewController
    func hanleOpenURLButtonTapped() {
        let url = URL(string: "https://github.com/NordicSemiconductor/pc-nrfutil")!
        UIApplication.shared.openURL(url)
    }
}
