//
//  UARTMacrosCollectionViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 01/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreData

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

class UARTMacrosCollectionViewController: UICollectionViewController {
    
    var macros: [UARTMacro] = []
    
    init() {
        super.init(nibName: "UARTMacrosCollectionViewController", bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.registerCellNib(type: UARTMacrosCollectionViewCell.self)
        collectionView.registerCellNib(type: UARTNewMacrosCollectionViewCell.self)
        collectionView.registerViewNib(type: SearchCollectionReusableView.self, ofKind: UICollectionView.elementKindSectionHeader)
        
        self.macros = fetchMacros()
    }
    
    private func fetchMacros() -> [UARTMacro] {
        let request: NSFetchRequest<UARTMacro> = UARTMacro.fetchRequest()
        return try! CoreDataStack.uart.viewContext.fetch(request)
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
            let nc = UINavigationController.nordicBranded(rootViewController: vc, prefersLargeTitles: true)
            self.present(nc, animated: true, completion: nil)
            return
        }
    }
    
}

extension UARTMacrosCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = (collectionViewLayout as! UICollectionViewFlowLayout).itemWidth(minimumCellWidth: 160)
        return CGSize(width: itemWidth, height: 116)
    }
}
