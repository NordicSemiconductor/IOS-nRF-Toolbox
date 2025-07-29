//
//  OpCode.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 02/08/2023.
//  Created by Dinesh Harjani on 29/7/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

import Foundation

// MARK: - SCControlPointOpCode
    
public enum SCControlPointOpCode: UInt8, CustomStringConvertible {
    case setCumulativeValue                 = 0x01
    case startSensorCalibration             = 0x02
    case updateSensorLocation               = 0x03
    case requestSupportedSensorLocations    = 0x04
    case responseCode                       = 0x10
    
    public var data: Data {
        Data([self.rawValue])
    }

    public var description: String {
        switch self {
        case .setCumulativeValue:
            return "Set Cumulative Value"
        case .startSensorCalibration:
            return "Start Sensor Calibration"
        case .updateSensorLocation:
            return "Update Sensor Location"
        case .requestSupportedSensorLocations:
            return "Request Supported Sensor Locations"
        case .responseCode:
            return "Response Code"
        }
    }
}

// MARK: - SCControlPointResponse

public struct SCControlPointResponse {
    public var opCode: SCControlPointOpCode
    public var responseValue: SCControlPointResponseCode
    public var parameter: Data?

    public init(opCode: SCControlPointOpCode, responseValue: SCControlPointResponseCode, parameter: Data?) {
        self.opCode = opCode
        self.responseValue = responseValue
        self.parameter = parameter
    }

    public init?(from data: Data) {
        guard data.count >= 2 else { return nil }
        guard let opCode = SCControlPointOpCode(rawValue: Data(data)[1]) else {
            return nil
        }
        self.opCode = opCode
        guard let responseValue = SCControlPointResponseCode(rawValue: Data(data)[2]) else {
            return nil
        }
        self.responseValue = responseValue
        if data.count > 3 {
            parameter = Data(data).subdata(in: 3 ..< data.count)
        }
    }

    public var data: Data {
        var data = Data()
        data.append(SCControlPointOpCode.responseCode.data)
        data.append(opCode.data)
        data.append(responseValue.rawValue)
        if let parameter {
            data.append(parameter)
        }
        return data
    }
}

// MARK: - SCControlPointResponseCode

public enum SCControlPointResponseCode: UInt8, CustomStringConvertible {
    case success = 0x01
    case opCodeNotSupported = 0x02
    case invalidParameter = 0x03
    case operationFailed = 0x04

    public var description: String {
        switch self {
        case .success:
            return "Success"
        case .opCodeNotSupported:
            return "Op Code Not Supported"
        case .invalidParameter:
            return "Invalid Parameter"
        case .operationFailed:
            return "Operation Failed"
        }
    }
}
