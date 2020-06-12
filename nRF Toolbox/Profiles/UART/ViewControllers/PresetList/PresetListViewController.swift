//
//  PresetListViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 08/06/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreData

protocol PresetListDelegate: class {
    func didSelectPreset(_ preset: UARTPreset)
}

class PresetListViewController: UITableViewController {
    
    private let coreDataStack: CoreDataStack
    private var presets: [UARTPreset] = []
    
    weak var presetDelegate: PresetListDelegate?
    
    init(stack: CoreDataStack = CoreDataStack.uart) {
        self.coreDataStack = stack
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.coreDataStack = CoreDataStack.uart
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presets = getPresetList()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    private func getPresetList() -> [UARTPreset] {
        let request: NSFetchRequest<UARTPreset> = UARTPreset.fetchRequest()
        return try! coreDataStack.viewContext.fetch(request)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        let preset = presets[indexPath.row]
        cell.textLabel?.text = preset.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presetDelegate?.didSelectPreset(presets[indexPath.row])
    }
    
}
