//
//  Assets.swift
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 27/11/24.
//  Created by Dinesh Harjani on 3/3/21.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - Assets

enum Assets: String {
    
    // MARK: Colors
    
    case navBar = "NavBarColor"
    
    // MARK: SwiftUI.Color
    
    var color: Color {
        Color(rawValue)
    }
    
    // MARK: UIColor
    
    #if os(iOS)
    var uiColor: UIColor! {
        UIColor(named: rawValue)
    }
    #endif
}
