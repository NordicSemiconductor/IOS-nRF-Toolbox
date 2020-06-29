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
    func presetWasDeleted(_ preset: UARTPreset)
}

@available(iOS 13.0, *)
class PresetContextMenuInteraction: UIContextMenuInteraction {
    var preset: UARTPreset?
}

class PresetListViewController: UICollectionViewController {
    
    private let coreDataStack: CoreDataStack
//    private var presets: [UARTPreset] = []
    private var favoritePresets: [UARTPreset] = []
    private var notFavoritePresets: [UARTPreset] = []
    
    weak var presetDelegate: PresetListDelegate?
    
    init(stack: CoreDataStack = CoreDataStack.uart) {
        self.coreDataStack = stack
        let flowLayout = UICollectionViewFlowLayout()
        super.init(collectionViewLayout: flowLayout)
        
        collectionView.register(type: PresetListUtilityCell.self)
        collectionView.register(type: PresetListCell.self)
        collectionView.registerViewNib(type: PresetListSectionTitleView.self, ofKind: UICollectionView.elementKindSectionHeader)
        collectionView.backgroundColor = .tableViewBackground
    }
    
    required init?(coder: NSCoder) {
        self.coreDataStack = CoreDataStack.uart
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let presets = getPresetList()
        favoritePresets = presets.filter { $0.isFavorite }
        notFavoritePresets = presets.filter { !$0.isFavorite }
        
        navigationItem.title = "Preset List"
        if #available(iOS 13.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismsiss))
        }
    }
    
    private func getPresetList() -> [UARTPreset] {
        let request: NSFetchRequest<UARTPreset> = UARTPreset.fetchRequest()
        let sortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "isFavorite", ascending: false)
        let sortDate: NSSortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        request.sortDescriptors = [sortDescriptor, sortDate]
        
        return try! coreDataStack.viewContext.fetch(request)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return favoritePresets.count
        case 1: return notFavoritePresets.count
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
        
        let presets = indexPath.section == 0 ? favoritePresets : notFavoritePresets
        let preset = presets[indexPath.item]
        
        if #available(iOS 13.0, *) {
            let interaction = PresetContextMenuInteraction(delegate: self)
            interaction.preset = preset
            cell.addInteraction(interaction)
        } else {
            // Fallback on earlier versions
        }
        
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
        
        let presets = indexPath.section == 0 ? favoritePresets : notFavoritePresets
        let preset = presets[indexPath.item]
        
        self.presetDelegate?.didSelectPreset(preset)
    }
    
    @available(iOS 13.0, *)
    override func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        
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
            guard let preset = (interaction as? PresetContextMenuInteraction)?.preset else {
                return nil
            }
            
            let toggleFavoriteAction = self?.toggleAction(preset)
            
            let removeAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: UIMenuElement.Attributes.destructive) { (_) in
                
                guard let `self` = self else {
                    return
                }
                
                if let ip = self.getIndexPath(for: preset) {
                    if preset.isFavorite {
                        self.favoritePresets.remove(at: ip.item)
                    } else {
                        self.notFavoritePresets.remove(at: ip.item)
                    }
                    
                    self.collectionView.deleteItems(at: [ip])
                    
                    self.coreDataStack.viewContext.delete(preset)
                    try? self.coreDataStack.viewContext.save()
                    
                    self.presetDelegate?.presetWasDeleted(preset)
                }
                
            }
            
            return UIMenu(title: "Options", image: nil, identifier: nil, children: [toggleFavoriteAction!, removeAction])
        }
    }
    
    private func toggleAction(_ preset: UARTPreset) -> UIAction {
        let title = preset.isFavorite ? "Remove from favorite" : "Add to favorite"
        let systemIconName = preset.isFavorite ? "star" : "star.fill"
        
        return UIAction(title: title, image: UIImage(systemName: systemIconName)) { [weak self] (_) in
            guard let `self` = self else { return }
            preset.isFavorite.toggle()
            
            if let index = self.favoritePresets.firstIndex(of: preset) {
                let atIP = IndexPath(item: index, section: 0)
                let toIP = IndexPath(item: self.notFavoritePresets.count, section: 1)
                
                self.favoritePresets.remove(at: index)
                self.notFavoritePresets.append(preset)
                
                self.collectionView.moveItem(at: atIP, to: toIP)
            } else if let index = self.notFavoritePresets.firstIndex(of: preset) {
                let atIP = IndexPath(item: index, section: 1)
                let toIP = IndexPath(item: self.favoritePresets.count, section: 0)
                
                self.notFavoritePresets.remove(at: index)
                self.favoritePresets.append(preset)
                
                self.collectionView.moveItem(at: atIP, to: toIP)
            }
            
            try? self.coreDataStack.viewContext.save()
            self.collectionView.reloadData()
        }
    }
    
    private func getIndexPath(for preset: UARTPreset) -> IndexPath? {
        favoritePresets.firstIndex(of: preset).map { IndexPath(item: $0, section: 0) }
            ?? notFavoritePresets.firstIndex(of: preset).map { IndexPath(item: $0, section: 1) }
    }
}
