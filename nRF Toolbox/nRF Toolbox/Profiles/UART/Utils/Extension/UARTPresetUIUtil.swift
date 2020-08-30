//
//  UARTPresetUIUtil.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 30/06/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreData
import Core
import UART

class UARTPresetUIUtil {
    let presetManager: PresetManager
    
    init(presetManager: PresetManager) {
        self.presetManager = presetManager
    }
    
    func renameAlert(for preset: Preset, onSave: (() -> ())?) -> UIAlertController {
        let alert = UIAlertController(title: "Rename", message: "Rename preset", preferredStyle: .alert)
        
        alert.addTextField { (tf) in
            tf.text = preset.name
            tf.selectAll(nil)
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak alert] (_) in
            var newPreset = preset
            newPreset.name = alert?.textFields?.first?.text ?? ""
            try? self.presetManager.savePreset(newPreset)
            
            onSave?()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        return alert
    }
    
    func dupplicatePreset(_ preset: Preset, completion: ((Preset) -> ())?) -> UIAlertController {
        let alert = UIAlertController(title: "Duplicate", message: "Enter new preset's name", preferredStyle: .alert)
        
        alert.addTextField { (tf) in
            tf.placeholder = preset.name + " copy"
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak alert] (_) in
            
            let name = alert?.textFields?.first?.text?.nilOnEmpty()
            let copy = self.presetManager.dupplicatePreset(preset, name: name)
            try? self.presetManager.savePreset(copy)
            
            completion?(copy)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        return alert
    }
}
