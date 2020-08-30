//
//  Command.swift
//  UART
//
//  Created by Nick Kibysh on 25/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import UIKit.UIImage

public protocol Command {
    var data: Data { get }
    var icon: CommandImage { get }
    var title: String { get }
}

public extension Command {
    var image: UIImage? {
        icon.image
    }
}
