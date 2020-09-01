//
//  CoreDataStack+UART.swift
//  UART
//
//  Created by Nick Kibysh on 26/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Core
import CoreData

extension CoreDataStack {
    static let uart: CoreDataStack = {
        let customBundle = Bundle(identifier: "com.nordicsemi.uart")
        
        guard let modelURL = customBundle?.url(forResource: "UART", withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        
        let stack = CoreDataStack(containerName: "UART", managedObjectModel: mom)
        return stack
    }()
}
