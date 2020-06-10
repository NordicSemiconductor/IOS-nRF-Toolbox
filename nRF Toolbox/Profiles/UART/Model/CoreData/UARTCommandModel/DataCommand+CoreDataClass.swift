//
//  DataCommand+CoreDataClass.swift
//  
//
//  Created by Nick Kibish on 02.06.2020.
//
//

import Foundation
import CoreData

@objc(DataCommand)
public class DataCommand: UARTCommandModel {
    init(data: Data, image: CommandImage, context: NSManagedObjectContext? = CoreDataStack.uart.viewContext) {
        if let entity = context.flatMap({ Self.getEntity(context: $0) }) {
            super.init(entity: entity, insertInto: context)
        } else {
            super.init()
        }
        
        self.data = data
        self.icon = image
        self.title = "0x" + data.hexString
    }
    
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

}
