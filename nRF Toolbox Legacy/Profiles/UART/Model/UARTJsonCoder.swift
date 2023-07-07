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
