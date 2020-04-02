//
//  Segment.swift
//  Pods-SegmentedView_Example
//
//  Created by Nick Kibysh on 28/02/2020.
//

import Foundation
import UIKit.UIColor

public struct Segment {
    public let size: Float
    public let color: UIColor
    public let title: String
    public let shortTitle: String?
    
    public init(size: Float, color: UIColor, title: String, shortTitle: String? = nil) {
        self.size = size
        self.color = color
        self.title = title
        self.shortTitle = shortTitle
    }
}
