//
//  ServiceProvider.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 22/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import Foundation

protocol ServiceProvider {
    var sections: [ServiceSection] { get }
}

struct ServiceSection {
    let title: String
    let services: [ServiceType]
}

struct DefaultServiceProvider: ServiceProvider {
    
    private static func loadServicesFromFile<T: ServiceType & Decodable>(_ fileName: String) -> [T] {
        let errorLogger = SystemLog(category: .ui, type: .error)
        guard let fileUrl = Bundle.main.url(forResource: fileName, withExtension: "plist") else {
            errorLogger.log(message: "Could not find \"\(fileName).plist\"")
            return []
        }
        do {
            let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
            return try PropertyListDecoder().decode([T].self, from: data)
        } catch let error {
            SystemLog(category: .ui, type: .error).log(message: "Could not load services: \(error.localizedDescription)")
            return []
        }
    }
    
    let sections: [ServiceSection] = {
        let bleServices: [BLEService] = DefaultServiceProvider.loadServicesFromFile("BLEServiceList")
        let utilsServices: [BLEService] = DefaultServiceProvider.loadServicesFromFile("InteractionServiceList")
        let smartHomeServices: [BLEService] = DefaultServiceProvider.loadServicesFromFile("IoTServices")
        let links: [LinkService] = DefaultServiceProvider.loadServicesFromFile("Links")
        return [
            ServiceSection(title: "Bluetooth Services", services: bleServices),
            ServiceSection(title: "Utils Services", services: utilsServices),
            ServiceSection(title: "Smart Homes", services: smartHomeServices),
            ServiceSection(title: "Links", services: links)
        ]
    }()
    
}
