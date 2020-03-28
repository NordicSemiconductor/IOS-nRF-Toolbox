//
//  DFUFileManager.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 23/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOSDFULibrary

protocol DFUPacket {
    var url: URL { get }
    var name: String { get }
}

struct DFUDistributionPacket: DFUPacket {
    let url: URL
    var name: String {
        url.lastPathComponent
    }
    var firmware: DFUFirmware? = nil
}

class DFUFileManager<T: DFUPacket> {
    
    func readList() throws -> [T] {
        fatalError("\(#function): override me!")
    }
    
    func handleUrl(_ url: URL) -> Bool {
        return false
    }
    
    func checkAndMoveFiles() throws -> [T] {
        fatalError("\(#function): override me!")
    }
}

class DFUPacketManager: DFUFileManager<DFUDistributionPacket> {
    private var fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    private func documentDir() throws -> URL {
        return try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    private func inboxDir() throws -> URL {
        return try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    private func dfuDir() throws -> URL {
        let dfuDir = try documentDir().appendingPathComponent("dfu")
        var isDir : ObjCBool = false
        if !fileManager.fileExists(atPath: dfuDir.path, isDirectory: &isDir) {
            try fileManager.createDirectory(atPath: dfuDir.path, withIntermediateDirectories: true, attributes: nil)
        }
        
        return dfuDir
    }
    
    override func handleUrl(_ url: URL) -> Bool {
        guard url.isFileURL,
            url.pathExtension == "zip",
            let newUrl = try? dfuDir().appendingPathComponent(url.lastPathComponent) else {
                return false
        }
        
        do {
            try fileManager.moveItem(at: url, to: newUrl)
        } catch let error {
            Log(category: .util, type: .error).log(message: error.localizedDescription)
            return false
        }
        
        return true
    }
    
    override func readList() throws -> [DFUDistributionPacket] {
        return try content(of: try dfuDir())
    }
    
    func content(of dir: URL) throws -> [DFUDistributionPacket] {
        return try fileManager
            .contentsOfDirectory(atPath: dir.path)
        .compactMap { str -> DFUDistributionPacket? in
            let fileUrl = dir.appendingPathComponent(str)
            guard let firmware = DFUFirmware(urlToZipFile: fileUrl) else {
                return nil
            }
            return DFUDistributionPacket(url: fileUrl, firmware: firmware)
        }
    }
    
}
