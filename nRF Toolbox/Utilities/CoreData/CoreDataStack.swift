//
//  CoreDataStack.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 28.05.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import CoreData

class CoreDataStack {
    init(containerName: String) {
        persistantContainer = NSPersistentContainer(name: containerName)
        persistantContainer.loadPersistentStores { (storeDescription, error) in
            if let e = error {
                fatalError(e.localizedDescription)
            }
        }
    }
    
    static let uart = CoreDataStack(containerName: "UART")
    
    let persistantContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        persistantContainer.viewContext
    }
    
    
}
