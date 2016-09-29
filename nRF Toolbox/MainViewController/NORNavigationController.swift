//
//  NORNavigationController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 27/04/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORNavigationController: UINavigationController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationBar.tintColor = UIColor.white
        let navBackgroundImage = UIImage(named: "BluetoothLogo")
        let navbackgroundImageView = UIImageView(image: navBackgroundImage)
        navbackgroundImageView.center = CGPoint(x: self.navigationBar.frame.size.width/2, y: self.navigationBar.frame.size.height/2)
        self.navigationBar.addSubview(navbackgroundImageView)
    }
}
