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
    init(data: Data, image: CommandImage, context: NSManagedObjectContext = CoreDataStack.uart.viewContext) {
        let entity = NSEntityDescription.entity(forEntityName: "DataCommand", in: context)
        super.init(entity: entity!, insertInto: context)
        
        self.data = data
        self.icon = image
        self.title = "0x" + data.hexString
    }

}
