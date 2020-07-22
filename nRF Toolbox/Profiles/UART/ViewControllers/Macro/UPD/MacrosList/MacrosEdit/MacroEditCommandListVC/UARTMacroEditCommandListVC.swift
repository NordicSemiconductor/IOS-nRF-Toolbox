//
//  UARTMacrosEditViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 03/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

private protocol SectionDescriptor { }

extension UARTMacroTimeInterval: SectionDescriptor { }

private struct CommandWrapper: SectionDescriptor {
    var element: UARTMacroCommandWrapper
    var expanded: Bool = true
    var repeatEnabled: Bool = true
    var timeIntervalEnabled: Bool = true
}

class UARTMacroEditCommandListVC: UITableViewController {
    
    let macros: UARTMacro
    private var elements: [SectionDescriptor]
    
    private var navBarEditButton: UIButton!

    init(macros: UARTMacro) {
        self.macros = macros
        self.elements = macros.elements.compactMap {
            switch $0 {
            case let c as UARTMacroCommandWrapper:
                return CommandWrapper(element: c, expanded: c.repeatCount > 1)
            case let ti as UARTMacroTimeInterval:
                return ti
            default:
                return nil
            }
        }

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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navBarEditButton.isHidden = false
        (navigationController?.navigationBar.frame.height).map { self.setVisibleNavigationButton(for: $0) }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navBarEditButton.isHidden = true
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        elements.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let command = self.elements[section] as? CommandWrapper else {
            return 1
        }
        return command.expanded ? 3 : 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch elements[indexPath.section] {
        case let e as CommandWrapper:
            return self.tableView(tableView, commandCellForRowAt: indexPath, command: e)
        case let ti as UARTMacroTimeInterval:
            return self.tableView(tableView, timeIntervalCellForRowAt: indexPath, timeInterval: ti)
        default:
            fatalError()
        }
        
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let height = navigationController?.navigationBar.frame.height else { return }
        setVisibleNavigationButton(for: height)
    }
        
}

extension UARTMacroEditCommandListVC {
    @IBAction private func save() {
        
    }
    
    @IBAction private func editMacros() {
        let vc = UARTEditMacrosVC(macros: self.macros)
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

//MARK: - Setup UI
extension UARTMacroEditCommandListVC {
    private struct SizeConst {
        static let imageSizeForLargeState: CGFloat = 40
        static let imageRightMargin: CGFloat = 16
        static let imageBottomMarginForLargeState: CGFloat = 26
        static let navBarHeightLargeState: CGFloat = 96.5
        static let navBarHeightSmallState: CGFloat = 80
    }
    
    private func setupTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.registerCellNib(cell: UARTMacroCommandCell.self)
        tableView.registerCellNib(cell: UARTMacroRepeatCommandCell.self)
        tableView.registerCellNib(cell: UARTMacroWaitCell.self)
        tableView.reloadData()
        
        let addView = MacrosAddNewCommand.instance()
        addView.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
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
        
        navBarEditButton = UIButton()
        navBarEditButton.addTarget(self, action: #selector(editMacros), for: .touchUpInside)
        if #available(iOS 13, *) {
            navBarEditButton.setImage(ModernIcon.plus(.circle)(.fill).image, for: .normal)
            navBarEditButton.tintColor = .nordicLake
            navBarEditButton.contentHorizontalAlignment = .fill
            navBarEditButton.contentVerticalAlignment = .fill
        }
        
        guard let navigationBar = navigationController?.navigationBar else {
            return
        }
        
        navigationBar.addSubview(navBarEditButton)
        
        navBarEditButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            navBarEditButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor, constant: SizeConst.imageBottomMarginForLargeState),
            navBarEditButton.rightAnchor.constraint(equalTo: navigationBar.rightAnchor, constant: -SizeConst.imageRightMargin),
            navBarEditButton.heightAnchor.constraint(equalToConstant: SizeConst.imageSizeForLargeState),
            navBarEditButton.widthAnchor.constraint(equalTo: navBarEditButton.heightAnchor)
        ])
    }
    
    private func setVisibleNavigationButton(for height: CGFloat) {
        let maxDiff = SizeConst.navBarHeightLargeState - SizeConst.navBarHeightSmallState
        let diff = SizeConst.navBarHeightLargeState - height
        let alpha = 1 - (diff / maxDiff)
        navBarEditButton.alpha = alpha
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

        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueCell(ofType: UARTMacroCommandCell.self)
            cell.apply(command.element.command)
            
            cell.expandAction = { [weak self] sender in
                guard var command = self?.elements[indexPath.section] as? CommandWrapper else {
                    return
                }
                
                command.expanded.toggle()
                sender.isHighlighted = command.expanded
                
                self?.elements[indexPath.section] = command
                tableView.reloadSections([indexPath.section], with: .automatic)
            }
            
            return cell
        case 1:
            return self.tableView(tableView, repeatCellForRowAt: indexPath, command: command)
        case 2:
            return self.tableView(tableView, tiCellForRowAt: indexPath, command: command)
        default:
            fatalError()
        }
    }

    private func tableView(_ tableView: UITableView, repeatCellForRowAt indexPath: IndexPath, command: CommandWrapper) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: UARTMacroRepeatCommandCell.self)
        cell.title.text = "Repeat"
        cell.argument.text = "\(command.element.repeatCount) times"
        cell.argument.labelDidPressed = { [weak self] label, controller in
            self?.setupAndShowStepper(controller, on: label)
            controller.stepperSetup = (1, 100, command.element.repeatCount, 1)
        }

        cell.argument.stepperValueChanged = { [weak cell] val in
            cell?.argument.text = "\(val) times"
            (self.elements[indexPath.section] as! CommandWrapper).element.repeatCount = val
        }
        
        return cell
    }

    private func tableView(_ tableView: UITableView, tiCellForRowAt indexPath: IndexPath, command: CommandWrapper) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: UARTMacroRepeatCommandCell.self)
        cell.title.text = "Time Interval"
        cell.argument.text = "\(command.element.timeInterval) milliseconds"
        cell.argument.labelDidPressed = { [weak self] label, controller in
            self?.setupAndShowStepper(controller, on: label)
            controller.stepperSetup = (100, 10_000, command.element.timeInterval, 100)
        }

        cell.argument.stepperValueChanged = { [weak cell] val in
            cell?.argument.text = "\(val) milliseconds"
            (self.elements[indexPath.section] as! CommandWrapper).element.timeInterval = val
        }
        
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
