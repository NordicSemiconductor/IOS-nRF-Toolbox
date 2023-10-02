/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



import UIKit

protocol UARTNewCommandDelegate: AnyObject {
    func createdNewCommand(_ viewController: UARTNewCommandViewController, command: UARTCommandModel, index: Int)
}

class UARTNewCommandViewController: UIViewController {
    
    @IBOutlet private var createButton: NordicButton!
    @IBOutlet private var deleteButton: NordicButton!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var valueTextField: UITextField!
    @IBOutlet private var typeSegmentControl: UISegmentedControl!
    
    @IBOutlet private var textView: AutoReszableTextView!
    @IBOutlet private var eolLabel: UILabel!
    @IBOutlet private var eolSegment: UISegmentedControl!
    
    weak var delegate: UARTNewCommandDelegate?
    
    private var command: UARTCommandModel?
    private var index: Int
    
    private let CR: UInt8 = 0x0D
    private let LF: UInt8 = 0x0A
    
    init(command: UARTCommandModel?, index: Int) {
        self.command = command
        self.index = index
        super.init(nibName: "UARTNewCommandViewController", bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        SystemLog(category: .app, type: .fault).fault("required init?(coder: NSCoder) is not implemented for UARTNewCommandViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        }
        
        setupTextField()
        setupTextView()
        createButton.style = .mainAction
        navigationItem.title = "Create new command"
        collectionView.register(type: ImageCollectionViewCell.self)
        
        command.map { self.setupUI(with: $0) }

        if #available(iOS 13, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismsiss))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(dismsiss))
        }
    }

    @IBAction func typeChanged(_ sender: UISegmentedControl) {
        // textField.isHidden, textView.isHidden, eolLabel.isHidden, eolSegment.isHidden
        let hiddenOptions: (Bool, Bool, Bool, Bool)
        
        if sender.selectedSegmentIndex == 0 {
            hiddenOptions = (true, false, false, false )
        } else {
            hiddenOptions = (false, true, true, true )
        }
        
        valueTextField.isHidden = hiddenOptions.0
        textView.isHidden = hiddenOptions.1
        eolLabel.isHidden = hiddenOptions.2
        eolSegment.isHidden = hiddenOptions.3
        
        createButton.isEnabled = readyForCreate()
        
        textView.resignFirstResponder()
        valueTextField.resignFirstResponder()
    }
    
    @IBAction func textChanged(_ sender: Any) {
        createButton.isEnabled = readyForCreate()
    }
    
    @IBAction func createCommand() {
        let command: UARTCommandModel
        let selectedItem = (collectionView.indexPathsForSelectedItems?.first?.item)!
        let image = CommandImage.allCases[selectedItem]
        
        if typeSegmentControl.selectedSegmentIndex == 0 {
            let text = textView.text ?? ""
            
            command = TextCommand(text: text, image: image, eol: self.eol())
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
        case let tCommand as TextCommand:
            typeIndex = 0
            title = tCommand.title
            textView.text = title
            updateEOLSegment(eol: tCommand.eol)
        case is DataCommand:
            typeIndex = 1
            title = command.data.hexEncodedString().uppercased()
            valueTextField.text = title
        default:
            return
        }
        
        typeSegmentControl.selectedSegmentIndex = typeIndex
        typeChanged(typeSegmentControl)
        
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
    
    private func setupTextView() {
        let accessoryToolbar = UIToolbar()
        accessoryToolbar.autoresizingMask = .flexibleHeight
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: textView, action: #selector(resignFirstResponder))
        accessoryToolbar.items = [doneBtn]
        
        textView.inputAccessoryView = accessoryToolbar
        
        textView.didChangeText = { [weak self] _ in
            self?.createButton.isEnabled = self?.readyForCreate() == true
        }
    }
    
    private func updateEOLSegment(eol: EOL) {
        let arr: [EOL] = [.lf, .cr, .crlf, .none]
        self.eolSegment.selectedSegmentIndex = arr.firstIndex(of: eol) ?? 3
    }
    
    private func setupTextField() {
        let accessoryToolbar = UIToolbar()
        accessoryToolbar.autoresizingMask = .flexibleHeight
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: valueTextField, action: #selector(resignFirstResponder))
        accessoryToolbar.items = [doneBtn]
        
        let hexLabel = UILabel()
        hexLabel.text = "  0x"
        hexLabel.font = valueTextField.font
        hexLabel.textColor = UIColor.Text.secondarySystemText
        hexLabel.textAlignment = .center
        valueTextField.leftView = hexLabel
        valueTextField.leftViewMode = .always
        valueTextField.inputAccessoryView = accessoryToolbar
    }
    
    private func readyForCreate() -> Bool {
        let selectedItem = collectionView.indexPathsForSelectedItems?.first != nil
        
        let dataIsReady = typeSegmentControl.selectedSegmentIndex == 0
            ? !textView.text.isEmpty
            : valueTextField.text?.isEmpty == false
        
        return selectedItem && dataIsReady
    }
    
    private func eol() -> EOL {
        switch eolSegment.selectedSegmentIndex {
        case 0: return .lf
        case 1: return .cr
        case 2: return .crlf
        default: return .none
        }
    }
}

extension UARTNewCommandViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        createButton.isEnabled = readyForCreate()
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
        return CharacterSet(charactersIn: "0123456789abcdefABCDEF").isSuperset(of: CharacterSet(charactersIn: string))
    }
}
