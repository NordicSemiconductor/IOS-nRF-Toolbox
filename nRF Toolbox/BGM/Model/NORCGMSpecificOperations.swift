//
//  NORGlucoseReading.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 03/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

enum NORCGMOpCode : UInt8 {
    case reserved_OP_CODE                       = 0
    case set_COMMUNICATION_INTERVAL             = 1
    case get_COMMUNICATION_INTERVAL             = 2
    case communication_INTERVAL_RESPONSE        = 3
    case set_GLUCOSE_CALIBRATION_VALUE          = 4
    case get_GLUCOSE_CALIBRATION_VALUE          = 5
    case glucose_CALIBRATION_VALUE_RESPONSE     = 6
    case set_PATIENT_HIGH_ALERT_LEVEL           = 7
    case get_PATIENT_HIGH_ALERT_LEVEL           = 8
    case patient_HIGH_ALERT_LEVEL_RESPONSE      = 9
    case set_PATIENT_LOW_ALERT_LEVEL            = 10
    case get_PATIENT_LOW_ALERT_LEVEL            = 11
    case patient_LOW_ALERT_LEVEL_RESPONSE       = 12
    case set_HYPO_ALERT_LEVEL                   = 13
    case get_HYPO_ALERT_LEVEL                   = 14
    case hypo_ALERT_LEVEL_RESPONSE              = 15
    case set_HYPER_ALERT_LEVEL                  = 16
    case get_HYPER_ALERT_LEVEL                  = 17
    case hyper_ALERT_LEVEL_RESPONSE             = 18
    case set_RATE_OF_DECREASE_ALERT_LEVEL       = 19
    case get_RATE_OF_DECREASE_ALERT_LEVEL       = 20
    case rate_OF_DECREASE_ALERT_LEVEL_RESPONSE  = 21
    case set_RATE_OF_INCREASE_ALERT_LEVEL       = 22
    case get_RATE_OF_INCREASE_ALERT_LEVEL       = 23
    case rate_OF_INCREASE_ALERT_LEVEL_RESPONSE  = 24
    case reset_DEVICE_SPECIFIC_ALERT            = 25
    case start_SESSION                          = 26
    case stop_SESSION                           = 27
    case response_CODE                          = 28
    case reserved_FOR_FUTURE_USE
}

enum NORCGMEnumerations : UInt8 {

    case reserved                            = 0
    case communication_INTERVAL_IN_MINUTES   = 1
    case calibration_VALUE                   = 4
    case calibration_RECORD_NUMBER           = 5
    case calibration_DATA                    = 6
    case patient_HIGH_BG_VALUE               = 7
    case patient_LOW_BG_VALUE                = 10
    case hypo_ALERT_LEVEL_VALUE              = 13
    case hyper_ALERT_LEVEL_VALUE             = 16
    case rate_OF_DECREASE_ALERT_LEVEL_VALUE  = 19
    case rate_OF_INCREASE_ALERT_LEVEL_VALUE  = 22
    case request_OP_CODE_RESPONSE_CODE_VALUE = 28

}

enum NORCGMOpcodeResponseCodes : UInt8 {

    case reserved_RESPONSE       = 0
    case success                 = 1
    case op_CODE_NOT_SUPPORTED   = 2
    case invalid_OPERAND         = 3
    case procedure_NOT_COMPLETED = 4
    case parameter_OUT_OF_RANGE  = 5

}

//typedef struct __attribute__ ((__packed__))
//{
//    UInt8 opCode;
//    UInt8 operatorType;
//    union  __attribute__ ((__packed__)) {
//        UInt16 numberLE; // Little Endian
//        struct  __attribute__ ((__packed__)) {
//            UInt8 responseCode;
//            UInt8 requestOpCode;
//        } response;
//        struct  __attribute__ ((__packed__)) {
//            UInt8 filterType;
//            UInt16 paramLE; // Little Endian
//        } singleParam;
//        struct  __attribute__ ((__packed__)) {
//            UInt8 filterType;
//            UInt16 paramFromLE; // Little Endian
//            UInt16 paramToLE; // Little Endian
//        } doubleParam;
//    } value;
//} SpecficOpsParam;
