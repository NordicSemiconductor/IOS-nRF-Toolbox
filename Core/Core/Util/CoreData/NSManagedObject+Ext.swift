//
//  NSManagedObject+Ext.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 05/06/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import CoreData

public extension NSManagedObject {
    class func getEntity(context: NSManagedObjectContext) -> NSEntityDescription? {
        let name = String(describing: self)
        let entity = NSEntityDescription.entity(forEntityName: name, in: context)
        return entity
    }
}
