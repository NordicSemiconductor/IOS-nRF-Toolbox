//
//  UARTCommandListCollectionView.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 17/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol UARTCommandListDelegate: class {
    func selectedCommand(_ command: UARTCommandModel, at index: Int)
    func longTapAtCommand(_ command: UARTCommandModel, at index: Int)
}

class UARTCommandListCollectionView: UICollectionView {
    var preset: UARTPreset = .default {
        didSet {
            reloadData()
        }
    }
    weak var commandListDelegate: UARTCommandListDelegate?
    
    private var longPress = UILongPressGestureRecognizer()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        dataSource = self
        delegate = self
        register(type: UARTActionCollectionViewCell.self)
        longPress.addTarget(self, action: #selector(longPressed))
        addGestureRecognizer(longPress)
    }
    
    @objc private func longPressed(_ sender: UIGestureRecognizer) {
        let location = sender.location(in: self)
        guard let ip = indexPathForItem(at: location) else { return }
        let command = preset.commands[ip.item]
        commandListDelegate?.longTapAtCommand(command, at: ip.item)
    }
}

extension UARTCommandListCollectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let side = collectionView.frame.size.width / 3 - 2
        return CGSize(width: side, height: side)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        3
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        3
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let command = preset.commands[indexPath.item]
        self.commandListDelegate?.selectedCommand(command, at: indexPath.item)
    }
}

extension UARTCommandListCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return preset.commands.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let command = preset.commands[indexPath.item]
        
        let cell = collectionView.dequeueCell(ofType: UARTActionCollectionViewCell.self, for: indexPath)
        cell.apply(command: command)
        if #available(iOS 13.0, *) {
            cell.contentView.backgroundColor = .systemGroupedBackground
        } else {
            cell.contentView.backgroundColor = .lightGray
        }
        return cell
    }
}
