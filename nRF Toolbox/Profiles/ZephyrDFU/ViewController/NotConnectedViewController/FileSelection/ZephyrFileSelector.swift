//
//  ZephyrFileSelector.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 17/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

struct ZephyrPacket: DFUPacket {
    var url: URL
    var data: Data
    
    var name: String {
        return url.lastPathComponent
    }
}

class ZephyrFileManager: DFUFileManager<ZephyrPacket> {
    private var fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    private func tmpDir() throws -> URL {
        return try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    override func checkAndMoveFiles() throws -> [ZephyrPacket] {
        let packetDir = try tmpDir().appendingPathComponent("dfu")
        
        return try self.content(of: try tmpDir())
            .map { (packet) -> ZephyrPacket in
                let newUrl = packetDir.appendingPathComponent(packet.name)
                try fileManager.moveItem(atPath: packet.url.path, toPath: newUrl.path)
                return ZephyrPacket(url: newUrl, data: packet.data)
            }
    }
    
    override func readList() throws -> [ZephyrPacket] {
        let packetDir = try tmpDir().appendingPathComponent("zephyr_dfu")
        return try content(of: packetDir)
    }
    
    func content(of dir: URL) throws -> [ZephyrPacket] {
        return try fileManager
        .contentsOfDirectory(atPath: try tmpDir().path)
        .compactMap { str -> ZephyrPacket? in
            guard let url = URL(string: str), url.pathExtension == "bin" else {
                return nil
            }
            let data = try Data(contentsOf: url)
            
            return ZephyrPacket(url: url, data: data)
        }
    }
}

class ZephyrFileSelector: FileSelectorViewController<Data> {
    weak var router: ZephyrDFURouterType?
    
    init(router: ZephyrDFURouterType? = nil, documentPicker: DocumentPicker<Data>) {
        self.router = router
        super.init(documentPicker: documentPicker)
        filterExtension = "bin"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func documentWasOpened(document: Data) {
        router?.goToUpdateScreen(data: document)
    }
    
    override func fileWasSelected(file: File) {
        do {
            let data = try Data(contentsOf: file.url)
            documentWasOpened(document: data)
        } catch let error {
            displayErrorAlert(error: error)
        }
    }
}

