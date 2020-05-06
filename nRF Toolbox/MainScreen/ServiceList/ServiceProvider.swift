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

protocol ServiceProvider {
    var sections: [ServiceSection] { get }
}

struct ServiceSection {
    let title: String
    let services: [ServiceType]
}

struct DefaultServiceProvider: ServiceProvider {
    
    private static func loadServicesFromFile<T: ServiceType & Decodable>(_ fileName: String) -> [T] {
        let errorLogger = SystemLog(category: .ui, type: .error)
        guard let fileUrl = Bundle.main.url(forResource: fileName, withExtension: "plist") else {
            errorLogger.log(message: "Could not find \"\(fileName).plist\"")
            return []
        }
        do {
            let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
            return try PropertyListDecoder().decode([T].self, from: data)
        } catch let error {
            SystemLog(category: .ui, type: .error).log(message: "Could not load services: \(error.localizedDescription)")
            return []
        }
    }
    
    let sections: [ServiceSection] = {
        let bleServices: [BLEService] = DefaultServiceProvider.loadServicesFromFile("BLEServiceList")
        let utilsServices: [BLEService] = DefaultServiceProvider.loadServicesFromFile("InteractionServiceList")
        let links: [LinkService] = DefaultServiceProvider.loadServicesFromFile("Links")
        return [
            ServiceSection(title: "Bluetooth Services", services: bleServices),
            ServiceSection(title: "Utils Services", services: utilsServices),
            ServiceSection(title: "Links", services: links)
        ]
    }()
    
}
