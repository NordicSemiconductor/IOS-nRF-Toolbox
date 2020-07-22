//
//  UARTCollorSelectorCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 19/07/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

private class UARTColorCollectionViewCell: UICollectionViewCell {
    override var isSelected: Bool {
        didSet {
            if isSelected {
                layer.borderWidth = 3
            } else {
                layer.borderWidth = 0
            }
        }
    }
    
    func apply(color: UARTColor) {
        contentView.cornerRadius = contentView.frame.minSide / 2
        contentView.backgroundColor = color.color
        cornerRadius = contentView.frame.minSide / 2
        borderColor = .nordicBlue
    }
}

class UARTColorSelectorCell: UITableViewCell {
    
    @IBOutlet private var collectionView: UICollectionView!
    var color: UARTColor? {
        didSet {
            UARTColor.allCases
                    .firstIndex {
                        $0.rawValue == self.color?.rawValue
                    }
                    .map {
                        self.collectionView.selectItem(at: IndexPath(item: $0, section: 0), animated: true, scrollPosition: .bottom)
                    }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.registerCellClass(type: UARTColorCollectionViewCell.self)
    }
}

extension UARTColorSelectorCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        UARTColor.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let color = UARTColor.allCases[indexPath.item]
        let cell = collectionView.dequeueCell(ofType: UARTColorCollectionViewCell.self, for: indexPath)
        cell.apply(color: color)
        
        return cell
    }
    
}

extension UARTColorSelectorCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.color = UARTColor.allCases[indexPath.row]
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 44, height: 44)
    }
    
}
