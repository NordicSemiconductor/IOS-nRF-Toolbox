//
//  PresetListViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 08/06/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreData
import Core
import UART

protocol PresetListDelegate: class {
    func didSelectPreset(_ preset: Preset)
    func presetWasDeleted(_ preset: Preset)
    func presetWasRenamed(_ preset: Preset)
}

@available(iOS 13.0, *)
class PresetContextMenuInteraction: UIContextMenuInteraction {
    var preset: Preset?
}

class PresetListViewController: UICollectionViewController {
    
    private struct DataSource {
        var favoritePresets: [Preset] = []
        var notFavoritePresets: [Preset] = []
        var inQuickAccess: [Preset] = []
    }
    
    private let presetManager: PresetManager
    private var dataSource: DataSource = DataSource()
    
    weak var presetDelegate: PresetListDelegate?
    
    init(inQuickAccess: [Preset], presetManager: PresetManager) {
        self.presetManager = presetManager
        
        self.dataSource = DataSource(favoritePresets: [], notFavoritePresets: [], inQuickAccess: inQuickAccess)
        
        let flowLayout = UICollectionViewFlowLayout()
        super.init(collectionViewLayout: flowLayout)
        
        collectionView.registerCellNib(type: PresetListUtilityCell.self)
        collectionView.registerCellNib(type: PresetListCell.self)
        collectionView.registerViewNib(type: PresetListSectionTitleView.self, ofKind: UICollectionView.elementKindSectionHeader)
        collectionView.backgroundColor = .tableViewBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let presets = presetManager.loadPresets()
        dataSource.favoritePresets = presets.filter { $0.isFavorite }
        dataSource.notFavoritePresets = presets.filter { !$0.isFavorite }
        
        navigationItem.title = "Preset List"
        if #available(iOS 13.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismsiss))
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return dataSource.favoritePresets.count
        case 1: return dataSource.notFavoritePresets.count
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
        
        let presets = indexPath.section == 0 ? dataSource.favoritePresets : dataSource.notFavoritePresets
        let preset = presets[indexPath.item]
        
        if #available(iOS 13.0, *) {
            let interaction = PresetContextMenuInteraction(delegate: self)
            interaction.preset = preset
            cell.addInteraction(interaction)
        }
        
        let cellSize  = collectionViewsizeForItem(collectionView)
        let imageSize = CGSize(width: cellSize.width, height: cellSize.width)
        cell.apply(preset, imageSize: imageSize)
        
        cell.imageView.borderColor = .nordicBlue
        cell.imageView.cornerRadius = 4
         
        cell.imageView.borderWidth = dataSource.inQuickAccess.contains(preset) ? 2 : 0
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section != 2 else {
            self.presetDelegate?.didSelectPreset(Preset)
            return
        }
        
        let presets = indexPath.section == 0 ? dataSource.favoritePresets : dataSource.notFavoritePresets
        let preset = presets[indexPath.item]
        
        self.presetDelegate?.didSelectPreset(preset)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            SystemLog.fault("Kind is not supported", category: .ui)
        }
        
        let view = collectionView.dequeueView(type: PresetListSectionTitleView.self, ofKind: kind, for: indexPath)
        
        switch indexPath.section {
        case 0:
            view.title.text = "Favorite"
        case 1:
            view.title.text = "Not Favorite"
        case 2:
            view.title.text = "New Preset"
        default:
            break
        }
        
        return view
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 320, height: 40)
    }
}

@available(iOS 13.0, *)
extension PresetListViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak interaction, weak self] (menu) -> UIMenu? in
            guard let preset = (interaction as? PresetContextMenuInteraction)?.preset, let `self` = self else {
                return nil
            }
            
            let removeAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: UIMenuElement.Attributes.destructive) { (_) in
                
                if let ip = self.getIndexPath(for: preset) {
                    if preset.isFavorite {
                        self.dataSource.favoritePresets.remove(at: ip.item)
                    } else {
                        self.dataSource.notFavoritePresets.remove(at: ip.item)
                    }
                    
                    self.collectionView.deleteItems(at: [ip])
                    
                    self.coreDataStack.viewContext.delete(preset)
                    try? self.coreDataStack.viewContext.save()
                    
                    self.presetDelegate?.presetWasDeleted(preset)
                }
                
            }
            
            return UIMenu(title: "Options", image: nil, identifier: nil, children: [
                self.toggleAction(preset),
                self.renameAction(preset),
                self.duplicateAction(preset),
                self.exportAction(preset),
                removeAction
            ])
        }
    }
    
    private func toggleAction(_ preset: UARTPreset) -> UIAction {
        let title = preset.isFavorite ? "Remove from favorite" : "Add to favorite"
        let systemIconName = preset.isFavorite ? "star" : "star.fill"
        
        return UIAction(title: title, image: UIImage(systemName: systemIconName)) { [weak self] (_) in
            guard let `self` = self else { return }
            preset.isFavorite.toggle()
            
            if let index = self.dataSource.favoritePresets.firstIndex(of: preset) {
                let atIP = IndexPath(item: index, section: 0)
                let toIP = IndexPath(item: self.dataSource.notFavoritePresets.count, section: 1)
                
                self.dataSource.favoritePresets.remove(at: index)
                self.dataSource.notFavoritePresets.append(preset)
                
                self.collectionView.moveItem(at: atIP, to: toIP)
            } else if let index = self.dataSource.notFavoritePresets.firstIndex(of: preset) {
                let atIP = IndexPath(item: index, section: 1)
                let toIP = IndexPath(item: self.dataSource.favoritePresets.count, section: 0)
                
                self.dataSource.notFavoritePresets.remove(at: index)
                self.dataSource.favoritePresets.append(preset)
                
                self.collectionView.moveItem(at: atIP, to: toIP)
            }
            
            try? self.coreDataStack.viewContext.save()
            self.collectionView.reloadData()
        }
    }
    
    private func duplicateAction(_ preset: UARTPreset) -> UIAction {
        UIAction(title: "Duplicate", image: ModernIcon.duplicateIcon.image) { [unowned self] (_) in
            let alert = UARTPresetUIUtil().dupplicatePreset(preset, intoContext: self.coreDataStack.viewContext) { (new) in
                self.dataSource.notFavoritePresets.append(new)
                self.collectionView.insertItems(at: [IndexPath(item: self.dataSource.notFavoritePresets.count-1, section: 1)])
            }
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func renameAction(_ preset: UARTPreset) -> UIAction {
        UIAction(title: "Rename", image: ModernIcon.pencil.image) { (_) in
            let alert = UARTPresetUIUtil().renameAlert(for: preset) { [weak self] in
                self?.collectionView.reloadData()
                self?.presetDelegate?.presetWasRenamed(preset)
            }
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func exportAction(_ preset: UARTPreset) -> UIAction {
        UIAction(title: "Export", image: ModernIcon.exportIcon.image) { (_) in
            
        }
    }
    
    private func getIndexPath(for preset: UARTPreset) -> IndexPath? {
        dataSource.favoritePresets.firstIndex(of: preset).map { IndexPath(item: $0, section: 0) }
            ?? dataSource.notFavoritePresets.firstIndex(of: preset).map { IndexPath(item: $0, section: 1) }
    }
}
