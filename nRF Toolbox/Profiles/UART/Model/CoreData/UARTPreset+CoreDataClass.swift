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
            commands.forEach(self.addToCommandsSet)
            print(commands.count)
        }
    }
    /*
     {
        set {
            newValue.forEach(self.addToCommandsSet)
            
        }
        get {
            self.commandsSet.map { $0 as! UARTCommandModel }
        }
    }
     */
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
    }
    
    public override func willSave() {
//        commands.forEach(self.addToCommandsSet)
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
    static let `default` = UARTPreset(commands: [
        DataCommand(data: Data([0x01]), image: .number1),
        DataCommand(data: Data([0x02]), image: .number2),
        DataCommand(data: Data([0x03]), image: .number3),
        TextCommand(text: "Pause", image: .pause),
        TextCommand(text: "Play", image: .play),
        TextCommand(text: "Stop", image: .stop),
        TextCommand(text: "Rew", image: .rewind),
        TextCommand(text: "Start", image: .start),
        TextCommand(text: "Repeat", image: .repeat)
    ], name: "Demo")
    
//    static let empty = UARTPreset(commands: Array(repeating: EmptyModel.emptyModel(in: CoreDataStack.uart.viewContext), count: 9), name: "")
}
