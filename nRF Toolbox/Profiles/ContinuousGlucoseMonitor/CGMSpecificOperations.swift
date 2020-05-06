/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



import UIKit

enum CGMOpCode: UInt8 {
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

enum CGMEnumerations: UInt8 {
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

enum CGMOpcodeResponseCodes: UInt8 {
    case reserved              = 0
    case success               = 1
    case opCodeNotSupported    = 2
    case invalidOperand        = 3
    case procedureNotCompleted = 4
    case parameterOutOfRange   = 5
}
