//
// Created by Nick Kibysh on 29/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth
import AVFoundation
import UserNotifications

extension Identifier where Value == UNNotification {
    static let notification: Identifier<Self> = "Identifier.UNNotification.Proximity"
}

class ProximityViewController: PeripheralViewController {
    
    @IBOutlet private var distanceView: DistanceView!
    @IBOutlet private var distanceLabel: UILabel!
    @IBOutlet private var rssiView: SignalStrengthView!
    @IBOutlet private var findMeBtn: NordicButton!
    @IBOutlet private var disconnectBtn: NordicButton!

    override var peripheralDescription: PeripheralDescription { .proximity }
    override var navigationTitle: String { "Proximity" }

    let audioPlayer: AVAudioPlayer? = {
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "high", ofType: "mp3")!)
        do {
            return try AVAudioPlayer(contentsOf: url)
        } catch let error {
            SystemLog(category: .util, type: .error).log(message: error.localizedDescription)
            return nil
        }
    }()

    private var peripheralManager: CBPeripheralManager!

    var immediateAlertCharacteristic: CBCharacteristic!

    private var txValue: Int?
    private var rssi: Int?
    private var timer: Timer?
    
    private var rssiArr: [Int] = []
    private var findMeEnabled: Bool = false
    
    @IBAction func findMe() {
        guard let immediateAlertCharacteristic = self.immediateAlertCharacteristic else {
            return
        }
        var val : UInt8 = findMeEnabled ? 0 : 2
        let data = Data(bytes: &val, count: 1)
        self.activePeripheral?.writeValue(data, for: immediateAlertCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
        
        findMeEnabled.toggle()
        let title = findMeEnabled ? "SILENT ME" : "FIND ME"
        findMeBtn.setTitle(title, for: .normal)
    }
    
    @IBAction func disconnectAction() {
        disconnect()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        findMeBtn.style = .mainAction
        audioPlayer?.prepareToPlay()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        disconnectBtn.style = .destructive

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { b, error in
            
        }
    }
    
    override func didDiscover(characteristic: CBCharacteristic, for service: CBService, peripheral: CBPeripheral) {
        super.didDiscover(characteristic: characteristic, for: service, peripheral: peripheral)
        switch (service.uuid, characteristic.uuid) {
        case (.immediateAlertService, .proximityAlertLevelCharacteristic):
            immediateAlertCharacteristic = characteristic
            self.findMeBtn.isEnabled = true
        case (.linkLossService, .proximityAlertLevelCharacteristic):
            var val = UInt8(1)
            let data = Data(bytes: &val, count: 1)
            peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        case (.txPowerLevelService, .txPowerLevelCharacteristic):
            peripheral.readValue(for: characteristic)
        default:
            break
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            SystemLog(category: .ble, type: .error).log(message: "Did not write characteristic \(characteristic), error: \(error.debugDescription)")
            return
        }
    }

    override func didUpdateValue(for characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case .txPowerLevelCharacteristic:
            let value: Int8? = characteristic.value?.read()
            txValue = value.map(Int.init)
            self.update(rssi: rssi, txValue: txValue)
        default:
            super.didUpdateValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let e = error {
            SystemLog(category: .ble, type: .error).log(message: "RSSI Reader error: \(e.localizedDescription)")
            displayErrorAlert(error: e)
            return
        }
        
        rssiArr.append(RSSI.intValue)
        rssi = rssiArr.reduce(0, +) / rssiArr.count
        
        if rssiArr.count > 20 {
            rssiArr.removeFirst()
        }
        
        update(rssi: rssi, txValue: txValue)
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
            self.activePeripheral?.readRSSI()
        }
        timer?.fire()
    }

    override func statusDidChanged(_ status: PeripheralStatus) {
        super.statusDidChanged(status)
        switch status {
        case .connected(_):
            self.activePeripheral?.readRSSI()
        case .disconnected, .poweredOff:
            timer?.invalidate()
            txValue = nil
            rssi = nil
            
            rssiView.filledBars = 0
            distanceView.unfilledSectors = distanceView.numberOfSectors
            distanceLabel.text = "Unknown"
            
            findMeBtn.isEnabled = false
        default:
            break
        }
    }
}

