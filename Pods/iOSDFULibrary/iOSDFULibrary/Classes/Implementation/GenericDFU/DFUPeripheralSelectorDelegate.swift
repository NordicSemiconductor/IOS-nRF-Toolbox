//
//  DFUPeripheralSelector.swift
//  Pods
//
//  Created by Mostafa Berg on 16/06/16.
//
//

import CoreBluetooth

/**
 The DFU Target matcher is used when both the Softdevice (or Softdevice and Bootloader) and Application
 are going to be updated.
 
 This library supports sending both BIN files from a ZIP Distribution Packet automatically.
 However, when sending the Softdevice update, the DFU Bootloader removes the current application in order to
 make space for the new Softdevice firmware. When the new Softdevice is flashed the bootloader restarts the device
 and, as there is no application anymore, starts advertising in DFU Bootloader mode.
 
 Since SDK 8.0.0, to solve caching problem on a host, the bootloader starts to advertise with an address incremented by 1.
 The DFU Library has to scan for a peripheral with this new address. However, as iOS does not expose the device
 address in the public CoreBluetooth API, address matching, used on Android, can not be used.
 Instead, this matcher is used. The DFU Service will start scanning for peripherals with a UUID filter, where
 the list of required UUID is returned by the `filterBy()` method. If your device in the Bootloader mode
 does not advertise with any service UUIDs, or this is not enough, you may select a target device
 by their advertising packet or RSSI.
 */
public protocol DFUPeripheralSelectorDelegate : class {
    /**
     Returns whether the given peripheral is a device in DFU Bootloader mode.
     
     - parameter peripheral:      the peripheral to be checked
     - parameter advertisingData: scanned advertising data
     - parameter RSSI:            received signal strength indication in dBm
     
     - returns: true (YES) if given peripheral is what service is looking for
     */
    func select(_ peripheral:CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) -> Bool
    
    /**
     Returns an optional list of services that the scanner will use to filter advertising packets
     when scanning for a device in DFU Bootloader mode. To find out what UUID you should return,
     switch your device to DFU Bootloader mode (with a button!) and check the advertisment packet.
     The result of this method will be applied to
     `centralManager.scanForPeripheralsWithServices([CBUUID]?, options: [String : AnyObject]?)`
     
     - returns: an optional list of services or nil
     */
    func filterBy() -> [CBUUID]?
}
