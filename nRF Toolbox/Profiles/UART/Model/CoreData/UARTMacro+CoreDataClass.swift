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
class UARTMacro: NSManagedObject, NSSecureCoding {
    
    static var supportsSecureCoding: Bool {
        true
    }
    
    func encode(with coder: NSCoder) {
        
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    var commands: [UARTMacroCommandWrapper] {
        elements.compactMap { $0 as? UARTMacroCommandWrapper }
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
        return UARTMacro(name: "Walkman", color: .red, commands: [
            UARTMacroCommandWrapper(command: TextCommand(text: "Pause", image: .pause), repeatCount: 2, timeInterval: 100),
            UARTMacroTimeInterval(milliseconds: 100),
            UARTMacroCommandWrapper(command: TextCommand(text: "Play", image: .play), repeatCount: 1, timeInterval: 100),
            UARTMacroCommandWrapper(command: TextCommand(text: "Stop", image: .stop), repeatCount: 3, timeInterval: 300),
            UARTMacroTimeInterval(milliseconds: 100),
            UARTMacroCommandWrapper(command: TextCommand(text: "Start", image: .start), repeatCount: 1, timeInterval: 500),
            UARTMacroCommandWrapper(command: TextCommand(text: "Repeat", image: .repeat), repeatCount: 2, timeInterval: 100),
            UARTMacroCommandWrapper(command: TextCommand(text: "Rew", image: .rewind), repeatCount: 2, timeInterval: 200)
        ])
    }
    
    static var controller: UARTMacro {
        UARTMacro(name: "Controller", color: .blue, commands: [
            UARTMacroCommandWrapper(command: TextCommand(text: "Up", image: .up), repeatCount: 2, timeInterval: 100),
            UARTMacroCommandWrapper(command: TextCommand(text: "Left", image: .left), repeatCount: 1, timeInterval: 100),
            UARTMacroTimeInterval(milliseconds: 200),
            UARTMacroCommandWrapper(command: TextCommand(text: "Down", image: .down), repeatCount: 3, timeInterval: 300),
            UARTMacroCommandWrapper(command: TextCommand(text: "Start", image: .start), repeatCount: 1, timeInterval: 500),
            UARTMacroTimeInterval(milliseconds: 300),
            UARTMacroCommandWrapper(command: TextCommand(text: "Repeat", image: .repeat), repeatCount: 2, timeInterval: 100),
            UARTMacroCommandWrapper(command: TextCommand(text: "Rew", image: .rewind), repeatCount: 2, timeInterval: 200)
        ])
    }
    
    static var numbers: UARTMacro {
        UARTMacro(name: "Numbers", color: .green, commands: [
            UARTMacroCommandWrapper(command: DataCommand(data: Data([0x01]), image: .number1), repeatCount: 2, timeInterval: 100),
            UARTMacroCommandWrapper(command: DataCommand(data: Data([0x02]), image: .number2), repeatCount: 1, timeInterval: 100),
            UARTMacroCommandWrapper(command: DataCommand(data: Data([0x03]), image: .number3), repeatCount: 3, timeInterval: 300),
            UARTMacroCommandWrapper(command: DataCommand(data: Data([0x04]), image: .number4), repeatCount: 1, timeInterval: 500),
            UARTMacroTimeInterval(milliseconds: 1000),
            UARTMacroCommandWrapper(command: DataCommand(data: Data([0x05]), image: .number5), repeatCount: 2, timeInterval: 100),
            UARTMacroCommandWrapper(command: DataCommand(data: Data([0x06]), image: .number6), repeatCount: 2, timeInterval: 200),
            UARTMacroCommandWrapper(command: DataCommand(data: Data([0x07]), image: .number7), repeatCount: 2, timeInterval: 100),
            UARTMacroTimeInterval(milliseconds: 10_000),
            UARTMacroCommandWrapper(command: DataCommand(data: Data([0x08]), image: .number8), repeatCount: 1, timeInterval: 100),
            UARTMacroCommandWrapper(command: DataCommand(data: Data([0x09]), image: .number9), repeatCount: 3, timeInterval: 300),
            UARTMacroCommandWrapper(command: DataCommand(data: Data([0x00]), image: .number0), repeatCount: 1, timeInterval: 500)
        ])
    }
}
