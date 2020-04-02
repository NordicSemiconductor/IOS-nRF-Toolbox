//
//  UIImage+Ext.swift
//  DirectoryInspecto
//
//  Created by Nick Kibysh on 26/03/2020.
//  Copyright © 2020 Nick Kibysh. All rights reserved.
//

import UIKit

extension UIImage {
    public enum FileIconSize {
        case smallest
        case largest
    }

    public class func icon(forFileURL fileURL: URL, preferredSize: FileIconSize = .smallest) -> UIImage {
        let myInteractionController = UIDocumentInteractionController(url: fileURL)
        let allIcons = myInteractionController.icons

        // allIcons is guaranteed to have at least one image
        switch preferredSize {
        case .smallest: return allIcons.first!
        case .largest: return allIcons.last!
        }
    }
}
