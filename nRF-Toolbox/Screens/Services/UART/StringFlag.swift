//
//  StringFlag.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 05/11/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

@propertyWrapper
struct StringFlag {
    private var value: String?
    
    var wrappedValue: Bool {
        get { value != nil }
        set {
            if !newValue { value = nil } // false => czyścimy string
        }
    }
    
    var projectedValue: String? {
        get { value }
        set { value = newValue } // dostęp do oryginalnego String?
    }
    
    init(wrappedValue: Bool = false) {
        self.value = wrappedValue ? "" : nil
    }
}
