//
//  DFUStartViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 26/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class DFUStartViewController: UIViewController {
    
    init(router: DFURouter) {
        super.init(nibName: "DFUStartViewController", bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

}
