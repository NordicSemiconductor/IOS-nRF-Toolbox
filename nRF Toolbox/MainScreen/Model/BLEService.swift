//
//  Service.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 16/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol ServiceType {
    var name: String { get }
    var iconImage: UIImage? { get }
    var id: String { get }
}

struct BLEService: Codable {
    let name: String
    let code: String?
    let icon: String
    let info: String
    let id: String
    let uuid: UUID?
}

extension BLEService: ServiceType {
    var iconImage: UIImage? {
        return UIImage(named: icon)
    }
}

struct LinkService: Decodable {
    let name: String
    let url: URL
    let description: String
    let id: String
}

extension LinkService: ServiceType {
    var iconImage: UIImage? {
        return nil // Maybe we should provide GitHub icon or Nordic DevZone
    }
}
