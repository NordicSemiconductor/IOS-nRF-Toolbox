//
//  Manifest.swift
//  Pods
//
//  Created by Mostafa Berg on 28/07/16.
//
//

class SoftdeviceBootloaderInfo: ManifestFirmwareInfo {
    var blSize: UInt32 = 0
    var sdSize: UInt32 = 0
    
    override init(withDictionary aDictionary : Dictionary<String, AnyObject>) {
        super.init(withDictionary: aDictionary)
        if aDictionary.keys.contains("bl_size") {
            blSize = (aDictionary["bl_size"]!).uint32Value
        }
        if aDictionary.keys.contains("sd_size") {
            sdSize = (aDictionary["sd_size"]!).uint32Value
        }
    }
}
