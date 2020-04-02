//
// Created by Nick Kibysh on 29/10/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth
import AVFoundation
import UserNotifications

private extension Identifier where Value == Section {
    static let findMeSection: Identifier<Section> = "FindMeSection"
    static let approxDistanceSection: Identifier<Section> = "ApproxDistanceSection"
}

private extension Identifier where Value == UNNotification {
    static let notification: Identifier<UNNotification> = "Notification.Id"
}

class ProximityViewController: PeripheralTableViewController {

    override var peripheralDescription: PeripheralDescription { .proximity }
    override var internalSections: [Section] { [findMeSection, chartSection] }
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

    private lazy var findMeSection = FindMeSection(id: .findMeSection) { findMe in
        var val : UInt8 = findMe ? 2 : 0
        let data = Data(bytes: &val, count: 1)
        self.activePeripheral?.writeValue(data, for: self.immediateAlertCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)

        self.tableView.reloadData()
    }

    private var chartSection = ApproxDistanceSection(id: .approxDistanceSection)
    private var peripheralManager: CBPeripheralManager!

    var immediateAlertCharacteristic: CBCharacteristic!

    private var txCharacteristic: CBCharacteristic?
    private var txValue: Int?
    private var rssi: Int?
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCellNib(cell: FindMeTableViewCell.self)
        audioPlayer?.prepareToPlay()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)

        tableView.register(DetailsTableViewCell.self, forCellReuseIdentifier: "DetailsTableViewCell")
        tableView.register(LinearChartTableViewCell.self, forCellReuseIdentifier: "LinearChartTableViewCell")

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { b, error in

        }

    }
    
    override func didDiscover(characteristic: CBCharacteristic, for service: CBService, peripheral: CBPeripheral) {
        super.didDiscover(characteristic: characteristic, for: service, peripheral: peripheral)
        switch (service.uuid, characteristic.uuid) {
        case (.immediateAlertService, .proximityAlertLevelCharacteristic):
            immediateAlertCharacteristic = characteristic
        case (.linkLossService, .proximityAlertLevelCharacteristic):
            var val = UInt8(1)
            let data = Data(bytes: &val, count: 1)
            peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        case (.txPowerLevelService, .txPowerLevelCharacteristic):
            txCharacteristic = characteristic
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

    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
        guard peripheral == activePeripheral else { return }
        guard error == nil else {
            SystemLog(category: .ble, type: .error).log(message: "RSSI Reader error: \(error!.localizedDescription)")
            return
        }

        // TODO: Rid off RSSI
        rssi = peripheral.rssi?.intValue
        if let rssi = self.rssi, let tx = txValue {
            chartSection.update(rssi: rssi, tx: tx)
        }
    }

    override func didUpdateValue(for characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case .txPowerLevelCharacteristic:
            let value: Int8? = characteristic.value?.read()
            txValue = value.map(Int.init)
            tableView.reloadData()
        default:
            super.didUpdateValue(for: characteristic)
        }
    }

    override func statusDidChanged(_ status: PeripheralStatus) {
        super.statusDidChanged(status)
        switch status {
        case .connected(_):
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                self.activePeripheral?.readRSSI()
                if let txCharacteristic = self.txCharacteristic {
                    self.activePeripheral?.readValue(for: txCharacteristic)
                }
                self.findMeSection.update(rssi: self.rssi, tx: self.txValue)

                if let rssi = self.rssi, let tx = self.txValue {
                    self.chartSection.update(rssi: rssi, tx: tx)
                }
                self.tableView.reloadData()
            }
            timer?.fire()
        case .disconnected, .poweredOff:
            timer?.invalidate()
            txValue = nil
            rssi = nil
            chartSection.reset()
        default:
            break
        }
    }
}

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
