//
//  UARTNewCommandViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 15/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class UARTNewCommandViewController: UIViewController {
    
    @IBOutlet private var createButton: NordicButton!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var valueTextField: UITextField!
    @IBOutlet private var typeSegmentControl: UISegmentedControl!
    
    init() {
        super.init(nibName: "UARTNewCommandViewController", bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createButton.style = .mainAction
        navigationItem.title = "Create new command"
        collectionView.register(type: ImageCollectionViewCell.self)
        
        let hexLabel = UILabel()
        hexLabel.text = "0x"
        hexLabel.font = valueTextField.font
        hexLabel.textColor = UIColor.Text.secondarySystemText
        hexLabel.textAlignment = .center
        valueTextField.leftView = hexLabel
        valueTextField.leftViewMode = .never
    }

    @IBAction func typeChanged(_ sender: UISegmentedControl) {
        valueTextField.text = ""
        createButton.isEnabled = false
        valueTextField.leftViewMode = sender.selectedSegmentIndex == 1 ? .always : .never
    }
    
    @IBAction func textChanged(_ sender: UITextField) {
        createButton.isEnabled = !(sender.text?.isEmpty ?? true)
        if typeSegmentControl.selectedSegmentIndex == 1 {
            sender.text = sender.text?.uppercased()
        }
    }
}

extension UARTNewCommandViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let side = collectionView.frame.size.width / 4
        return CGSize(width: side, height: side)
    }
}

extension UARTNewCommandViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return CommandImage.allCases.count
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
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard typeSegmentControl.selectedSegmentIndex == 1 else {
            return true
        }
        
        return CharacterSet(charactersIn: "0123456789abcdefABCDEF").isSuperset(of: CharacterSet(charactersIn: string))
    }
}
