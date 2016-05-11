//
//  NOREditPopupViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 11/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

@objc protocol ButtonConfigureDelegate {
    func didConfigureButton(aButton : UIButton, withCommand aCommand : String, andIconIndex index : Int, shouldHide hide : Bool)
}

class NOREditPopupViewController: UIViewController, UITextFieldDelegate {

    //MARK: - Class properties
    var delegate : ButtonConfigureDelegate?
    var command  : String?
    var isHidden : Bool?
    var iconIndex: Int?
    
    //MARK: - View Actions
    @IBAction func toggleVisibilityButtonPressed(sender: AnyObject) {
        self.handleToggleVisibilityButtonPressed()
    }
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.handleCancelButtonPressed()
    }
    @IBAction func okButtonPressed(sender: AnyObject) {
        self.handleOkButtonPressed()
    }
    @IBAction func iconButtonPressed(sender: AnyObject) {
        self.handleIconButtonPressed(sender as! UIButton)
    }
    
    //MARK: - View Outlets
    @IBOutlet var iconButtons: [UIButton]!
    @IBOutlet weak var commandTextField: UITextField!
    @IBOutlet weak var toggleVisibilityButton: UIButton!
    
    //MARK: - UIVIewDelegate
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.isHidden! {
            toggleVisibilityButton.setTitle("Show", forState: UIControlState.Normal)
        }else{
            toggleVisibilityButton.setTitle("Hide", forState: UIControlState.Normal)
        }
        
        print("Oultlet count = \(iconButtons?.count)")
        commandTextField.text = self.command!
        let button = iconButtons[self.iconIndex!]
        button.backgroundColor = UIColor(red: 222.0/255.0, green: 74.0/255.0, blue: 19.0/255.0, alpha: 1.0)
    }
    
    //MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

    //MARK: - View Implementation
    
    //Swift->Obj-C Helpers
    func setIsHidden(aValue: Bool){
        isHidden = aValue
    }
    func setIconIndex(anIndex : Int){
        iconIndex = anIndex
    }

    func handleOkButtonPressed() {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.delegate?.didConfigureButton(iconButtons[self.iconIndex!], withCommand: commandTextField.text!, andIconIndex: self.iconIndex!, shouldHide: self.isHidden!)
    }
    
    func handleCancelButtonPressed() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func handleToggleVisibilityButtonPressed() {
        if isHidden == true {
            isHidden = false
            self.toggleVisibilityButton.setTitle("Hide", forState: UIControlState.Normal)
        }else{
            isHidden = true
            self.toggleVisibilityButton.setTitle("Show", forState: UIControlState.Normal)
        }
    }
    
    func handleIconButtonPressed(sender: UIButton){
        iconIndex = sender.tag-1
        self.setSelectedBackgroundColor()
    }
    
    func setSelectedBackgroundColor() {
        for aButton :UIButton in self.iconButtons {
            aButton.backgroundColor = UIColor(red: 127.0/255.0, green: 127.0/255.0, blue: 127.0/255.0, alpha: 1.0)
        }
        iconButtons[self.iconIndex!].backgroundColor = UIColor(red: 222.0/255.0, green: 74.0/255.0, blue: 19.0/255.0, alpha: 1.0)
    }

}
