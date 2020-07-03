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
class
        UARTPreset: NSManagedObject {
    
    var isEmpty: Bool {
        self.commands.reduce(true) { $0 && ($1 is EmptyModel) }
    }
    
    var commands: [UARTCommandModel] {
        get {
            commandSet.compactMap { $0 as? UARTCommandModel }
        }
        set {
            commandSet = newValue.compactMap { $0 as? NSObject }
        }
    }
    
    subscript(index: Int) -> UARTCommandModel {
        get {
            commandSet[index] as! UARTCommandModel
        }
        set(newValue) {
            commandSet[index] = newValue as! NSObject
        }
    }
    
    init(commands: [UARTCommandModel], name: String, isFavorite: Bool = false, context: NSManagedObjectContext? = CoreDataStack.uart.viewContext) {
        if let entity = context.flatMap({ Self.getEntity(context: $0) }) {
            super.init(entity: entity, insertInto: context)
        } else {
            super.init()
        }
        self.commands = commands
        self.name = name
        self.isFavorite = isFavorite
    }
    
    private func updateCommands(commands: [UARTCommandModel]) {
        self.commandSet.removeAll()
        self.commandSet += commands.compactMap { $0 as? NSObject }
    }
    
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
    }
    
    public override func willSave() {
        super.willSave()
    }
    
    func updateCommand(_ command: UARTCommandModel, at index: Int) {
        commandSet[index] = command as! NSObject
    }
    
    func cloneWithName(_ name: String, context: NSManagedObjectContext?) -> UARTPreset {
        let copiedCommands = self.commands.map { $0.clone() }
        let newPreset = UARTPreset(commands: copiedCommands, name: name, isFavorite: false, context: context)
        return newPreset
    }
}

extension UARTPreset {
    static var empty: UARTPreset {
        UARTPreset(commands: Array(repeating: EmptyModel(), count: 9), name: "")
    }
    
    static func fetchFavorite(isFavorite: Bool = true, stack: CoreDataStack = .uart) throws -> [UARTPreset] {
        let fRequest: NSFetchRequest<UARTPreset> = UARTPreset.fetchRequest()
        fRequest.predicate = NSPredicate(format: "isFavorite", isFavorite)
        
        return try stack.viewContext.fetch(fRequest)
    }
}
