//
//  CoreDataStack.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 28.05.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import CoreData

open class CoreDataStack {
    public init(containerName: String, managedObjectModel: NSManagedObjectModel? = nil) {
        if let model = managedObjectModel {
            persistantContainer = NSPersistentContainer(name: containerName, managedObjectModel: model)
        } else {
            persistantContainer = NSPersistentContainer(name: containerName)
        }
        persistantContainer.loadPersistentStores { (storeDescription, error) in
            if let e = error {
                fatalError(e.localizedDescription)
            }
        }
    }
    
    public let persistantContainer: NSPersistentContainer
    
    open var viewContext: NSManagedObjectContext {
        persistantContainer.viewContext
    }
    
    
}
