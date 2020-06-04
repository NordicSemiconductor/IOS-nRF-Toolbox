//
//  UARTMacro+CoreDataProperties.swift
//  
//
//  Created by Nick Kibish on 04.06.2020.
//
//

import Foundation
import CoreData


extension UARTMacro {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UARTMacro> {
        return NSFetchRequest<UARTMacro>(entityName: "UARTMacro")
    }

    @NSManaged public var name: String!
    @NSManaged public var commandsSet: NSOrderedSet!
    @NSManaged public var preset: UARTPreset!

}

// MARK: Generated accessors for commandsSet
extension UARTMacro {

    @objc(insertObject:inCommandsSetAtIndex:)
    @NSManaged public func insertIntoCommandsSet(_ value: UARTMacroElement, at idx: Int)

    @objc(removeObjectFromCommandsSetAtIndex:)
    @NSManaged public func removeFromCommandsSet(at idx: Int)

    @objc(insertCommandsSet:atIndexes:)
    @NSManaged public func insertIntoCommandsSet(_ values: [UARTMacroElement], at indexes: NSIndexSet)

    @objc(removeCommandsSetAtIndexes:)
    @NSManaged public func removeFromCommandsSet(at indexes: NSIndexSet)

    @objc(replaceObjectInCommandsSetAtIndex:withObject:)
    @NSManaged public func replaceCommandsSet(at idx: Int, with value: UARTMacroElement)

    @objc(replaceCommandsSetAtIndexes:withCommandsSet:)
    @NSManaged public func replaceCommandsSet(at indexes: NSIndexSet, with values: [UARTMacroElement])

    @objc(addCommandsSetObject:)
    @NSManaged public func addToCommandsSet(_ value: UARTMacroElement)

    @objc(removeCommandsSetObject:)
    @NSManaged public func removeFromCommandsSet(_ value: UARTMacroElement)

    @objc(addCommandsSet:)
    @NSManaged public func addToCommandsSet(_ values: NSOrderedSet)

    @objc(removeCommandsSet:)
    @NSManaged public func removeFromCommandsSet(_ values: NSOrderedSet)

}
