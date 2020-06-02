//
//  UARTCommandModel+CoreDataProperties.swift
//  
//
//  Created by Nick Kibish on 02.06.2020.
//
//

import Foundation
import CoreData


extension UARTCommandModel {

    @nonobjc class func fetchRequest() -> NSFetchRequest<UARTCommandModel> {
        return NSFetchRequest<UARTCommandModel>(entityName: "UARTCommandModel")
    }

    @NSManaged var data: Data!
    @NSManaged var icon: CommandImage?
    @NSManaged var title: String!

}
