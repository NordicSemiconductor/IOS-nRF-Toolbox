//
//  NORGlucoseReading.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 03/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit

enum NORCGMOpCode : UInt8 {
    case RESERVED_OP_CODE                       = 0
    case SET_COMMUNICATION_INTERVAL             = 1
    case GET_COMMUNICATION_INTERVAL             = 2
    case COMMUNICATION_INTERVAL_RESPONSE        = 3
    case SET_GLUCOSE_CALIBRATION_VALUE          = 4
    case GET_GLUCOSE_CALIBRATION_VALUE          = 5
    case GLUCOSE_CALIBRATION_VALUE_RESPONSE     = 6
    case SET_PATIENT_HIGH_ALERT_LEVEL           = 7
    case GET_PATIENT_HIGH_ALERT_LEVEL           = 8
    case PATIENT_HIGH_ALERT_LEVEL_RESPONSE      = 9
    case SET_PATIENT_LOW_ALERT_LEVEL            = 10
    case GET_PATIENT_LOW_ALERT_LEVEL            = 11
    case PATIENT_LOW_ALERT_LEVEL_RESPONSE       = 12
    case SET_HYPO_ALERT_LEVEL                   = 13
    case GET_HYPO_ALERT_LEVEL                   = 14
    case HYPO_ALERT_LEVEL_RESPONSE              = 15
    case SET_HYPER_ALERT_LEVEL                  = 16
    case GET_HYPER_ALERT_LEVEL                  = 17
    case HYPER_ALERT_LEVEL_RESPONSE             = 18
    case SET_RATE_OF_DECREASE_ALERT_LEVEL       = 19
    case GET_RATE_OF_DECREASE_ALERT_LEVEL       = 20
    case RATE_OF_DECREASE_ALERT_LEVEL_RESPONSE  = 21
    case SET_RATE_OF_INCREASE_ALERT_LEVEL       = 22
    case GET_RATE_OF_INCREASE_ALERT_LEVEL       = 23
    case RATE_OF_INCREASE_ALERT_LEVEL_RESPONSE  = 24
    case RESET_DEVICE_SPECIFIC_ALERT            = 25
    case START_SESSION                          = 26
    case STOP_SESSION                           = 27
    case RESPONSE_CODE                          = 28
    case RESERVED_FOR_FUTURE_USE
}

enum NORCGMEnumerations : UInt8 {

    case RESERVED                            = 0
    case COMMUNICATION_INTERVAL_IN_MINUTES   = 1
    case CALIBRATION_VALUE                   = 4
    case CALIBRATION_RECORD_NUMBER           = 5
    case CALIBRATION_DATA                    = 6
    case PATIENT_HIGH_BG_VALUE               = 7
    case PATIENT_LOW_BG_VALUE                = 10
    case HYPO_ALERT_LEVEL_VALUE              = 13
    case HYPER_ALERT_LEVEL_VALUE             = 16
    case RATE_OF_DECREASE_ALERT_LEVEL_VALUE  = 19
    case RATE_OF_INCREASE_ALERT_LEVEL_VALUE  = 22
    case REQUEST_OP_CODE_RESPONSE_CODE_VALUE = 28

}

enum NORCGMOpcodeResponseCodes : UInt8 {

    case RESERVED_RESPONSE       = 0
    case SUCCESS                 = 1
    case OP_CODE_NOT_SUPPORTED   = 2
    case INVALID_OPERAND         = 3
    case PROCEDURE_NOT_COMPLETED = 4
    case PARAMETER_OUT_OF_RANGE  = 5

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