//
//  UARTMacrosEditViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 03/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import UART
import Core

protocol UARTMacroEditCommandProtocol: class {
    func saveMacroUpdate(_ macros: Macros?, commandSet: [MacrosElement], name: String, color: Color)
}

class UARTMacroEditCommandListVC: UITableViewController {
    enum SectionDescriptor {
        case delay(TimeInterval)
        case command(MacrosCommandContainer, Bool)
    }
    
    var elements: [SectionDescriptor] = []
    var macros: Macros?
    
    weak var editCommandDelegate: UARTMacroEditCommandProtocol?
    
    private var headerView: ActionHeaderView!
    
    private var name: String?
    private var color: Color?
    
    private var postponedAction: (() -> ())?
    
    private var sourceIndexPath: IndexPath?
    private var snapshot: UIView?

    init(macros: Macros?) {
        self.macros = macros
        
        self.name = macros?.name
        self.color = macros?.color ?? Color.nordic

        if #available(iOS 13, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
        
        self.elements = macros?.elements.map { self.map(macrosElement: $0) } ?? []
    }
    
    init(commands: [Command]) {
        let containers = commands.map { MacrosCommandContainer(command: $0) }
        self.elements = containers.map {
            SectionDescriptor.command($0, false)
        }
        
        self.macros = .empty
        self.macros?.elements = containers.map { MacrosElement.commandContainer($0) }
        
        self.color = nil
        self.name = nil
        
        if #available(iOS 13, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupNavigationBar()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(sender:)))
        tableView.addGestureRecognizer(longPress)
    }
    
    @objc
    func longPressed(sender: UILongPressGestureRecognizer) {
        let state = sender.state
        let location = sender.location(in: tableView)
        
        guard let indexPath = tableView.indexPathForRow(at: location) else { return }
        
        switch state {
        case .began:
            sourceIndexPath = indexPath
            guard let cell = self.tableView.cellForRow(at: indexPath) else { return }
            snapshot = self.customSnapshotFromView(inputView: cell)
            guard  let snapshot = self.snapshot else { return }
            var center = cell.center
            snapshot.center = center
            snapshot.alpha = 0.0
            tableView.addSubview(snapshot)
            UIView.animate(withDuration: 0.25, animations: {
                center.y = location.y
                snapshot.center = center
                snapshot.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                snapshot.alpha = 0.98
                cell.alpha = 0.0
            }, completion: { (finished) in
                cell.isHidden = true
            })
        case .changed:
            guard  let snapshot = self.snapshot else { return }
            
            var center = snapshot.center
            center.y = location.y
            snapshot.center = center
            guard let sourceIndexPath = self.sourceIndexPath  else {
                return
            }
            if indexPath != sourceIndexPath {
                elements.swapAt(indexPath.section, sourceIndexPath.section)
                tableView.moveSection(sourceIndexPath.section, toSection: indexPath.section)
                
                let cell = tableView.cellForRow(at: indexPath)
                cell?.alpha = 0
                
                self.sourceIndexPath = indexPath
            }
        default:
            guard let cell = self.tableView.cellForRow(at: indexPath) else {
                return
            }
            guard  let snapshot = self.snapshot else {
                return
            }
            cell.isHidden = false
            cell.alpha = 0.0
            UIView.animate(withDuration: 0.25, animations: {
                snapshot.center = cell.center
                snapshot.transform = CGAffineTransform.identity
                snapshot.alpha = 0
                cell.alpha = 1
            }, completion: { (finished) in
                self.cleanup()
            })
        }
    }
    
    private func cleanup() {
        self.sourceIndexPath = nil
        snapshot?.removeFromSuperview()
        self.snapshot = nil
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        elements.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch elements[indexPath.section] {
        case .command(let element, let expanded):
            return self.tableView(tableView, commandCellForRowAt: indexPath, command: element, extended: expanded)
        case .delay(let ti):
            return self.tableView(tableView, timeIntervalCellForRowAt: indexPath, timeInterval: ti)
        }
        
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationItem.title = scrollView.contentOffset.y > -30 ? "Edit Macros Commands" : ""
    }
    
    
}

//MARK: - Private methods
extension UARTMacroEditCommandListVC {
    private func map(macrosElement: MacrosElement) -> SectionDescriptor {
        switch macrosElement {
        case .commandContainer(let container):
            return .command(container, container.repeatCount > 1 && container.delay > 0)
        case .delay(let ti):
            return .delay(ti)
        }
    }
}

//MARK: - Actions
extension UARTMacroEditCommandListVC {
    @IBAction private func save() {
        guard let name = self.name, let color = self.color else {
            editMacros()
            postponedAction = { [weak self] in
                self?.save()
            }
            return
        }
        
        
        let commands: [MacrosElement] = self.elements.map {
            switch $0 {
            case .command(let container, _):
                return .commandContainer(container)
            case .delay(let ti):
                return .delay(ti)
            }
        }
        
        self.editCommandDelegate?.saveMacroUpdate(macros, commandSet: commands, name: name, color: color)
    }
    
    @IBAction private func editMacros() {
        let vc = UARTEditMacrosVC(name: name, color: color)
        vc.editMacrosDelegate = self
        navigationController?.pushViewController(vc, animated: true)
        postponedAction = nil
    }
    
}

//MARK: - Setup UI
extension UARTMacroEditCommandListVC {
    
    private func setupTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.registerCellNib(cell: UARTMacroWaitCell.self)
        tableView.registerCellNib(cell: UARTMacroCommandWrapperCell.self)
        
        tableView.reloadData()
        
        let addView = MacrosAddNewCommand.instance()
        addView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        tableView.tableFooterView = addView
        
