//
//  PresetListViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 08/06/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreData

protocol PresetListDelegate: class {
    func didSelectPreset(_ preset: UARTPreset)
}

class PresetListViewController: UICollectionViewController {
    
    private let coreDataStack: CoreDataStack
    private var presets: [UARTPreset] = []
    
    weak var presetDelegate: PresetListDelegate?
    
    init(stack: CoreDataStack = CoreDataStack.uart) {
        self.coreDataStack = stack
        let flowLayout = UICollectionViewFlowLayout()
        super.init(collectionViewLayout: flowLayout)
        
        collectionView.register(type: PresetListCell.self)
        collectionView.register(type: AddUARTPresetCell.self)
        collectionView.backgroundColor = .nordicBackground
    }
    
    required init?(coder: NSCoder) {
        self.coreDataStack = CoreDataStack.uart
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presets = getPresetList()
    }
    
    private func getPresetList() -> [UARTPreset] {
        let request: NSFetchRequest<UARTPreset> = UARTPreset.fetchRequest()
        return try! coreDataStack.viewContext.fetch(request)
    }
    
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        presets.count + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard indexPath.item < presets.count else {
            return collectionView.dequeueCell(ofType: AddUARTPresetCell.self, for: indexPath)
        }
        
        let cell = collectionView.dequeueCell(ofType: PresetListCell.self, for: indexPath)
        let preset = presets[indexPath.item]
        let cellSize  = collectionViewsizeForItem(collectionView)
        let imageSize = CGSize(width: cellSize.width, height: cellSize.width)
        cell.apply(preset, imageSize: imageSize)
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let preset = presets[indexPath.item]
        self.presetDelegate?.didSelectPreset(preset)
    }
}

extension PresetListViewController: UICollectionViewDelegateFlowLayout {
    func collectionViewsizeForItem(_ collectionView: UICollectionView) -> CGSize {
        let minimumCellWidth: CGFloat = 100
        let numberOfCellsInRaw = Int(collectionView.frame.width / minimumCellWidth)
        let cellWidth = collectionView.frame.width / CGFloat(numberOfCellsInRaw) - 8
        return CGSize(width: cellWidth, height: cellWidth + 28)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionViewsizeForItem(collectionView)
    }
}
