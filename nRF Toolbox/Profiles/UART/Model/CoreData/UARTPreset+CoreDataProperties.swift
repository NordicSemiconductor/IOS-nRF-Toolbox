//
//  UARTPreset+CoreDataProperties.swift
//  
//
//  Created by Nick Kibish on 03.06.2020.
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

// MARK: Generated accessors for commands
extension UARTPreset {

    @objc(insertObject:inCommandsAtIndex:)
    @NSManaged public func insertIntoCommands(_ value: UARTCommandModel, at idx: Int)

    @objc(removeObjectFromCommandsAtIndex:)
    @NSManaged public func removeFromCommands(at idx: Int)

    @objc(insertCommands:atIndexes:)
    @NSManaged public func insertIntoCommands(_ values: [UARTCommandModel], at indexes: NSIndexSet)

    @objc(removeCommandsAtIndexes:)
    @NSManaged public func removeFromCommands(at indexes: NSIndexSet)

    @objc(replaceObjectInCommandsAtIndex:withObject:)
    @NSManaged public func replaceCommands(at idx: Int, with value: UARTCommandModel)

    @objc(replaceCommandsAtIndexes:withCommands:)
    @NSManaged public func replaceCommands(at indexes: NSIndexSet, with values: [UARTCommandModel])

    @objc(addCommandsObject:)
    @NSManaged public func addToCommands(_ value: UARTCommandModel)

    @objc(removeCommandsObject:)
    @NSManaged public func removeFromCommands(_ value: UARTCommandModel)

    @objc(addCommands:)
    @NSManaged public func addToCommands(_ values: NSOrderedSet)

    @objc(removeCommands:)
    @NSManaged public func removeFromCommands(_ values: NSOrderedSet)

}
