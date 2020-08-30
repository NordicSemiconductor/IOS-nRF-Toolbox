//
// Created by Nick Kibysh on 28/08/2020.
// Copyright (c) 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

public enum MacrosElement {
    case delay(TimeInterval)
    case commandContainer(MacrosCommandContainer)
}