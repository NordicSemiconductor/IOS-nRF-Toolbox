//
//  NORNavigationController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 27/04/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORNavigationController: UINavigationController {
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationBar.tintColor = UIColor.whiteColor()
        let navBackgroundImage = UIImage(named: "BluetoothLogo")
        let navbackgroundImageView = UIImageView(image: navBackgroundImage)
        navbackgroundImageView.center = CGPointMake(self.navigationBar.frame.size.width/2, self.navigationBar.frame.size.height/2)
        self.navigationBar.addSubview(navbackgroundImageView)
    }
}
