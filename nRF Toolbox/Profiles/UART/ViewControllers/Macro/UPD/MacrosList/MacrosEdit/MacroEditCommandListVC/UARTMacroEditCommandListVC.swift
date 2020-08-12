//
//  UARTMacrosEditViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 03/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol UARTMacroEditCommandProtocol: class {
    func saveMacroUpdate(_ macros: UARTMacro?, commandSet: [UARTMacroElement], name: String, color: UARTColor)
}

struct CommandWrapper {
    var element: UARTMacroCommandWrapper
    var expanded: Bool = true
    var repeatEnabled: Bool = true
    var timeIntervalEnabled: Bool = true
}

private protocol SectionDescriptor { }
extension UARTMacroTimeInterval: SectionDescriptor { }
extension CommandWrapper: SectionDescriptor { }

class UARTMacroEditCommandListVC: UITableViewController {
    
    let macros: UARTMacro?
    
    weak var editCommandDelegate: UARTMacroEditCommandProtocol?
    
    private var elements: [SectionDescriptor]
    private var headerView: ActionHeaderView!
    
    private var name: String?
    private var color: UARTColor?
    
    private var postponedAction: (() -> ())?

    init(macros: UARTMacro?) {
        self.macros = macros
        self.elements = macros?.elements.compactMap {
            switch $0 {
            case let c as UARTMacroCommandWrapper:
                return CommandWrapper(element: c, expanded: c.repeatCount > 1)
            case let ti as UARTMacroTimeInterval:
                return ti
            default:
                return nil
            }
        } ?? []
        
        self.name = macros?.name
        self.color = macros?.color

        if #available(iOS 13, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }
    
    init(commonds: [UARTMacroElement]) {
        self.elements = commonds.compactMap {
            switch $0 {
            case let c as UARTMacroCommandWrapper:
                return CommandWrapper(element: c, expanded: c.repeatCount > 1)
            case let command as UARTCommandModel:
                return CommandWrapper(element: UARTMacroCommandWrapper(command: command), expanded: false)
            case let ti as UARTMacroTimeInterval:
                return ti
            default:
                return nil
            }
        }
        
        self.macros = nil
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
    
    private var sourceIndexPath: IndexPath?
    private var snapshot: UIView?
    
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
        case let e as CommandWrapper:
            return self.tableView(tableView, commandCellForRowAt: indexPath, command: e)
        case let ti as UARTMacroTimeInterval:
            return self.tableView(tableView, timeIntervalCellForRowAt: indexPath, timeInterval: ti)
        default:
            SystemLog.fault("Unknown command type", category: .app)
        }
        
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationItem.title = scrollView.contentOffset.y > -30 ? "Edit Macros Commands" : ""
    }
    
    
}

extension UARTMacroEditCommandListVC {
    @IBAction private func save() {
        guard let name = self.name, let color = self.color else {
            editMacros()
            postponedAction = { [weak self] in
                self?.save()
            }
            return
        }
        
        
        let commands: [UARTMacroElement] = self.elements.compactMap {
            switch $0 {
            case let ti as UARTMacroTimeInterval: return ti
            case let command as CommandWrapper: return command.element
            default: return nil
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
            let vc = UARTNewCommandViewController(command: nil, index: -1)
            vc.delegate = self
            self?.navigationController?.pushViewController(vc, animated: true)
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
}

//MARK: - Table View
extension UARTMacroEditCommandListVC {
    private func tableView(_ tableView: UITableView, timeIntervalCellForRowAt indexPath: IndexPath, timeInterval: UARTMacroTimeInterval) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: UARTMacroWaitCell.self)
        
        let milliseconds = Int(timeInterval.timeInterval * 1000)
        cell.intervalLabel.text = "\(milliseconds) milliseconds"
        cell.presentController = { [weak self] label, controller in
            self?.setupAndShowStepper(controller, on: label)
            controller.stepperSetup = (100, 10_000, milliseconds, 100)
        }
        
        cell.timeIntervalChanged = { [weak cell, unowned self] ti in
            
            (self.elements[indexPath.section] as! UARTMacroTimeInterval).timeInterval = Double(ti) / 1000.0
            cell?.intervalLabel.text = "\(ti) milliseconds"
        }
        
        return cell
    }
    
    private func tableView(_ tableView: UITableView, commandCellForRowAt indexPath: IndexPath, command: CommandWrapper) -> UITableViewCell {

        let cell = tableView.dequeueCell(ofType: UARTMacroCommandWrapperCell.self)

        cell.timeIntervalCanged = { [weak self] val in
            (self?.elements[indexPath.section] as! CommandWrapper).element.timeInterval = val
        }

        cell.repeatCountCanged = { [weak self] val in
            (self?.elements[indexPath.section] as! CommandWrapper).element.repeatCount = val
        }

        cell.expandAction = { [weak self] sender in
            guard var command = self?.elements[indexPath.section] as? CommandWrapper else {
                return
            }

            command.expanded.toggle()
            sender.isHighlighted = command.expanded

            self?.elements[indexPath.section] = command
            tableView.reloadSections([indexPath.section], with: .automatic)
        }

        weak var `self` = self
        cell.setupAndShowStepper = self?.setupAndShowStepper

        cell.apply(command)
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
}

extension UARTMacroEditCommandListVC: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}

extension UARTMacroEditCommandListVC: UARTNewCommandDelegate {
    func createdNewCommand(_ viewController: UARTNewCommandViewController, command: UARTCommandModel, index: Int) {
        self.elements.append(CommandWrapper(element: UARTMacroCommandWrapper(command: command), expanded: false))
        self.tableView.insertSections([elements.count - 1], with: .automatic)
        self.navigationController?.popViewController(animated: true)
    }
}

extension UARTMacroEditCommandListVC: UARTEditMacrosDelegate {
    func saveMacrosUpdate(name: String, color: UARTColor) {
        self.name = name
        self.color = color
        
        if let action = postponedAction {
            action()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    
}
