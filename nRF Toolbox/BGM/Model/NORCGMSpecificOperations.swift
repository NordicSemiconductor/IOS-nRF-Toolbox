//
//  NORGlucoseReading.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 03/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

enum NORCGMOpCode: UInt8 {
    case reserved                          = 0
    case setCommunicationInterval          = 1
    case getCommunicationInterval          = 2
    case communicationIntervalResponse     = 3
    case setGlucoseCalibrationValue        = 4
    case getGlucoseCalibrationValue        = 5
    case glucoseCalibrationValueResponse   = 6
    case setPatientHighAlertLevel          = 7
    case getPatientHighAlertLevel          = 8
    case patientHighAlertLevelResponse     = 9
    case setPatientLowAlertLevel           = 10
    case getPatientLowAlertLevel           = 11
    case patientLowAlertLevelResponse      = 12
    case setHypoAlertLevel                 = 13
    case getHypoAlertLevel                 = 14
    case hypoAlertLevelResponse            = 15
    case setHyperAlertLevel                = 16
    case getHyperAlertLevel                = 17
    case hyperAlertLevelResponse           = 18
    case setRateOfDecreaseAlertLevel       = 19
    case getRateOfDecreaseAlertLevel       = 20
    case rateOfDecreaseAlertLevelResponse  = 21
    case setRateOfIncreaseAlertLevel       = 22
    case getRateOfIncreaseAlertLevel       = 23
    case rateOfIncreaseAlertLevelResponse  = 24
    case resetDeviceSpecificAlert          = 25
    case startSession                      = 26
    case stopStopSession                   = 27
    case responseCode                      = 28
}

enum NORCGMEnumerations: UInt8 {
    case reserved                       = 0
    case communicationIntervalInMinutes = 1
    case calibrationValue               = 4
    case calibrationRecordNumber        = 5
    case calibrationData                = 6
    case patientHighBgValue             = 7
    case patientLowBgValue              = 10
    case hypoAlertLevelValue            = 13
    case hyperAlertLevelValue           = 16
    case rateOfDecreaseAlertLevelValue  = 19
    case rateOfIncreaseAlertLevelValue  = 22
    case responseCode                   = 28
}

enum NORCGMOpcodeResponseCodes: UInt8 {
    case reserved              = 0
    case success               = 1
    case opCodeNotSupported    = 2
    case invalidOperand        = 3
    case procedureNotCompleted = 4
    case parameterOutOfRange   = 5
}
