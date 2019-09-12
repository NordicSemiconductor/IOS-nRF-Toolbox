//
//  TitledError.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 12/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

struct TitledError: Error {
    let title: String
    let message: String?
    
    init(title: String = "Error", message: String? = nil ) {
        self.title = title
        self.message = message
    }
    
    var localizedDescription: String {
        return message ?? ""
    }
}
