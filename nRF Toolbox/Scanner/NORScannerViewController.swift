//
//  NORScannerViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 28/04/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth

class NORScannerViewController: UIViewController, CBCentralManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    let dfuServiceUUIDString  = "00001530-1212-EFDE-1523-785FEABCD123"
    let ANCSServiceUUIDString = "7905F431-B5CE-4E99-A40F-4B1E122D00D0"

    //MARK: - ViewController Properties
    var bluetoothManager : CBCentralManager?
    var delegate         : protocol<NORScannerDelegate>?
    var filterUUID       : CBUUID?
    var peripherals      : NSMutableArray?
    var timer            : NSTimer?
    
    @IBOutlet weak var devicesTable: UITableView!
    @IBOutlet weak var emptyView: UIView!
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @objc func timerFire() {
        if peripherals?.count > 0 {
            emptyView.hidden = true
            devicesTable.reloadData()
        }
    }
    
    func getRSSIImage(RSSI anRSSIValue: Int32) -> UIImage {
        
        var image: UIImage
        
        if (anRSSIValue < -90) {
            image = UIImage(named: "Signal_0")!
        }else if (anRSSIValue < -70) {
            image = UIImage(named: "Signal_1")!
        }else if (anRSSIValue < -50) {
            image = UIImage(named: "Signal_2")!
        }else{
            image = UIImage(named: "Signal_3")!
        }
        
        return image
    }
    
    func getConnectedPeripherals() -> NSArray {
        var retreivedPeripherals : NSArray

        if filterUUID == nil {
            let dfuServiceUUID       = CBUUID(string: dfuServiceUUIDString)
            let ancsServiceUUID      = CBUUID(string: ANCSServiceUUIDString)
            retreivedPeripherals     = (bluetoothManager?.retrieveConnectedPeripheralsWithServices([dfuServiceUUID, ancsServiceUUID]))!
        } else {
            retreivedPeripherals     = (bluetoothManager?.retrieveConnectedPeripheralsWithServices([filterUUID!]))!
        }

        return retreivedPeripherals
    }
    
    /*!
     * @brief Starts scanning for peripherals with rscServiceUUID
     * @param enable If YES, this method will enable scanning for bridge devices, if NO it will stop scanning
     * @return true if success, false if Bluetooth Manager is not in CBCentralManagerStatePoweredOn state.
     */
    func scanForPeripherals(enable:Bool) -> Bool {
        guard bluetoothManager?.state == CBCentralManagerState.PoweredOn else {
            return false
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            if enable == true {
                let options: NSDictionary = NSDictionary(objects: [NSNumber(bool: true)], forKeys: [CBCentralManagerScanOptionAllowDuplicatesKey])
                if self.filterUUID != nil {
                    self.bluetoothManager?.scanForPeripheralsWithServices([self.filterUUID!], options: options as? [String : AnyObject])
                } else {
                    self.bluetoothManager?.scanForPeripheralsWithServices(nil, options: options as? [String : AnyObject])
                }
                self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(self.timerFire), userInfo: nil, repeats: true)
            } else {
                self.timer?.invalidate()
                self.timer = nil
                self.bluetoothManager?.stopScan()
            }
        }
        
        return true
    }
    
    //MARK: - ViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        peripherals = NSMutableArray(capacity: 8)
        devicesTable.delegate = self
        devicesTable.dataSource = self
        
        let activityIndicatorView              = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityIndicatorView.hidesWhenStopped = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicatorView)
        
        activityIndicatorView.startAnimating()
        
        let centralQueue = dispatch_queue_create("no.nordicsemi.nRFToolBox", DISPATCH_QUEUE_SERIAL)
        bluetoothManager = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        let success = self.scanForPeripherals(false)
        if !success {
            print("Bluetooth is powered off!")
        }

        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        super.viewWillDisappear(animated)
    }

    //MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard peripherals != nil else {
            return 0
        }

        return peripherals!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCellWithIdentifier("Cell")
        
        //Update cell content
        let scannedPeripheral = peripherals?.objectAtIndex(indexPath.row) as! NORScannedPeripheral
        aCell?.textLabel?.text = scannedPeripheral.name()
        if scannedPeripheral.isConnected == true {
            aCell?.imageView?.image = UIImage(named: "Connected")
        }else{
            let RSSIImage = self.getRSSIImage(RSSI: scannedPeripheral.RSSI)
            aCell?.imageView?.image = RSSIImage
        }
        
        return aCell!
    }

    //MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        bluetoothManager?.stopScan()
        self.dismissViewControllerAnimated(true, completion: nil)
        // Call delegate method
        self.delegate?.centralManagerDidSelectPeripheral(withManager: bluetoothManager!, andPeripheral: (peripherals?.objectAtIndex(indexPath.row).peripheral)!)

    }
    
    //MARK: - CBCentralManagerDelgate
    func centralManagerDidUpdateState(central: CBCentralManager) {
        guard central.state == CBCentralManagerState.PoweredOn else {
            print("Bluetooth is porewed off")
            return
        }

        peripherals = NSMutableArray(array: self.getConnectedPeripherals())
        let success = self.scanForPeripherals(true)
        if !success {
            print("Bluetooth is powered off!")
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        if advertisementData[CBAdvertisementDataIsConnectable]?.boolValue == true {
            dispatch_async(dispatch_get_main_queue(), { 
                var sensor = NORScannedPeripheral(withPeripheral: peripheral, andRSSI: RSSI.intValue, andIsConnected: false)
                if ((self.peripherals?.containsObject(sensor)) == false) {
                    self.peripherals?.addObject(sensor)
                }else{
                    sensor = (self.peripherals?.objectAtIndex((self.peripherals?.indexOfObject(sensor))!))! as! NORScannedPeripheral
                    sensor.RSSI = RSSI.intValue
                }
            })
        }
    }
}
