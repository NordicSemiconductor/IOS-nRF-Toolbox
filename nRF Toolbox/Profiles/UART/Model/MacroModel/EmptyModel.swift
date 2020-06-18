//
//  EmptyModel.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 18.06.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class EmptyModel: NSObject, UARTCommandModel {
    private(set) let data: Data = Data()
    private(set) let icon: CommandImage? = nil
    private(set) let title: String = ""

    func encode(with coder: NSCoder) {
    }

    required init?(coder: NSCoder) {
    }
}
