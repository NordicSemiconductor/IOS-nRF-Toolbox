//
//  UARTMacrosEditViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 03/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTMacrosEditViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerCellNib(cell: UARTMacroCommandCell.self)
        tableView.registerCellNib(cell: UARTMacroRepeatCommandCell.self)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return tableView.dequeueCell(ofType: UARTMacroCommandCell.self)
        } else {
            let cell = tableView.dequeueCell(ofType: UARTMacroRepeatCommandCell.self)
            
            cell.argument.labelDidPressed = { label in
                let vc = UARTIncrementViewController()
                vc.modalPresentationStyle = .popover
                vc.preferredContentSize = CGSize(width: 110, height: 48)
                vc.popoverPresentationController?.delegate = self
                vc.popoverPresentationController?.sourceView = label
                vc.popoverPresentationController?.permittedArrowDirections = .up
                
                self.present(vc, animated: true, completion:nil)
            }
            
            return cell
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // return UIModalPresentationStyle.FullScreen
        return UIModalPresentationStyle.none
    }
}
