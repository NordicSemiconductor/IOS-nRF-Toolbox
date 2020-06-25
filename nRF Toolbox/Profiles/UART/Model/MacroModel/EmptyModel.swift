//
//  EmptyModel.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 18.06.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class EmptyModel: NSObject, UARTCommandModel {
    let data: Data
    let icon: CommandImage?
    let title: String
    
    override init() {
        data = Data()
        icon = nil
        title = ""
        
        super.init()
    }

    func encode(with coder: NSCoder) {
    }

    required init?(coder: NSCoder) {
        data = Data()
        icon = nil
        title = ""
    }
    
    func clone() -> UARTCommandModel {
        EmptyModel()
    }
}
