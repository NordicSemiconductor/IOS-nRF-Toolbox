//
//  CGMSFeature.swift
//  nRF Toolbox
//
//  Created by Sylwester Zieliński on 19/09/2025.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

struct CGMFeaturesEnvelope {
    let features: CGMFeatures
    let type: Int
    let sampleLocation: Int
    let secured: Bool
    let crcValid: Bool
}
