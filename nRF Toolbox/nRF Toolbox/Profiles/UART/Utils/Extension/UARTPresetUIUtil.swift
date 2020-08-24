//
//  UARTPresetUIUtil.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 30/06/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreData

class UARTPresetUIUtil {
    let stack: CoreDataStack
    
    init(stack: CoreDataStack = .uart) {
        self.stack = stack
    }
    
    func renameAlert(for preset: UARTPreset, onSave: (() -> ())?) -> UIAlertController {
        let alert = UIAlertController(title: "Rename", message: "Rename preset", preferredStyle: .alert)
        
        alert.addTextField { (tf) in
            tf.text = preset.name
            tf.selectAll(nil)
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak alert] (_) in
            let name = alert?.textFields?.first?.text
            preset.name = name
            try! self.stack.viewContext.save()
            
            onSave?()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        return alert
    }
    
    func dupplicatePreset(_ preset:UARTPreset, intoContext context: NSManagedObjectContext?, completion: ((UARTPreset) -> ())?) -> UIAlertController {
        let alert = UIAlertController(title: "Duplicate", message: "Enter new preset's name", preferredStyle: .alert)
        
        alert.addTextField { (tf) in
            tf.placeholder = preset.name.map { $0 + " copy" } ?? "New Preset"
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak alert] (_) in
            
            let name = alert?.textFields?.first?.text?.nilOnEmpty()
                ?? preset.name.map { $0 + " copy" }
                ?? "New Preset"
            let copy = preset.cloneWithName(name, context: context)
            try? context?.save()
            
            completion?(copy)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        return alert
    }
}
