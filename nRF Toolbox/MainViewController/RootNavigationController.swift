//
//  ModalNavigationController.swift
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 07/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class RootNavigationController: UINavigationController {
    
    // Make sure the status bar is light in the app.
    // The default is set to black, as this one is used in the Launch Screen.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}
