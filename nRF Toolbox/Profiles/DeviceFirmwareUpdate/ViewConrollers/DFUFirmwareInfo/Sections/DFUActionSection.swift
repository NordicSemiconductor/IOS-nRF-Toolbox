//
//  DFUActionSection.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 04/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

protocol DFUActionSection: Section {
    var action: () -> () { get }
}
