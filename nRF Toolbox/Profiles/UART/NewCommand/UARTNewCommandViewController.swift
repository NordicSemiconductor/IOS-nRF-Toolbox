//
//  UARTNewCommandViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 15/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol UARTNewCommandDelegate: class {
    func createdNewCommand(_ viewController: UARTNewCommandViewController, command: UARTCommandModel, index: Int)
}

class UARTNewCommandViewController: UIViewController {
    
    @IBOutlet private var createButton: NordicButton!
    @IBOutlet private var deleteButton: NordicButton!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var valueTextField: UITextField!
    @IBOutlet private var typeSegmentControl: UISegmentedControl!
    
    weak var delegate: UARTNewCommandDelegate?
    
    private var command: UARTCommandModel?
    private var index: Int
    
    init(command: UARTCommandModel?, index: Int) {
        self.command = command
        self.index = index
        super.init(nibName: "UARTNewCommandViewController", bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        Log(category: .app, type: .fault).fault("required init?(coder: NSCoder) is not implemented for UARTNewCommandViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        }
        
        setupTextField()
        createButton.style = .mainAction
        navigationItem.title = "Create new command"
        collectionView.register(type: ImageCollectionViewCell.self)
        
        command.map { self.setupUI(with: $0) }
    }

    @IBAction func typeChanged(_ sender: UISegmentedControl) {
        valueTextField.text = ""
        updateButtonState()
        valueTextField.leftViewMode = sender.selectedSegmentIndex == 1 ? .always : .never
    }
    
    @IBAction func textChanged(_ sender: UITextField) {
        updateButtonState()
    }
    
    @IBAction func createCommand() {
        let command: UARTCommandModel
        let selectedItem = (collectionView.indexPathsForSelectedItems?.first?.item)!
        let image = CommandImage.allCases[selectedItem]
        
        if typeSegmentControl.selectedSegmentIndex == 0 {
            command = TextCommand(text: valueTextField.text!, image: image)
        } else {
            command = DataCommand(data: Data(valueTextField.text!.hexa), image: image)
        }
        
        delegate?.createdNewCommand(self, command: command, index: index)
    }
    
    @IBAction func deleteBtnPressed() {
        delegate?.createdNewCommand(self, command: EmptyModel(), index: index)
    }
}

extension UARTNewCommandViewController {
    private func setupUI(with command: UARTCommandModel) {
        let typeIndex: Int
        let title: String
        switch command {
        case is TextCommand:
            typeIndex = 0
            title = command.title
        case is DataCommand:
            typeIndex = 1
            title = command.data.hexEncodedString().uppercased()
        default:
            return
        }
        
        typeSegmentControl.selectedSegmentIndex = typeIndex
        typeChanged(typeSegmentControl)
        
        valueTextField.text = title
        CommandImage.allCases.enumerated()
            .first(where: { $0.element.name == command.image.name })
            .map { self.collectionView.selectItem(at: IndexPath(item: $0.offset, section: 0), animated: false, scrollPosition: .top) }
        
        deleteButton.isHidden = false
        deleteButton.style = .destructive
        
        createButton.setTitle("Save", for: .normal)
    }
    
    private func updateButtonState() {
        createButton.isEnabled = !(valueTextField.text?.isEmpty ?? true) && collectionView.indexPathsForSelectedItems?.first != nil
    }
    
    private func setupTextField() {
        let hexLabel = UILabel()
        hexLabel.text = "0x"
        hexLabel.font = valueTextField.font
        hexLabel.textColor = UIColor.Text.secondarySystemText
        hexLabel.textAlignment = .center
        valueTextField.leftView = hexLabel
        valueTextField.leftViewMode = .never
    }
}

extension UARTNewCommandViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateButtonState()
        valueTextField.resignFirstResponder()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let side = collectionView.frame.size.width / 3 - 6
        return CGSize(width: side, height: side)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        8
    }
}

extension UARTNewCommandViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        CommandImage.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let img = CommandImage.allCases[indexPath.item]
        let cell = collectionView.dequeueCell(ofType: ImageCollectionViewCell.self, for: indexPath)
        cell.imageView.image = img.image?.withRenderingMode(.alwaysTemplate)
        return cell
    }
}

extension UARTNewCommandViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard typeSegmentControl.selectedSegmentIndex == 1 else {
            return true
        }
        
        return CharacterSet(charactersIn: "0123456789abcdefABCDEF").isSuperset(of: CharacterSet(charactersIn: string))
    }
}
