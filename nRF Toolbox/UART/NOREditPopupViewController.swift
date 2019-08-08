//
//  NOREditPopupViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 11/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

@objc protocol ButtonConfigureDelegate {
    func didConfigureButton(_ aButton : UIButton, withCommand aCommand : String, andIconIndex index : Int, shouldHide hide : Bool)
}

class NOREditPopupViewController: UIViewController, UITextFieldDelegate {

    //MARK: - Class properties
    var delegate : ButtonConfigureDelegate?
    var command  : String?
    var isHidden : Bool?
    var iconIndex: Int?
    
    //MARK: - View Actions
    @IBAction func toggleVisibilityButtonPressed(_ sender: AnyObject) {
        handleToggleVisibilityButtonPressed()
    }
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        handleCancelButtonPressed()
    }
    @IBAction func okButtonPressed(_ sender: AnyObject) {
        handleOkButtonPressed()
    }
    @IBAction func iconButtonPressed(_ sender: AnyObject) {
        handleIconButtonPressed(sender as! UIButton)
    }
    
    //MARK: - View Outlets
    @IBOutlet var iconButtons: [UIButton]!
    @IBOutlet weak var commandTextField: UITextField!
    @IBOutlet weak var toggleVisibilityButton: UIButton!
    
    //MARK: - UIViewDelegate
    override func viewDidLoad() {
        super.viewDidLoad()
        if isHidden! {
            toggleVisibilityButton.setTitle("Show", for: .normal)
        } else {
            toggleVisibilityButton.setTitle("Hide", for: .normal)
        }

        commandTextField.text = self.command!
        let button = iconButtons[self.iconIndex!]
        button.backgroundColor = .nordicLake
    }
    
    //MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

    //MARK: - View Implementation
    
    //Swift->Obj-C Helpers
    func setIsHidden(_ aValue: Bool){
        isHidden = aValue
    }
    func setIconIndex(_ anIndex : Int){
        iconIndex = anIndex
    }

    func handleOkButtonPressed() {
        dismiss(animated: true)
        delegate?.didConfigureButton(iconButtons[iconIndex!],
                                     withCommand: commandTextField.text!,
                                     andIconIndex: iconIndex!,
                                     shouldHide: isHidden!)
    }
    
    func handleCancelButtonPressed() {
        dismiss(animated: true)
    }
    
    func handleToggleVisibilityButtonPressed() {
        if isHidden == true {
            isHidden = false
            toggleVisibilityButton.setTitle("Hide", for: .normal)
        }else{
            isHidden = true
            toggleVisibilityButton.setTitle("Show", for: .normal)
        }
    }
    
    func handleIconButtonPressed(_ sender: UIButton){
        iconIndex = sender.tag - 1
        setSelectedBackgroundColor()
    }
    
    func setSelectedBackgroundColor() {
        for aButton: UIButton in iconButtons {
            aButton.backgroundColor = .nordicMediumGray
        }
        iconButtons[iconIndex!].backgroundColor = .nordicLake
    }

}
