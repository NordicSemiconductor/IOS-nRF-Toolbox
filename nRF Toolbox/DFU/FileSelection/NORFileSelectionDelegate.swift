//
//  NORFileSelectionDelegate.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 12/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

@objc protocol NORFileSelectionDelegate {
    func onFileSelected(withURL aFileURL : NSURL)
}
