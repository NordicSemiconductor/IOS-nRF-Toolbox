//
//  NORBGMRecordAccess.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 18/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//


enum NORBGMOpCode : UInt8 {
    case reserved                      = 0
    case report_STORED_RECORDS         = 1
    case delete_STORED_RECORDS         = 2
    case abort_OPERATION               = 3
    case report_STORED_RECORD_COUNT    = 4
    case number_OF_STORED_RECODRDS     = 5
    case response_CODE                 = 6
    // Values outside this range are reserved
}

enum NORBGMOPerator : UInt8 {
    case null_OPERATOR                 = 0
    case all_RECORDS                   = 1
    case less_THAN_OR_EQUAL            = 2
    case greater_THAN_OR_EQUAL         = 3
    case within_RANGE_INCLUSIVE        = 4
    case first_RECORD                  = 5
    case last_RECORD                   = 6
    // Values outside this range are reserved
}

enum NORBGMFilterType : UInt8 {
    case reserved_FILTER_TYPE          = 0
    case sequence_NUMBER               = 1
    case user_FACING_TIME              = 2
}

enum NORBGMResponseCode : UInt8 {
    case reserved                      = 0
    case success                       = 1
    case op_CODE_NOT_SUPPORTED         = 2
    case invalid_OPERATOR              = 3
    case operator_NOT_SUPPORTED        = 4
    case invalid_OPERAND               = 5
    case no_RECORDS_FOUND              = 6
    case abort_UNSUCCESSFUL            = 7
    case procedure_NOT_COMPLETED       = 8
    case operand_NOT_SUPPORTED         = 9
    // Values outside this range are reserved
}
