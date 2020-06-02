//
//  UARTCommandModel+CoreDataClass.swift
//  
//
//  Created by Nick Kibish on 02.06.2020.
//
//

import Foundation
import CoreData
import UIKit.UIImage

@objc(UARTCommandModel)
public class UARTCommandModel: UARTMacroElement {

}

extension UARTCommandModel: NordicTextTableViewCellModel {
    var image: UIImage? {
        return icon?.image
    }
    
    var text: String? {
        return nil
    }
    
    
}
