//
//  UARTMacrosEditViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 03/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTMacrosEditViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerCellNib(cell: UARTMacroCommandCell.self)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueCell(ofType: UARTMacroCommandCell.self)
    }
}
