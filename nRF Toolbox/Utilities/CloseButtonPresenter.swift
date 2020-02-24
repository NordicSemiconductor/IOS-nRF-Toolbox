//
//  CloseButtonPresenter.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol CloseButtonPresenter: NSObjectProtocol {
    func setupCloseButton()
}

extension CloseButtonPresenter where Self: UIViewController {
    func setupCloseButton() {
        let closeBtn: UIBarButtonItem = {
            if #available(iOS 13, *) {
                return UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismsiss))
            } else {
                return UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(dismsiss))
            }
        }()
        
        navigationItem.leftBarButtonItem = closeBtn
    }
}
