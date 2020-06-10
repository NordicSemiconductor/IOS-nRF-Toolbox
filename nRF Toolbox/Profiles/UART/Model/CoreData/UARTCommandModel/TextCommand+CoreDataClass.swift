//
//  TextCommand+CoreDataClass.swift
//  
//
//  Created by Nick Kibish on 27.05.2020.
//
//

import Foundation
import CoreData

@objc(TextCommand)
public class TextCommand: UARTCommandModel {
    
    public var commandText: String? {
        set {
            self.data = newValue?.data(using: .utf8)
        }
        get {
//            self.data.flatMap { String(data: $0, encoding: .utf8) }
            self.title
        }
    }
    
    var eol: EOL {
        EOL(symbol: eolSymbol!)
    }
    
    init(text: String, image: CommandImage, eol: EOL = .lf, context: NSManagedObjectContext? = CoreDataStack.uart.viewContext) {
        if let entity = context.flatMap({ Self.getEntity(context: $0) }) {
            super.init(entity: entity, insertInto: context)
        } else {
            super.init()
        }
        self.icon = image
        self.commandText = text
        self.title = text
        self.eolSymbol = eol.rawValue
        
    }
    
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

}
