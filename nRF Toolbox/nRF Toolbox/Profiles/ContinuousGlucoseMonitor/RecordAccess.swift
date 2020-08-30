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

import Core 


enum BGMOpCode : UInt8 {
    case reserved                 = 0
    case reportStoredRecords      = 1
    case deleteStoredRecords      = 2
    case abort                    = 3
    case reportStoredRecordsCount = 4
    case numberOfStoredRecords    = 5
    case response                 = 6
    // Values outside this range are reserved
}

enum BGMOperator : UInt8 {
    case null                 = 0
    case allRecords           = 1
    case lessThanOrEqual      = 2
    case greaterThanOrEqual   = 3
    case withinRangeInclusive = 4
    case first                = 5
    case last                 = 6
    // Values outside this range are reserved
}

enum BGMFilterType : UInt8 {
    case reserved       = 0
    case sequenceNumber = 1
    case userFacingTime = 2
}

enum BGMResponseCode : UInt8 {
    case reserved              = 0
    case success               = 1
    case opCodeNotSupported    = 2
    case invalidOperator       = 3
    case operatorNotSupported  = 4
    case invalidOperand        = 5
    case noRecordsFound        = 6
    case abortUnsuccessful     = 7
    case procedureNotCompleted = 8
    case operandNotSupported   = 9
    // Values outside this range are reserved
    
    var error: TitledError? {
        switch self {
        case .opCodeNotSupported: return TitledError(message: "Operation not supported")
        case .noRecordsFound: return TitledError(message: "No records found")
        case .operatorNotSupported: return TitledError(message: "Operator not supported")
        case .invalidOperator: return TitledError(message: "Invalid operator")
        case .operandNotSupported: return TitledError(message: "Operand not supported")
        case .invalidOperand: return TitledError(message: "Invalid operator")
        case .abortUnsuccessful: return TitledError(message: "Abort unsuccessful")
        case .procedureNotCompleted: return TitledError(message: "Procedure not completed")
        default: return nil
        }
    }
    
}
