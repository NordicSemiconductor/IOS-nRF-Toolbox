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
import UIKit.UIImage
import AEXML

protocol UARTCommandModel: Codable, XMLRepresentable, UARTMacroElement, NordicTextTableViewCellModel {
    var image: CommandImage { get }
    var title: String { get }
    var data: Data { get }
}

extension UARTCommandModel {
    var image: UIImage? {
        return self.image.image
    }
    
    var text: String? {
        return self.title
    }
}

protocol XMLRepresentable {
    var xml: AEXMLElement { get }
}

enum EOL: Codable {
    static let CR: UInt8 = 0x0d
    static let LF: UInt8 = 0x0a
    
    case cr, lf, crlf, none
    
    var data: Data {
        switch self {
        case .cr:
            Data([Self.CR])
        case .lf:
            Data([Self.LF])
        case .crlf:
            Data([Self.CR, Self.LF])
        case .none:
            Data()
        }
    }
    
    var name: String {
        switch self {
        case .cr:
            return "CR"
        case .lf:
            return "LF"
        case .crlf:
            return "CR+LF"
        case .none:
            return "None"
        }
    }
    
    init(data: Data) {
        switch data {
        case Data([Self.CR]): self = .cr
        case Data([Self.LF]): self = .lf
        case Data([Self.CR, Self.LF]): self = .crlf
        default: self = .none
        }
    }
    
    init(name: String) {
        switch name {
        case EOL.cr.name: self = .cr
        case EOL.lf.name: self = .lf
        case EOL.crlf.name: self = .crlf
        default: self = .none
        }
    }
}

struct EmptyModel: UARTCommandModel, Equatable {
    var xml: AEXMLElement {
        AEXMLElement(name: "command")
    }
    
    let image: CommandImage = .empty
    let title: String = ""
    let data: Data = Data()
    
    init() { }
    init(from decoder: Decoder) throws { }
    func encode(to encoder: Encoder) throws { }
    
    static func ==(lhs: EmptyModel, rhs: EmptyModel) -> Bool { true }
}

struct TextCommand: UARTCommandModel, Equatable {
    var xml: AEXMLElement {
        AEXMLElement(name: "command", value: text, attributes: [
            "icon":image.name,
            "active":"true",
            "eol":eol.name,
            "type":"text",
            "system_icon":image.systemIcon?.name ?? ""
        ])
    }
    
    var title: String { text.split(whereSeparator: \.isNewline).joined() }
    
    var data: Data {
        text.data(using: .utf8)! + eol.data
    }
    
    let text: String
    let image: CommandImage
    var eol: EOL = .none
}

struct DataCommand: UARTCommandModel, Equatable {
    var xml: AEXMLElement {
        AEXMLElement(name: "command", value: data.hexString, attributes: [
            "icon":image.name,
            "active":"true",
            "eol":"none",
            "type":"data",
            "system_icon":image.systemIcon?.name ?? ""
        ])
    }
    
    var title: String { "0x" + data.hexEncodedString().uppercased() }
    
    let data: Data
    let image: CommandImage
}
