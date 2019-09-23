//
//  UINavigationController+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 22/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

extension UINavigationController {
    static func nordicBranded(rootViewController: UIViewController, prefersLargeTitles: Bool = false) -> UINavigationController {
        let nc = UINavigationController(rootViewController: rootViewController)
        nc.navigationBar.tintColor = .almostWhite
        nc.navigationBar.barTintColor = .nordicBlue
        
        if #available(iOS 11.0, *) {
            let attributes: [NSAttributedString.Key : Any] = [
                .foregroundColor : UIColor.almostWhite
            ]
            
            nc.navigationBar.titleTextAttributes = attributes
            nc.navigationBar.largeTitleTextAttributes = attributes
            nc.navigationBar.prefersLargeTitles = prefersLargeTitles
        }
        
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.backgroundColor = UIColor.NavigationBar.barTint
            
            nc.navigationBar.standardAppearance = navBarAppearance
            nc.navigationBar.scrollEdgeAppearance = navBarAppearance
        }
        
        return nc
    }
}
