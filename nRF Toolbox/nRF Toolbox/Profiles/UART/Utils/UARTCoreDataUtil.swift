//
//  UARTCoreDataUtil.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 15.06.2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import CoreData
import UART

class UARTCoreDataUtil {
    
    private let presetsWereSavedKey = "PresetsWereSaved"
    
    enum PresetFilter {
        case all, favorite, notFavorite
    }
    
    let manager: PresetManager
    
    init(presetManager: PresetManager = PresetManager()) {
        self.manager = presetManager
        
        let saved = UserDefaults.standard.bool(forKey: presetsWereSavedKey)
        if saved != true {
            firstSave()
        }
    }
    
    func getPresets(options: PresetFilter) throws -> [Preset] {
        var presets = try manager.loadPresets()
        switch options {
        case .favorite:
            presets = presets.filter { $0.isFavorite }
        case .notFavorite:
            presets = presets.filter { !$0.isFavorite }
        default:
            break
        }
        return presets
    }
}

extension UARTCoreDataUtil {
    private func firstSave() {
        
        try? manager.savePreset(Preset.default)
        try? manager.savePreset(Preset.numbers)
        try? manager.savePreset(Preset.walkman)
        
        UserDefaults.standard.set(true, forKey: presetsWereSavedKey)
    }
}

extension Preset {
    static var `default`: Preset {
        Preset(commands: [
            DataCommand(data: Data([0x01]), image: .number1),
            DataCommand(data: Data([0x02]), image: .number2),
            DataCommand(data: Data([0x03]), image: .number3),
            TextCommand(text: "Pause", image: .pause),
            TextCommand(text: "Play", image: .play),
            TextCommand(text: "Stop", image: .stop),
            TextCommand(text: "Rew", image: .rewind),
            TextCommand(text: "Start", image: .start),
            TextCommand(text: "Repeat", image: .repeat)
        ], name: "Demo", isFavorite: true)
    }
    
    static var numbers: Preset {
        Preset(commands: [
            DataCommand(data: Data([0x01]), image: .number1),
            DataCommand(data: Data([0x02]), image: .number2),
            DataCommand(data: Data([0x03]), image: .number3),
            DataCommand(data: Data([0x04]), image: .number4),
            DataCommand(data: Data([0x05]), image: .number5),
            DataCommand(data: Data([0x06]), image: .number6),
            DataCommand(data: Data([0x07]), image: .number7),
            DataCommand(data: Data([0x08]), image: .number8),
            DataCommand(data: Data([0x09]), image: .number9),
        ], name: "Numbers", isFavorite: false)
    }
    
    static var walkman: Preset {
        Preset(commands: [
            TextCommand(text: "Pause", image: .pause),
            TextCommand(text: "Play", image: .play),
            TextCommand(text: "Stop", image: .stop),
            TextCommand(text: "Start", image: .start),
            EmptyCommand(),
            TextCommand(text: "Repeat", image: .repeat),
            EmptyCommand(),
            TextCommand(text: "Rew", image: .rewind),
            EmptyCommand()
        ], name: "Walkman", isFavorite: true)
    }
    
}

