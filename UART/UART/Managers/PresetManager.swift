//
//  PresetManager.swift
//  UART
//
//  Created by Nick Kibysh on 25/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Core
import CoreData

open class PresetManager {
    
    public let storage: CoreDataStack
    
    init(storage: CoreDataStack) {
        self.storage = storage
    }
    
    public init() {
        self.storage = .uart
    }
    
    /// Load all existing presets
    open func loadPresets() throws -> [Preset] {
        let request: NSFetchRequest<PresetObject> = PresetObject.fetchRequest()
        let presetObjects = try storage.viewContext.fetch(request)
        let converter = PresetConverter(stack: storage)
        return presetObjects.map { converter.convert(object: $0) }
    }
    
    /// Save new preset to storage or update existing one.
    /// - Parameters:
    ///   - preset: Preset to be saved
    ///   - update: Declares whether preset will be updated. If the parameter is set to `false` the new preset will be created. If there's no such preset in the storage parameter has no effects and new preset will be saved.
    open func savePreset(_ preset: Preset) throws {
        guard let obj = preset.storedObject else {
            let newObject = PresetConverter(stack: storage).convert(model: preset)
            storage.viewContext.insert(newObject)
            try storage.viewContext.save()
            return
        }
        
        obj.name = preset.name
        obj.isFavorite = preset.isFavorite
        obj.commandSet = preset.commands.compactMap { CommandCoderMethod.coder(for: $0) as? NSObject }
        try storage.viewContext.save()
    }
    
    /// Duplicates provided preset.
    /// - IMPORTANT: The method doesn't save new preset to the storage.
    /// - Parameters:
    ///   - preset: Preset to be copied
    ///   - name: Name of dupplicated preset. If the name is `nil` or the `copy` suffix will be added to original name
    /// - Returns: Dupplicated preset
    open func dupplicatePreset(_ preset: Preset, name: String?) -> Preset {
        var newPreset = preset
        newPreset.storedObject = nil
        
        if let name = name {
            newPreset.name = name
        } else {
            newPreset.name = preset.name + " (copy)"
        }
        
        return newPreset
    }
    
    open func removePreset(_ preset: Preset) throws {
        guard let presetObj = preset.storedObject else {
            return
        }
        
        storage.viewContext.delete(presetObj)
        try storage.viewContext.save()
    }
}
