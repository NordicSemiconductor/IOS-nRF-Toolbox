
/*
 * Copyright (c) 2015, Nordic Semiconductor
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef nRF_Toolbox_RecordAccess_h
#define nRF_Toolbox_RecordAccess_h

typedef enum
{
    RESERVED_OP_CODE,
    SET_COMMUNICATION_INTERVAL,
    GET_COMMUNICATION_INTERVAL,
    COMMUNICATION_INTERVAL_RESPONSE,
    SET_GLUCOSE_CALIBRATION_VALUE,
    GET_GLUCOSE_CALIBRATION_VALUE,
    GLUCOSE_CALIBRATION_VALUE_RESPONSE,
    SET_PATIENT_HIGH_ALERT_LEVEL,
    GET_PATIENT_HIGH_ALERT_LEVEL,
    PATIENT_HIGH_ALERT_LEVEL_RESPONSE,
    SET_PATIENT_LOW_ALERT_LEVEL,
    GET_PATIENT_LOW_ALERT_LEVEL,
    PATIENT_LOW_ALERT_LEVEL_RESPONSE,
    SET_HYPO_ALERT_LEVEL,
    GET_HYPO_ALERT_LEVEL,
    HYPO_ALERT_LEVEL_RESPONSE,
    SET_HYPER_ALERT_LEVEL,
    GET_HYPER_ALERT_LEVEL,
    HYPER_ALERT_LEVEL_RESPONSE,
    SET_RATE_OF_DECREASE_ALERT_LEVEL,
    GET_RATE_OF_DECREASE_ALERT_LEVEL,
    RATE_OF_DECREASE_ALERT_LEVEL_RESPONSE,
    SET_RATE_OF_INCREASE_ALERT_LEVEL,
    GET_RATE_OF_INCREASE_ALERT_LEVEL,
    RATE_OF_INCREASE_ALERT_LEVEL_RESPONSE,
    RESET_DEVICE_SPECIFIC_ALERT,
    START_SESSION,
    STOP_SESSION,
    RESPONSE_CODE,
    RESERVED_FOR_FUTURE_USE
} CGMOpCode;

typedef enum
{
    RESERVED                            = 0,
    COMMUNICATION_INTERVAL_IN_MINUTES   = 1,
    CALIBRATION_VALUE                   = 4,
    CALIBRATION_RECORD_NUMBER           = 5,
    CALIBRATION_DATA                    = 6,
    PATIENT_HIGH_BG_VALUE               = 7,
    PATIENT_LOW_BG_VALUE                = 10,
    HYPO_ALERT_LEVEL_VALUE              = 13,
    HYPER_ALERT_LEVEL_VALUE             = 16,
    RATE_OF_DECREASE_ALERT_LEVEL_VALUE  = 19,
    RATE_OF_INCREASE_ALERT_LEVEL_VALUE  = 22,
    REQUEST_OP_CODE_RESPONSE_CODE_VALUE = 28,
} GCMEnumerations;

typedef enum
{
    RESERVED_RESPONSE       = 0,
    SUCCESS                 = 1,
    OP_CODE_NOT_SUPPORTED   = 2,
    INVALID_OPERAND         = 3,
    PROCEDURE_NOT_COMPLETED = 4,
    PARAMETER_OUT_OF_RANGE  = 5,
} CGMOpcodeResponseCodes;

typedef struct __attribute__ ((__packed__))
{
    UInt8 opCode;
    UInt8 operatorType;
    union  __attribute__ ((__packed__)) {
        UInt16 numberLE; // Little Endian
        struct  __attribute__ ((__packed__)) {
            UInt8 responseCode;
            UInt8 requestOpCode;
        } response;
        struct  __attribute__ ((__packed__)) {
            UInt8 filterType;
            UInt16 paramLE; // Little Endian
        } singleParam;
        struct  __attribute__ ((__packed__)) {
            UInt8 filterType;
            UInt16 paramFromLE; // Little Endian
            UInt16 paramToLE; // Little Endian
        } doubleParam;
    } value;
} SpecficOpsParam;

#endif
