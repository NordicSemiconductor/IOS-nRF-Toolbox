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
    init(commands: [UARTCommandModel], name: String, context: NSManagedObjectContext = CoreDataStack.uart.viewContext) {
        let entity = NSEntityDescription.entity(forEntityName: "UARTPreset", in: context)
        super.init(entity: entity!, insertInto: context)
        self.commands = commands
        self.name = name
    }
    
    var commands: [UARTCommandModel] {
        set {
            newValue.forEach(self.addToCommandsSet)
        }
        get {
            self.commandsSet.map { $0 as! UARTCommandModel }
        }
    }
    
    func updateCommand(_ command: UARTCommandModel, at index: Int) {
        removeFromCommandsSet(at: index)
        insertIntoCommandsSet(command, at: index)
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
    
    static let empty = UARTPreset(commands: Array(repeating: EmptyModel(), count: 9), name: "")
}
