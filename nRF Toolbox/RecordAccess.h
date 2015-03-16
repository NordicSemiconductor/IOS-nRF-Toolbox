
//
//  RecordAccess.h
//  nRF Toolbox
//
//  Created by Aleksander Nowakowski on 20/01/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#ifndef nRF_Toolbox_RecordAccess_h
#define nRF_Toolbox_RecordAccess_h

typedef enum
{
    RESERVED_OP_CODE,
    REPORT_STORED_RECORDS,
    DELETE_STORED_RECORDS,
    ABORT_OPERATION,
    REPORT_NUMBER_OF_STORED_RECORDS,
    NUMBER_OF_STORED_RECORDS,
    RESPONSE_CODE
} OpCode;

typedef enum
{
    NULL_OPERATOR,
    ALL_RECORDS,
    LESS_THAN_OR_EQUAL,
    GREATER_THAN_OR_EQUAL,
    WITHIN_RANGE_INCLUSIVE,
    FIRST_RECORD, // oldest
    LAST_RECORD, // most recent one
    RESERVED_OPERATOR
} Operator;

typedef enum
{
    RESERVED_FILTER_TYPE,
    SEQUENCE_NUMBER,
    USER_FACING_TIME
} FilterType;

typedef enum
{
    RESERVED_RESPONSE,
    SUCCESS,
    OP_CODE_NOT_SUPPORTED,
    INVALID_OPERATOR,
    OPERATOR_NOT_SUPPORTED,
    INVALID_OPERAND,
    NO_RECORDS_FOUND,
    ABORT_UNSUCCESSFUL,
    PROCEDURE_NOT_COMPLETED,
    OPERAND_NOT_SUPPORTED
} ResponseCode;

typedef struct __attribute__ ((__packed__))
{
    UInt8 opCode;
    UInt8 operatorType;
    union  __attribute__ ((__packed__)) {
        UInt16 numberLE; // Little Endian
        struct  __attribute__ ((__packed__)) {
            UInt8 requestOpCode;
            UInt8 responseCode;
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
} RecordAccessParam;

#endif
