//
//  UARTMacro+CoreDataClass.swift
//  
//
//  Created by Nick Kibish on 03.06.2020.
//
//

import Foundation
import CoreData

@objc(UARTMacro)
class UARTMacro: NSManagedObject {
    
    var commands: [UARTCommandModel] {
        elements.compactMap { $0 as? UARTCommandModel }
    }
    
    var color: UARTColor {
        get {
            UARTColor(colorNameString: self.colorName)!
        }
        set {
            self.colorName = newValue.name.rawValue
        }
    }
    
    var elements: [UARTMacroElement] {
        get {
            commandSet.compactMap { $0 as? UARTMacroElement }
        }
        set {
            commandSet = newValue.compactMap { $0 as? NSObject }
        }
    }
    
    subscript(index: Int) -> UARTMacroElement {
        get {
            commandSet[index] as! UARTMacroElement
        }
        set(newValue) {
            commandSet[index] = newValue as! NSObject
        }
    }
    
    init(name: String, color: UARTColor, commands: [UARTMacroElement], context: NSManagedObjectContext? = CoreDataStack.uart.viewContext) {
        
        if let entity = context.flatMap({ Self.getEntity(context: $0) }) {
            super.init(entity: entity, insertInto: context)
        } else {
            super.init()
        }

        self.name = name
        self.elements = commands
        self.color = color
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    static let empty = UARTMacro(name: "", color: .red, commands: [])
    
    func replaceCommandsSet(at: Int, with element: UARTMacroElement) {
        
    }
}

extension UARTMacro {
    static var walkman: UARTMacro {
        UARTMacro(name: "Walkman", color: .red, commands: [
            TextCommand(text: "Pause", image: .pause),
            TextCommand(text: "Play", image: .play),
            TextCommand(text: "Stop", image: .stop),
            TextCommand(text: "Start", image: .start),
            TextCommand(text: "Repeat", image: .repeat),
            TextCommand(text: "Rew", image: .rewind)
        ])
    }
    
    static var controller: UARTMacro {
        UARTMacro(name: "Controller", color: .blue, commands: [
            TextCommand(text: "Up", image: .up),
            TextCommand(text: "Left", image: .left),
            TextCommand(text: "Down", image: .down),
            TextCommand(text: "Start", image: .start),
            TextCommand(text: "Repeat", image: .repeat),
            TextCommand(text: "Rew", image: .rewind)
        ])
    }
    
    static var numbers: UARTMacro {
        UARTMacro(name: "Numbers", color: .green, commands: [
            DataCommand(data: Data([0x01]), image: .number1),
            DataCommand(data: Data([0x02]), image: .number2),
            DataCommand(data: Data([0x03]), image: .number3),
            DataCommand(data: Data([0x04]), image: .number4),
            DataCommand(data: Data([0x05]), image: .number5),
            DataCommand(data: Data([0x06]), image: .number6),
            DataCommand(data: Data([0x07]), image: .number7),
            DataCommand(data: Data([0x08]), image: .number8),
            DataCommand(data: Data([0x09]), image: .number9),
            DataCommand(data: Data([0x00]), image: .number0)
        ])
    }
}
