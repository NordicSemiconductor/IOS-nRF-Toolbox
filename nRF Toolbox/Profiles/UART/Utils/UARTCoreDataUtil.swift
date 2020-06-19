//
//  UARTCoreDataUtil.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 15.06.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import CoreData

class UARTCoreDataUtil {
    
    private let presetsWereSavedKey = "PresetsWereSaved"
    
    enum PresetFilter {
        case all, favorite, notFavorite
    }
    
    let stack: CoreDataStack
    
    init(stack: CoreDataStack = .uart) {
        self.stack = stack
        
        let saved = UserDefaults.standard.bool(forKey: presetsWereSavedKey)
        if saved != true {
            firstSave()
        }
    }
    
    func getPresets(options: PresetFilter) throws -> [UARTPreset] {
        let request: NSFetchRequest<UARTPreset> = UARTPreset.fetchRequest()
        
        switch options {
        case .favorite:
            request.predicate = NSPredicate(format: "isFavorite == $@", "YES")
        case .notFavorite:
            request.predicate = NSPredicate(format: "isFavorite == $@", "NO")
        case .all:
            break
        }
        
        let context = stack.viewContext
        let presets = try context.fetch(request)
        return presets
    }
}

extension UARTCoreDataUtil {
    private func firstSave() {
        stack.viewContext.insert(UARTPreset.default)
        stack.viewContext.insert(UARTPreset.walkman)
        stack.viewContext.insert(UARTPreset.numbers)
        
        try! stack.viewContext.save()
        
        UserDefaults.standard.set(true, forKey: presetsWereSavedKey)
    }
}

extension UARTPreset {
    static var `default`: UARTPreset {
        UARTPreset(commands: [
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
    }
    
    static var numbers: UARTPreset {
        UARTPreset(commands: [
            DataCommand(data: Data([0x01]), image: .number1),
            DataCommand(data: Data([0x02]), image: .number2),
            DataCommand(data: Data([0x03]), image: .number3),
            DataCommand(data: Data([0x04]), image: .number4),
            DataCommand(data: Data([0x05]), image: .number5),
            DataCommand(data: Data([0x06]), image: .number6),
            DataCommand(data: Data([0x07]), image: .number7),
            DataCommand(data: Data([0x08]), image: .number8),
            DataCommand(data: Data([0x09]), image: .number9),
        ], name: "Numbers")
    }
    
    static  var walkman: UARTPreset {
        UARTPreset(commands: [
            TextCommand(text: "Pause", image: .pause),
            TextCommand(text: "Play", image: .play),
            TextCommand(text: "Stop", image: .stop),
            TextCommand(text: "Start", image: .start),
            EmptyModel(),
            TextCommand(text: "Repeat", image: .repeat),
            EmptyModel(),
            TextCommand(text: "Rew", image: .rewind),
            EmptyModel()
        ], name: "Walkman")
    }
    
}

