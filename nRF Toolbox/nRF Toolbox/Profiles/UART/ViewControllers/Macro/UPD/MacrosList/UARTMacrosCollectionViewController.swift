//
//  UARTMacrosCollectionViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 01/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreData
import UART

extension UICollectionViewFlowLayout {
    func itemWidth(minimumCellWidth minWidth: CGFloat) -> CGFloat {
        guard let cvWidth = collectionView?.frame.width else {
            return 0
        }
        
        let sectionWidth = cvWidth - sectionInset.right - sectionInset.left + minimumInteritemSpacing
        let numberOfItems = (sectionWidth / (minWidth + minimumInteritemSpacing)).rounded(.down)
        let itemWidth = sectionWidth / numberOfItems - minimumInteritemSpacing
        
        return itemWidth
    }
}

class UARTMacrosCollectionViewController: UICollectionViewController, AlertPresenter {
    
    var macros: [Macros] = []
    
    let macrosManager: MacrosManager
    let btManager: BluetoothManager
    
    init(bluetoothManager: BluetoothManager = .shared, macrosManager: MacrosManager = MacrosManager()) {
        self.btManager = bluetoothManager
        self.macrosManager = macrosManager
        super.init(nibName: "UARTMacrosCollectionViewController", bundle: .main)
        
        tabBarItem = UITabBarItem(title: "Macros", image: TabBarIcon.uartMacros.image, selectedImage: TabBarIcon.uartMacros.filledImage)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.registerCellNib(type: UARTMacrosCollectionViewCell.self)
        collectionView.registerCellNib(type: UARTNewMacrosCollectionViewCell.self)
        collectionView.registerViewNib(type: SearchCollectionReusableView.self, ofKind: UICollectionView.elementKindSectionHeader)
        
        self.macros = try! macrosManager.loadMacros()
        
        
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        macros.count + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.item != macros.count else {
            return collectionView.dequeueCell(ofType: UARTNewMacrosCollectionViewCell.self, for: indexPath)
        }
        
        let macro = macros[indexPath.item]
        
        let cell = collectionView.dequeueCell(ofType: UARTMacrosCollectionViewCell.self, for: indexPath)
        cell.editMacros = { _ in
            let vc = UARTMacroEditCommandListVC(macros: macro)
            vc.editCommandDelegate = self
            let nc = UINavigationController.nordicBranded(rootViewController: vc, prefersLargeTitles: true)
            self.present(nc, animated: true, completion: nil)
        }
        cell.applyMacro(macro)
        
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        return collectionView.dequeueView(type: SearchCollectionReusableView.self, ofKind: UICollectionView.elementKindSectionHeader, for: indexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < macros.count else {
            let vc = UARTMacroEditCommandListVC(macros: nil)
            vc.editCommandDelegate = self
            let nc = UINavigationController.nordicBranded(rootViewController: vc, prefersLargeTitles: true)
            self.present(nc, animated: true, completion: nil)
            return
        }
        
        let macro = macros[indexPath.item]
        btManager.send(macro: macro)
    }
    
    override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        indexPath.item == macros.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        macros.swapAt(sourceIndexPath.item, destinationIndexPath.item)
    }
    
}

extension UARTMacrosCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = (collectionViewLayout as! UICollectionViewFlowLayout).itemWidth(minimumCellWidth: 160)
        return CGSize(width: itemWidth, height: 116)
    }
}

extension UARTMacrosCollectionViewController: UARTMacroEditCommandProtocol {
    func saveMacroUpdate(_ macros: Macros?, commandSet: [MacrosElement], name: String, color: Color) {
        defer {
            dismsiss()
        }
        
        guard var macros = macros else {
            let newMacros = Macros(elements: commandSet, name: name, color: color)
            self.macros.append(try! macrosManager.save(macros: newMacros))
            collectionView.insertItems(at: [IndexPath(item: self.macros.count - 1, section: 0)])
            return
        }
        
        guard let index = self.macros.firstIndex(of: macros) else {
            return
        }
        
        macros.name = name
        macros.color = color
        macros.elements = commandSet
        
        self.macros[index] = try! macrosManager.save(macros: macros)
        
        collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
    }
    
}
