//
//  Service.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 16/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct Service: Codable {
    let name: String
    let code: String?
    let icon: String
    let info: String
}
