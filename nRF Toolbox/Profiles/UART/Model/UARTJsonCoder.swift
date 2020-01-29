//
//  UARTJsonCoder.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 21/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation

private struct UARTModelContainer: Codable {
    enum ModelType: String, Codable {
        case empty, text, data
        
        var modelType: UARTCommandModel.Type {
            switch self {
            case .empty: return EmptyModel.self
            case .data: return DataCommand.self
            case .text: return TextCommand.self
            }
        }
    }
    
    let type: ModelType
    let data: Data
}

class UARTModelEncoder: JSONEncoder {
    enum Error: Swift.Error {
        case unknownCommandType
    }
    
    func encode(model: UARTCommandModel) throws -> Data {
        let type: UARTModelContainer.ModelType
        let data: Data
        switch model {
        case let m as EmptyModel:
            type = .empty
            data = try encode(m)
        case let m as TextCommand:
            type = .text
            data = try encode(m)
        case let m as DataCommand:
            type = .data
            data = try encode(m)
        default: throw Error.unknownCommandType
        }
        
        return try encode(UARTModelContainer(type: type, data: data))
    }
}

class UARTModelDecoder: JSONDecoder {
    func decodeModel(from data: Data) throws -> UARTCommandModel {
        let container = try decode(UARTModelContainer.self, from: data)
        let modelData = container.data
        return try {
            switch container.type {
            case .empty: return try decode(EmptyModel.self, from: modelData)
            case .data: return try decode(DataCommand.self, from: modelData)
            case .text: return try decode(TextCommand.self, from: modelData)
            }
        }()
    }
}
