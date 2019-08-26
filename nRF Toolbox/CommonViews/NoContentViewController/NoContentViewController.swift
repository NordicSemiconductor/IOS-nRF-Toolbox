//
//  NoContentViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 26/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NoContentViewController: UIViewController {
    
    override func loadView() {
        super.loadView()
        
        let image = UIImage(named: "Logo_Vertical_Transparent_White")?.withRenderingMode(.alwaysTemplate)
        
        let messageView = InfoActionView.instanceWithParams(image: image)
        self.view = messageView
    }
    
}
