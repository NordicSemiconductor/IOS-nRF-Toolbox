//
//  TextCommand+CoreDataProperties.swift
//  
//
//  Created by Nick Kibish on 29.05.2020.
//
//

import Foundation
import CoreData


extension TextCommand {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TextCommand> {
        return NSFetchRequest<TextCommand>(entityName: "TextCommand")
    }

    @NSManaged public var eolSymbol: String?

}
