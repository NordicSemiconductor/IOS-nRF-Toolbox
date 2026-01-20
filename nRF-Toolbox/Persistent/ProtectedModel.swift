//
//  ProtectedModel.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 20/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import SwiftData
import Foundation

nonisolated protocol ProtectedModel: Sendable, Identifiable {
    associatedtype Model: PersistentModel
    var persistentModelID: PersistentIdentifier? { get }
    
    init(from item: Model)
}