//MARK: - Signal Strength
extension ProximityViewController {
    private func update(rssi value: Int?, txValue: Int?) {
        guard let rssi = value else {
            rssiView.filledBars = 0
            return
        }
        
        let rssiSectors = Int((RSSI.percent(from: rssi) * Double(rssiView.numberOfBars)).rounded())
        rssiView.filledBars = rssiSectors
        
        if let tx = txValue {
            SystemLog(category: .ble, type: .debug).log(message: "Proximity Tx: \(tx)")
            let distance = pow(10, (Double(tx - rssi) / 20.0))
            let distanceUnitVal = Measurement<UnitLength>(value: distance, unit: .millimeters)
            let formatter = MeasurementFormatter()
            let numberFormatter = NumberFormatter()
            numberFormatter.maximumFractionDigits = 2
            formatter.numberFormatter = numberFormatter
            formatter.unitOptions = .naturalScale
            distanceLabel.text = formatter.string(from: distanceUnitVal)
            
            let distancePercentage = positionInDistanceRange(distance: distance)
            distanceView.unfilledSectors = distanceView.numberOfSectors - Int((distancePercentage * Double(distanceView.numberOfSectors)).rounded())
            
        } else {
            let rssiDistance = Int((RSSI.percent(from: rssi) * Double(distanceView.numberOfSectors)).rounded())
            distanceView.unfilledSectors = distanceView.numberOfSectors - rssiDistance
        }
        
        
    }
    
    func positionInDistanceRange(distance: Double, min: Double = 200, max: Double = 5_000) -> Double {
        if distance > max {
            return 0
        } else if distance < min {
            return 1
        }
        
        let rangeDistance = max - min
        return 1 - (distance / rangeDistance)
    }
}

//MARK: - Player
extension ProximityViewController {
    private func stopSound() {
        if case .background = UIApplication.shared.applicationState {
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier<UNNotification>.notification.string])
            return
        }
        audioPlayer?.stop()
    }

    private func playSoundOnce(repeat: Bool) {

        if case .background = UIApplication.shared.applicationState {
            let content = UNMutableNotificationContent()
            content.title = "Proximity"
            content.subtitle = activePeripheral?.name.flatMap { "Phone found using \($0)" } ?? "Find iPhone feature was enabled"

            content.sound = UNNotificationSound(named: UNNotificationSoundName("high.mp3"))

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: Identifier<UNNotification>.notification.string, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
            return
        }

        audioPlayer?.play()
    }
}

extension ProximityViewController: CBPeripheralManagerDelegate {
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            let service = CBMutableService(type: .immediateAlertService, primary: true)
            let characteristic = CBMutableCharacteristic(
                type: .proximityAlertLevelCharacteristic,
                properties: .writeWithoutResponse,
                value: nil,
                permissions: .writeable)
            service.characteristics = [characteristic]
            peripheralManager.add(service)
        default:
            break
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        guard let attributeRequest = requests.first,
              attributeRequest.characteristic.uuid == .proximityAlertLevelCharacteristic else {
            return
        }

        let alertLevel: UInt8 = attributeRequest.value!.read()
        switch alertLevel {
        case 0:
            SystemLog(category: .ble, type: .debug).log(message: "No Alert")
            stopSound()
        case 1:
            SystemLog(category: .ble, type: .debug).log(message: "Low Alert")
            playSoundOnce(repeat: false)
        case 2:
            SystemLog(category: .ble, type: .debug).log(message: "High Alert")
            playSoundOnce(repeat: true)
        default:
            break
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        SystemLog(category: .ble, type: .debug).log(message: "Will Restore characteristic: \(dict)")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            SystemLog(category: .ble, type: .error).log(message: error.localizedDescription)
        } else {
            SystemLog(category: .ble, type: .debug).log(message: "added service: \(service.debugDescription)")
        }
    }
}
