//
//  ModelConverter.swift
//  UART
//
//  Created by Nick Kibysh on 28/08/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import CoreData

protocol ModelConverter {
    associatedtype M
    associatedtype O: NSManagedObject
    
    func convert(model: M) -> O
    func convert(object: O) -> M 
}
