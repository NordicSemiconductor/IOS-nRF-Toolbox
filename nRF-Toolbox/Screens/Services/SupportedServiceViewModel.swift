//
//  SupportedServiceViewModel.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 4/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - SupportedServiceViewModel

protocol SupportedServiceViewModel {
    
    var description: String { get }
    
    @ViewBuilder
    var attachedView: any View { get }
    
    // TODO: async throws for onConnect()
    func onConnect() async
    func onDisconnect()
}
