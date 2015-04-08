
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
