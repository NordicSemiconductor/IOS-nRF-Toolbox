//
//  NORUARTRevealViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 11/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORUARTRevealViewController: NORBaseRevealViewController {

    //MARK: - ViewActions
    @IBAction func aboutButtonTapped(_ sender: AnyObject) {
        handleActionButtonTappedEvent()
    }
    
    //MARK: - UIViewDelegate
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the rear view width to almost whole screen width
        self.rearViewRevealWidth = UIScreen.main.bounds.size.width - 30
        self.rearViewRevealDisplacement = 0
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // This method is called after the device orientation has changed
        // Set the rear view width to almost whole screen width
        self.rearViewRevealWidth = size.width - 30;
    }

    //MARK: - Impementation
    func handleActionButtonTappedEvent() {
        self.ShowAbout(message: NORAppUtilities.getHelpTextForService(service: .uart))
    }

}
