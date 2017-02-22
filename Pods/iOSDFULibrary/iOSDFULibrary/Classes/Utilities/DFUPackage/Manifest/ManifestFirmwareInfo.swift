//
//  ManifestFirmwareInfo.swift
//  Pods
//
//  Created by Mostafa Berg on 28/07/16.
//
//

class ManifestFirmwareInfo: NSObject {
    var binFile: String? = nil
    var datFile: String? = nil
    
    var valid: Bool {
        return binFile != nil // && datFile != nil The init packet was not required before SDK 7.1
    }
    
    init(withDictionary aDictionary : Dictionary<String, AnyObject>) {
        if aDictionary.keys.contains("bin_file") {
            binFile = String(describing: aDictionary["bin_file"]!)
        }
        if aDictionary.keys.contains("dat_file") {
            datFile = String(describing: aDictionary["dat_file"]!)
        }
    }
}
