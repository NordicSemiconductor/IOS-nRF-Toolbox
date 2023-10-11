//
//  RSSIItem_Preview.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 10/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Foundation

extension RSSIItem {
    static var preview: [RSSIItem] { [
        .init(timeinterval: 110, value: 10),
        .init(timeinterval: 112, value: 12),
        .init(timeinterval: 113, value: 11),
        .init(timeinterval: 114, value: 14),
        .init(timeinterval: 115, value: 13),
        .init(timeinterval: 116, value: 14),
        .init(timeinterval: 117, value: 11),
        .init(timeinterval: 118, value: 18),
        .init(timeinterval: 119, value: 17),
        .init(timeinterval: 120, value: 5),
        .init(timeinterval: 121, value: 6),
        .init(timeinterval: 122, value: 4),
        .init(timeinterval: 123, value: 7),
        .init(timeinterval: 124, value: 5)
    ]
    }
}
