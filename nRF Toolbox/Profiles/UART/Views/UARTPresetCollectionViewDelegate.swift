//
//  UARTPresetCollectionViewDelegate.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 17/02/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol UARTPresetCollectionViewDelegate: class {
    func selectedCommand(_ command: UARTCommandModel, at index: Int)
    func longTapAtCommand(_ command: UARTCommandModel, at index: Int)
}

extension UARTPresetCollectionViewDelegate where Self: UIViewController & UARTNewCommandDelegate {
    func openPresetEditor(with command: UARTCommandModel?, index: Int) {
        let vc = UARTNewCommandViewController(command: command, index: index)
        vc.delegate = self
        let nc = UINavigationController.nordicBranded(rootViewController: vc, prefersLargeTitles: false)
        self.present(nc, animated: true)
    }
}
