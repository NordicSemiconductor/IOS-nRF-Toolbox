//
//  NORBGMRecordAccess.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 18/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//


enum NORBGMOpCode : UInt8 {
    case RESERVED                      = 0
    case REPORT_STORED_RECORDS         = 1
    case DELETE_STORED_RECORDS         = 2
    case ABORT_OPERATION               = 3
    case REPORT_STORED_RECORD_COUNT    = 4
    case NUMBER_OF_STORED_RECODRDS     = 5
    case RESPONSE_CODE                 = 6
    // Values outside this range are reserved
}

enum NORBGMOPerator : UInt8 {
    case NULL_OPERATOR                 = 0
    case ALL_RECORDS                   = 1
    case LESS_THAN_OR_EQUAL            = 2
    case GREATER_THAN_OR_EQUAL         = 3
    case WITHIN_RANGE_INCLUSIVE        = 4
    case FIRST_RECORD                  = 5
    case LAST_RECORD                   = 6
    // Values outside this range are reserved
}

enum NORBGMFilterType : UInt8 {
    case RESERVED_FILTER_TYPE          = 0
    case SEQUENCE_NUMBER               = 1
    case USER_FACING_TIME              = 2
}

enum NORBGMResponseCode : UInt8 {
    case RESERVED                      = 0
    case SUCCESS                       = 1
    case OP_CODE_NOT_SUPPORTED         = 2
    case INVALID_OPERATOR              = 3
    case OPERATOR_NOT_SUPPORTED        = 4
    case INVALID_OPERAND               = 5
    case NO_RECORDS_FOUND              = 6
    case ABORT_UNSUCCESSFUL            = 7
    case PROCEDURE_NOT_COMPLETED       = 8
    case OPERAND_NOT_SUPPORTED         = 9
    // Values outside this range are reserved
}