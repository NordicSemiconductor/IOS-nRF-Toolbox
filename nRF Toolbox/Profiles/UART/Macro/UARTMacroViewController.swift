//
//  UARTMacroViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 17/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTMacroViewController: UIViewController {

    private let commandsList: [UARTCommandModel]
    private let btManager: BluetoothManager

    @IBOutlet var commandListCollectionView: UARTCommandListCollectionView!
    @IBOutlet var commandOrderTableView: UITableView!
    @IBOutlet var timeStepper: UIStepper!
    @IBOutlet var playBtn: NordicButton!
    @IBOutlet var timeLabel: UILabel!
    
    private var macros: [UARTCommandModel] = []
    
    private lazy var dispatchSource = DispatchSource.makeTimerSource(queue: .main)
    
    init(bluetoothManager: BluetoothManager, commandsList: [UARTCommandModel]) {
        self.btManager = bluetoothManager
        self.commandsList = commandsList
        super.init(nibName: "UARTMacroViewController", bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commandOrderTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        commandListCollectionView.commands = commandsList
        commandListCollectionView.commandListDelegate = self 
    }
    
    func setCommandList(_ commands: [UARTCommandModel]) {
        commandListCollectionView.commands = commands
    }
    
    @IBAction func play() {
        var itorator = macros.makeIterator()
        
    }
    
    @IBAction func timeStep(sender: UIStepper) {
        timeLabel.text = "\(Int(sender.value)) ms"
    }

}

extension UARTMacroViewController: UARTCommandListDelegate {
    func selectedCommand(_ command: UARTCommandModel) {
        guard !(command is EmptyModel) else { return }
        macros.append(command)
        commandOrderTableView.insertRows(at: [IndexPath(row: macros.count - 1, section: 0)], with: .automatic)
    }
}

extension UARTMacroViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        macros.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let command = macros[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        cell?.textLabel?.text = command.title
        cell?.imageView?.image = command.image.image?.withRenderingMode(.alwaysTemplate)
        cell?.imageView?.tintColor = .nordicBlue
        return cell!
    }
    
    
}
