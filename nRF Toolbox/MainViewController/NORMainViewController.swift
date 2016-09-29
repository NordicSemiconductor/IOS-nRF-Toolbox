//
//  NORMainViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 27/04/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class NORMainViewController: UIViewController, UICollectionViewDataSource, UIAlertViewDelegate {

    // MARK: - Outlets & Actions
    @IBOutlet weak var collectionView: UICollectionView!

    @IBAction func aboutButtonTapped(_ sender: AnyObject) {
        showAboutAlertView()
    }
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
    }
    
    func showAboutAlertView() {
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        //Note: The character \u{2022} found here is a unicode bullet, used just for styling purposes
        let aboutMessage = String("The nRF Toolbox works with the most popular Bluetooth Low Energy accessories that use standard BLE profiles. Additionaly, it supports Nordic Semiconductor's proprietary profiles:\n\n\u{2022}UART (Universal Asynchronous Receiver/Transmitter),\n\n\u{2022}DFU (Device Firmware Update).\n\nMore information and the source code may be found on GitHub.\n\nVersion \(appVersion)")
        
        let alertView = UIAlertView.init(title: "About", message: aboutMessage!, delegate: self, cancelButtonTitle: "Ok", otherButtonTitles:"GitHub")
        alertView.show()
    }

    // MARK: - UIalertViewDelegate
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if buttonIndex == 1 {
            UIApplication.shared.openURL(URL(string: "https://github.com/NordicSemiconductor/IOS-nRF-Toolbox")!)
        }
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellName = String(format: "profile_%d", (indexPath as NSIndexPath).item)
        return collectionView.dequeueReusableCell(withReuseIdentifier: cellName, for: indexPath)
    }

}