        addView.addButtonCallback = { [weak self] in
            self?.addCommand()
        }
    }
    
    private func setupNavigationBar() {
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismsiss))
        let saveItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        
        navigationItem.leftBarButtonItem = cancelItem
        navigationItem.rightBarButtonItem = saveItem
        navigationItem.title = "Edit macros"
        
        headerView = ActionHeaderView.instance()
        headerView.editButtonCallback = {
            self.editMacros()
        }
        
        headerView.frame = CGRect(x: 0, y: 0, width: 100, height: 58)
        tableView.tableHeaderView = headerView
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
    }
    
    private func addCommand() {
        let alert = UIAlertController(title: "Add commond", message: nil, preferredStyle: .actionSheet)
        
        let command = UIAlertAction(title: "Command", style: .default) { [weak self] (_) in
            let vc = UARTNewCommandViewController(command: nil, index: -1)
            vc.delegate = self
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        
        let delay = UIAlertAction(title: "Delay", style: .default) { [weak self] (_) in
            self?.elements.append(.delay(0.1))
            let index = (self?.elements.count).flatMap { $0 - 1 }
            self?.tableView.insertSections([index ?? 0], with: .automatic)
        }
        
        alert.addAction(command)
        alert.addAction(delay)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}

//MARK: - Table View
extension UARTMacroEditCommandListVC {
    private func tableView(_ tableView: UITableView, timeIntervalCellForRowAt indexPath: IndexPath, timeInterval: TimeInterval) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: UARTMacroWaitCell.self)
        
        let milliseconds = Int(timeInterval * 1000)
        cell.intervalLabel.text = "\(milliseconds) milliseconds"
        cell.presentController = { [weak self] label, controller in
            self?.setupAndShowStepper(controller, on: label)
            controller.stepperSetup = (100, 10_000, milliseconds, 100)
        }
        
        cell.timeIntervalChanged = { [weak cell, unowned self] ti in
            self.elements[indexPath.section] = .delay(Double(ti) / 1000.0)
            cell?.intervalLabel.text = "\(ti) milliseconds"
        }
        
        cell.removeAction = { [weak self, weak cell] in
            self?.askForRemoveCell(cell)
        }
        
        return cell
    }
    
    private func tableView(_ tableView: UITableView, commandCellForRowAt indexPath: IndexPath, command: MacrosCommandContainer, extended: Bool) -> UITableViewCell {

        let cell = tableView.dequeueCell(ofType: UARTMacroCommandWrapperCell.self)

        cell.timeIntervalCanged = { [weak self] val in
            guard let `self` = self else { return }
            guard case .command(var container, let exp) = self.elements[indexPath.section] else {
                return
            }
            
            container.delay = val
            
            self.elements[indexPath.section] = .command(container, exp)
        }

        cell.repeatCountCanged = { [weak self] val in
            guard let `self` = self else { return }
            guard case .command(var container, let exp) = self.elements[indexPath.section] else {
                return
            }
            
            container.repeatCount = val
            
            self.elements[indexPath.section] = .command(container, exp)
        }

        cell.expandAction = { [weak self] sender in
            
            guard let `self` = self else { return }
            guard case .command(var container, let exp) = self.elements[indexPath.section] else {
                return
            }
            
            sender.isHighlighted = exp

            self.elements[indexPath.section] = .command(container, !exp)
            tableView.reloadSections([indexPath.section], with: .automatic)
        }
        
        cell.removeCommand = { [weak self, weak cell] in
            self?.askForRemoveCell(cell)
        }

        weak var `self` = self
        cell.setupAndShowStepper = self?.setupAndShowStepper

        cell.apply(command, expanded: extended)
        return cell
    }
    
    private func setupAndShowStepper(_ controller: UARTIncrementViewController, on view: UIView) {
        controller.modalPresentationStyle = .popover
        controller.preferredContentSize = CGSize(width: 110, height: 48)
        
        controller.popoverPresentationController?.sourceView = view
        controller.popoverPresentationController?.permittedArrowDirections = .up
        controller.popoverPresentationController?.delegate = self
        
        self.present(controller, animated: true)
    }

    private func customSnapshotFromView(inputView: UIView) -> UIView? {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0)
        if let CurrentContext = UIGraphicsGetCurrentContext() {
            inputView.layer.render(in: CurrentContext)
        }
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()
        let snapshot = UIImageView(image: image)
        snapshot.layer.masksToBounds = false
        snapshot.layer.cornerRadius = 0
        snapshot.layer.shadowOffset = CGSize(width: -5, height: 0)
        snapshot.layer.shadowRadius = 5
        snapshot.layer.shadowOpacity = 0.4
        return snapshot
    }
    
    private func askForRemoveCell(_ cell: UITableViewCell?) {
        guard let ip = cell.flatMap ({ self.tableView.indexPath(for: $0) }) else { return }
        
        let alert = UIAlertController(title: "Remove command?", message: "Are you sure you want to remove the command?", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.elements.remove(at: ip.section)
            self?.tableView.deleteSections([ip.section], with: .automatic)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
}

extension UARTMacroEditCommandListVC: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}

extension UARTMacroEditCommandListVC: UARTNewCommandDelegate {
    func createdNewCommand(_ viewController: UARTNewCommandViewController, command: Command, index: Int) {
        self.elements.append(.command(MacrosCommandContainer(command: command), false))
        self.tableView.insertSections([elements.count - 1], with: .automatic)
        self.navigationController?.popViewController(animated: true)
    }
}

extension UARTMacroEditCommandListVC: UARTEditMacrosDelegate {
    func saveMacrosUpdate(name: String, color: Color) {
        self.name = name
        self.color = color
        
        if let action = postponedAction {
            action()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    
}
