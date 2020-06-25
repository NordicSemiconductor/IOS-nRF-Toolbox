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
        
        collectionView.register(type: PresetListUtilityCell.self)
        collectionView.register(type: PresetListCell.self)
        collectionView.backgroundColor = .tableViewBackground
    }
    
    required init?(coder: NSCoder) {
        self.coreDataStack = CoreDataStack.uart
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presets = getPresetList()
        
        navigationItem.title = "Preset List"
        if #available(iOS 13.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismsiss))
        } else {
            // Fallback on earlier versions
        }
    }
    
    private func getPresetList() -> [UARTPreset] {
        let request: NSFetchRequest<UARTPreset> = UARTPreset.fetchRequest()
        let sortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "isFavorite", ascending: false)
        let sortDate: NSSortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        request.sortDescriptors = [sortDescriptor, sortDate]
        
        return try! coreDataStack.viewContext.fetch(request)
    }
    
    private func filterPresets(isFavorite:  Bool) -> [UARTPreset] {
        presets.filter { $0.isFavorite == isFavorite }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return filterPresets(isFavorite: true).count
        case 1: return filterPresets(isFavorite: false).count
        case 2: return 2
        default: SystemLog.fault("Unknown section", category: .ui)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard indexPath.section != 2 else {
            let type: PresetListUtilityCell.CellStyle = indexPath.row == 0 ? .blanc : .export
            let cell = collectionView.dequeueCell(ofType: PresetListUtilityCell.self, for: indexPath)
            cell.type = type
            return cell
        }
        
        let cell = collectionView.dequeueCell(ofType: PresetListCell.self, for: indexPath)
        
        let presets = indexPath.section == 0 ? filterPresets(isFavorite: true) : filterPresets(isFavorite: false)
        let preset = presets[indexPath.item]
        
        let cellSize  = collectionViewsizeForItem(collectionView)
        let imageSize = CGSize(width: cellSize.width, height: cellSize.width)
        cell.apply(preset, imageSize: imageSize)
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section != 2 else {
            self.presetDelegate?.didSelectPreset(UARTPreset.empty)
            return
        }
        
        let presets = indexPath.section == 0 ? filterPresets(isFavorite: true) : filterPresets(isFavorite: false)
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
