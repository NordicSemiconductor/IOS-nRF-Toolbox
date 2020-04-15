//
//  BatteryTableViewCell.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 13/09/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol DetailsTableViewCellModel {
    var title: String { get set }
    var details: CustomStringConvertible { get set }
    var identifier: Identifier<DetailsTableViewCellModel> { get }
}

struct DefaultDetailsTableViewCellModel: DetailsTableViewCellModel {
    var title: String
    let identifier: Identifier<DetailsTableViewCellModel>
    
    var details: CustomStringConvertible
    
    init(title: String, value: String = "-", identifier: Identifier<DetailsTableViewCellModel> = "") {
        self.title = title
        self.details = value
        self.identifier = identifier
    }
}

class DetailsTableViewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        
        textLabel?.font = UIFont.gtEestiDisplay(.regular, size: 17.0)
        detailTextLabel?.font = UIFont.gtEestiDisplay(.regular, size: 17.0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with model: DetailsTableViewCellModel) {
        textLabel?.text = model.title
        detailTextLabel?.text = model.details.description
    }
    
}
