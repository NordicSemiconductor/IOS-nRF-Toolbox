//
//  MainViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 27/04/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UICollectionViewDataSource {

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
    
    func showAboutAlertView() {
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        //Note: The character \u{2022} found here is a unicode bullet, used just for styling purposes
        let aboutMessage = String("The nRF Toolbox works with the most popular Bluetooth Low Energy accessories that use standard BLE profiles. Additionaly, it supports Nordic Semiconductor's proprietary profiles:\n\n\u{2022}UART (Universal Asynchronous Receiver/Transmitter),\n\n\u{2022}DFU (Device Firmware Update).\n\nMore information and the source code may be found on GitHub.\n\nVersion \(appVersion)")
        
        let alertView = UIAlertController(title: "About", message: aboutMessage, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "OK", style: .cancel))
        alertView.addAction(UIAlertAction(title: "GitHub", style: .default) { _ in
            UIApplication.shared.openURL(URL(string: "https://github.com/NordicSemiconductor/IOS-nRF-Toolbox")!)
        })
        present(alertView, animated: true)
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 11
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellName = String(format: "profile_%d", indexPath.item)
        return collectionView.dequeueReusableCell(withReuseIdentifier: cellName, for: indexPath)
    }

}
