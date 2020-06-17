//
//  UARTPreset+CoreDataClass.swift
//  
//
//  Created by Nick Kibish on 03.06.2020.
//
//

import Foundation
import CoreData

@objc(UARTPreset)
public class UARTPreset: NSManagedObject {
    
    var isEmpty: Bool {
        self.commands.reduce(true) { $0 && ($1 is EmptyModel) }
    }
    
    init(commands: [UARTCommandModel], name: String, context: NSManagedObjectContext? = CoreDataStack.uart.viewContext) {
        if let entity = context.flatMap({ Self.getEntity(context: $0) }) {
            super.init(entity: entity, insertInto: context)
        } else {
            super.init()
        }
        self.commands = commands
        commands.forEach {
            self.insertIntoCommandsSet($0, at: 0)
        }
        self.name = name
    }
    
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
        self.commands = self.commandsSet.map { $0 as! UARTCommandModel }
    }
    
    var commands: [UARTCommandModel] = [] {
        didSet {
            commandsSet.map { $0 as! UARTCommandModel }
                .forEach(self.removeFromCommandsSet)
                
            commands.forEach(self.addToCommandsSet)
            print(commands.count)
        }
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
    }
    
    public override func willSave() {
        super.willSave()
    }
    
    func updateCommand(_ command: UARTCommandModel, at index: Int) {
        commands[index] = command
        
        commandsSet.compactMap { $0 as? UARTCommandModel }
            .forEach(self.removeFromCommandsSet)
        
        let set = NSOrderedSet(array: commands)
        self.addToCommandsSet(set)
        
        print(commandsSet.count)
    }
}

extension UARTPreset {
    static var empty: UARTPreset {
        UARTPreset(commands: Array(repeating: EmptyModel.emptyModel(), count: 9), name: "")
    }
}
