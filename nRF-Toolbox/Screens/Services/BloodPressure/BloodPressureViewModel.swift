//
//  BloodPressureViewModel.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 23/10/2023.
//  Copyright © 2023 Nordic Semiconductor. All rights reserved.
//

import Combine 
import SwiftUI

extension BloodPressureScreen {
    @MainActor 
    class ViewModel: ObservableObject {
        let env = Environment()
    }
}

extension BloodPressureScreen.ViewModel {
    @MainActor
    class Environment: ObservableObject {
        
    }
}