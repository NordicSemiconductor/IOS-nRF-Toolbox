//
//  SupportedServiceViewModel.swift
//  nRF Toolbox
//
//  Created by Dinesh Harjani on 4/6/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation

// MARK: - SupportedServiceViewModel

protocol SupportedServiceViewModel {
    
    func onConnect() async
    func onDisconnect()
}
