//
//  PresetManager.swift
//  UART
//
//  Created by Nick Kibysh on 25/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import Core

open class PresetManager {
    
    public init(storage: CoreDataStack) {
        
    }
    
    /// Load all existing presets
    open func loadPresets() -> [Preset] {
        return []
    }
    
    /// Save new preset to storage or update existing one.
    /// - Parameters:
    ///   - preset: Preset to be saved
    ///   - update: Declares whether preset will be updated. If the parameter is set to `false` the new preset will be created. If there's no such preset in the storage parameter has no effects and new preset will be saved.
    open func savePreset(_ preset: Preset, update: Bool = false) throws {
        
    }
    
    /// Duplicates provided preset.
    /// - IMPORTANT: The method doesn't save new preset to the storage.
    /// - Parameters:
    ///   - preset: Preset to be copied
    ///   - name: Name of dupplicated preset. If the name is `nil` or the `copy` suffix will be added to original name
    /// - Returns: Dupplicated preset
    open func dupplicatePreset(_ preset: Preset, name: String?) -> Preset {
        return preset
    }
}
