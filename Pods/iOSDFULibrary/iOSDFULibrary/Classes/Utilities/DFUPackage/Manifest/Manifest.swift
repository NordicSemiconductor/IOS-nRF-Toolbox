//
//  Manifest.swift
//  Pods
//
//  Created by Mostafa Berg on 28/07/16.
//
//

class Manifest: NSObject {
    var application: ManifestFirmwareInfo?
    var softdevice:  ManifestFirmwareInfo?
    var bootloader:  ManifestFirmwareInfo?
    var softdeviceBootloader: SoftdeviceBootloaderInfo?
    
    var valid: Bool {
        // The manifest.json file may specify only:
        // 1. a softdevice, a bootloader, or both combined (with, or without an app)
        // 2. only the app
        let hasApplication = application != nil
        var count = 0
        
        count += softdevice != nil ? 1 : 0
        count += bootloader != nil ? 1 : 0
        count += softdeviceBootloader != nil ? 1 : 0
        
        return count == 1 || (count == 0 && hasApplication)
    }
    
    init(withJsonString aString : String) {
        do {
            let data = aString.data(using: String.Encoding.utf8)
            let aDictionary = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! Dictionary<String, AnyObject>
            
            let mainObject = aDictionary["manifest"] as! Dictionary<String, AnyObject>
            if mainObject.keys.contains("application") {
                let dictionary = mainObject["application"] as? Dictionary<String, AnyObject>
                self.application = ManifestFirmwareInfo(withDictionary: dictionary!)
            }
            if mainObject.keys.contains("softdevice_bootloader") {
                let dictionary = mainObject["softdevice_bootloader"] as? Dictionary<String, AnyObject>
                self.softdeviceBootloader = SoftdeviceBootloaderInfo(withDictionary: dictionary!)
            }
            if mainObject.keys.contains("softdevice"){
                let dictionary = mainObject["softdevice"] as? Dictionary<String, AnyObject>
                self.softdevice = ManifestFirmwareInfo(withDictionary: dictionary!)
            }
            if mainObject.keys.contains("bootloader"){
                let dictionary = mainObject["bootloader"] as? Dictionary<String, AnyObject>
                self.bootloader = ManifestFirmwareInfo(withDictionary: dictionary!)
            }

        } catch {
            print("an error occured while parsing manifest.json \(error)")
        }        
    }
}
