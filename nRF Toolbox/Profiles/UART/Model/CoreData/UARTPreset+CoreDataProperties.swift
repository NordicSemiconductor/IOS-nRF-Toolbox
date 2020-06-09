//
//  UARTPreset+CoreDataProperties.swift
//  
//
//  Created by Nick Kibysh on 05/06/2020.
//
//

import Foundation
import CoreData


extension UARTPreset {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UARTPreset> {
        return NSFetchRequest<UARTPreset>(entityName: "UARTPreset")
    }

    @NSManaged public var name: String!
    @NSManaged public var commandsSet: NSOrderedSet!

}

// MARK: Generated accessors for commandsSet
extension UARTPreset {

    @objc(insertObject:inCommandsSetAtIndex:)
    @NSManaged public func insertIntoCommandsSet(_ value: UARTCommandModel, at idx: Int)

    @objc(removeObjectFromCommandsSetAtIndex:)
    @NSManaged public func removeFromCommandsSet(at idx: Int)

    @objc(insertCommandsSet:atIndexes:)
    @NSManaged public func insertIntoCommandsSet(_ values: [UARTCommandModel], at indexes: NSIndexSet)

    @objc(removeCommandsSetAtIndexes:)
    @NSManaged public func removeFromCommandsSet(at indexes: NSIndexSet)

    @objc(replaceObjectInCommandsSetAtIndex:withObject:)
    @NSManaged public func replaceCommandsSet(at idx: Int, with value: UARTCommandModel)

    @objc(replaceCommandsSetAtIndexes:withCommandsSet:)
    @NSManaged public func replaceCommandsSet(at indexes: NSIndexSet, with values: [UARTCommandModel])

    @objc(addCommandsSetObject:)
    @NSManaged public func addToCommandsSet(_ value: UARTCommandModel)

    @objc(removeCommandsSetObject:)
    @NSManaged public func removeFromCommandsSet(_ value: UARTCommandModel)

    @objc(addCommandsSet:)
    @NSManaged public func addToCommandsSet(_ values: NSOrderedSet)

    @objc(removeCommandsSet:)
    @NSManaged public func removeFromCommandsSet(_ values: NSOrderedSet)

}
