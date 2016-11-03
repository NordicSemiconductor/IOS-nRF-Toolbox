//
//  NORHRMViewController.swift
//  nRF Toolbox
//
//  Created by Mostafa Berg on 04/05/16.
//  Copyright © 2016 Nordic Semiconductor. All rights reserved.
//

import UIKit
import CoreBluetooth
import CorePlot
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


class NORHRMViewController: NORBaseViewController, CBCentralManagerDelegate, CBPeripheralDelegate, NORScannerDelegate, CPTPlotDataSource, CPTPlotSpaceDelegate {

    //MARK: - Properties
    var bluetoothManager                : CBCentralManager?
    var hrValues                        : NSMutableArray?
    var xValues                         : NSMutableArray?
    var plotXMaxRange                   : Int?
    var plotXMinRange                   : Int?
    var plotYMaxRange                   : Int?
    var plotYMinRange                   : Int?
    var plotXInterval                   : Int?
    var plotYInterval                   : Int?
    var isBluetoothOn                   : Bool?
    var isDeviceConnected               : Bool?
    var isBackButtonPressed             : Bool?
    var batteryServiceUUID              : CBUUID
    var batteryLevelCharacteristicUUID  : CBUUID
    var hrServiceUUID                   : CBUUID
    var hrMeasurementCharacteristicUUID : CBUUID
    var hrLocationCharacteristicUUID    : CBUUID
    var linePlot                        : CPTScatterPlot?
    var graph                           : CPTGraph?
    var peripheral                      : CBPeripheral?
    
    //MARK: - UIVIewController Outlets
    @IBOutlet weak var verticalLabel: UILabel!
    @IBOutlet weak var battery: UIButton!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var connectionButton: UIButton!
    @IBOutlet weak var hrLocation: UILabel!
    @IBOutlet weak var hrValue: UILabel!
    @IBOutlet weak var graphView: CPTGraphHostingView!
    
    //MARK: - UIVIewController Actions
    @IBAction func connectionButtonTapped(_ sender: AnyObject) {
        if peripheral != nil
        {
            bluetoothManager?.cancelPeripheralConnection(peripheral!)
        }
    }
    @IBAction func aboutButtonTapped(_ sender: AnyObject) {
        self.showAbout(message: NORAppUtilities.getHelpTextForService(service: .hrm))
    }
    //MARK: - UIViewController delegate
    required init?(coder aDecoder: NSCoder) {
        hrServiceUUID                    = CBUUID(string: NORServiceIdentifiers.hrsServiceUUIDString)
        hrMeasurementCharacteristicUUID  = CBUUID(string: NORServiceIdentifiers.hrsHeartRateCharacteristicUUIDString)
        hrLocationCharacteristicUUID     = CBUUID(string: NORServiceIdentifiers.hrsSensorLocationCharacteristicUUIDString)
        batteryServiceUUID               = CBUUID(string: NORServiceIdentifiers.batteryServiceUUIDString)
        batteryLevelCharacteristicUUID   = CBUUID(string: NORServiceIdentifiers.batteryLevelCharacteristicUUIDString)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Rotate the vertical label
        verticalLabel.transform = CGAffineTransform(translationX: -120.0, y: 0.0).rotated(by: CGFloat(-M_PI_2))
        isBluetoothOn           = false
        isDeviceConnected       = false
        isBackButtonPressed     = false
        peripheral              = nil
        
        hrValues = NSMutableArray()
        xValues  = NSMutableArray()
        
        initLinePlot()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if peripheral != nil && isBackButtonPressed == true
        {
            bluetoothManager?.cancelPeripheralConnection(peripheral!)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isBackButtonPressed = true
    }

    //MARK: - CTPPlot Implementation
    
    func initLinePlot() {
        //Initialize and display Graph (x and y axis lines)
        graph = CPTXYGraph(frame: graphView.bounds)
        self.graphView.hostedGraph = self.graph;
        
        //apply styling to Graph
        graph?.apply(CPTTheme(named: CPTThemeName.plainWhiteTheme))
        
        //set graph backgound area transparent
        graph?.fill = CPTFill(color: CPTColor.clear())
        graph?.plotAreaFrame?.fill = CPTFill(color: CPTColor.clear())
        graph?.plotAreaFrame?.fill = CPTFill(color: CPTColor.clear())
        
        //This removes top and right lines of graph
        graph?.plotAreaFrame?.borderLineStyle = CPTLineStyle(style: nil)
        //This shows x and y axis labels from 0 to 1
        graph?.plotAreaFrame?.masksToBorder = false
        
        // set padding for graph from Left and Bottom
        graph?.paddingBottom = 30;
        graph?.paddingLeft = 50;
        graph?.paddingRight = 0;
        graph?.paddingTop = 0;
        
        //Define x and y axis range
        // x-axis from 0 to 100
        // y-axis from 0 to 300
        let plotSpace = graph?.defaultPlotSpace
        plotSpace?.allowsUserInteraction = true
        plotSpace?.delegate = self;
        self.resetPlotRange()
        
        let axisSet = graph?.axisSet as! CPTXYAxisSet;
        
        let axisLabelFormatter = NumberFormatter()
        axisLabelFormatter.generatesDecimalNumbers = false
        axisLabelFormatter.numberStyle = NumberFormatter.Style.decimal
        
        
        //Define x-axis properties
        //x-axis intermediate interval 2
        let xAxis = axisSet.xAxis
        xAxis?.majorIntervalLength = plotXInterval as NSNumber?
        xAxis?.minorTicksPerInterval = 4;
        xAxis?.minorTickLength = 5;
        xAxis?.majorTickLength = 7;
        xAxis?.title = "Time (s)"
        xAxis?.titleOffset = 25;
        xAxis?.labelFormatter = axisLabelFormatter
        
        //Define y-axis properties
        let yAxis = axisSet.yAxis
        yAxis?.majorIntervalLength = plotYInterval as NSNumber?
        yAxis?.minorTicksPerInterval = 4
        yAxis?.minorTickLength = 5
        yAxis?.majorTickLength = 7
        yAxis?.title = "BPM"
        yAxis?.titleOffset = 30
        yAxis?.labelFormatter = axisLabelFormatter
        
        
        //Define line plot and set line properties
        linePlot = CPTScatterPlot()
        linePlot?.dataSource = self
        graph?.add(linePlot!, to: plotSpace)
        
        //set line plot style
        let lineStyle = linePlot?.dataLineStyle!.mutableCopy() as! CPTMutableLineStyle
        lineStyle.lineWidth = 2
        lineStyle.lineColor = CPTColor.black()
        linePlot!.dataLineStyle = lineStyle;
        
        let symbolLineStyle = CPTMutableLineStyle(style: lineStyle)
        symbolLineStyle.lineColor = CPTColor.black()
        let symbol = CPTPlotSymbol.ellipse()
        symbol.fill = CPTFill(color: CPTColor.black())
        symbol.lineStyle = symbolLineStyle
        symbol.size = CGSize(width: 3.0, height: 3.0)
        linePlot?.plotSymbol = symbol;
        
        //set graph grid lines
        let gridLineStyle = CPTMutableLineStyle()
        gridLineStyle.lineColor = CPTColor.gray()
        gridLineStyle.lineWidth = 0.5
        xAxis?.majorGridLineStyle = gridLineStyle
        yAxis?.majorGridLineStyle = gridLineStyle
    }
    
    func resetPlotRange() {
        plotXMaxRange = 121
        plotXMinRange = -1
        plotYMaxRange = 310
        plotYMinRange = -1
        plotXInterval = 20
        plotYInterval = 50
         
        let plotSpace = graph?.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.xRange = CPTPlotRange(location: NSNumber(value: plotXMinRange!), length: NSNumber(value: plotXMaxRange!))
        plotSpace.yRange = CPTPlotRange(location: NSNumber(value: plotYMinRange!), length: NSNumber(value: plotYMaxRange!))
    }
    
    func clearUI() {
        deviceName.text = "DEFAULT HRM";
        battery.setTitle("N/A", for: UIControlState())
        battery.tag = 0;
        hrLocation.text = "n/a";
        hrValue.text = "-";
        
        // Clear and reset the graph
        hrValues?.removeAllObjects()
        xValues?.removeAllObjects()
        resetPlotRange()
        graph?.reloadData()
    }
    
    func addHRvalueToGraph(data value: Int) {
        // In this method the new value is added to hrValues array
        hrValues?.add(NSDecimalNumber(value: value as Int))
        
        // Also, we save the time when the data was received
        // 'Last' and 'previous' values are timestamps of those values. We calculate them to know whether we should automatically scroll the graph
        var lastValue : NSDecimalNumber
        var firstValue : NSDecimalNumber
        
        if xValues?.count > 0 {
            lastValue  = xValues?.lastObject as! NSDecimalNumber
            firstValue = xValues?.firstObject as! NSDecimalNumber
        }else{
            lastValue  = 0
            firstValue = 0
        }
        
        let previous : Double = lastValue.subtracting(firstValue).doubleValue
        xValues?.add(NORHRMViewController.longUnixEpoch())
        lastValue  = xValues?.lastObject as! NSDecimalNumber
        firstValue = xValues?.firstObject as! NSDecimalNumber
        let last : Double = lastValue.subtracting(firstValue).doubleValue
        
        // Here we calculate the max value visible on the graph
        let plotSpace = graph!.defaultPlotSpace as! CPTXYPlotSpace
        let max = plotSpace.xRange.locationDouble + plotSpace.xRange.lengthDouble
        
        if last > max && previous <= max {
            let location = Int(last) - plotXMaxRange! + 1
            plotSpace.xRange = CPTPlotRange(location: NSNumber(value: (location)), length: NSNumber(value: plotXMaxRange!))
        }
        
        // Rescale Y axis to display higher values
        if value >= plotYMaxRange {
            while (value >= plotYMaxRange)
            {
                plotYMaxRange = plotYMaxRange! + 50
            }
            
            plotSpace.yRange = CPTPlotRange(location: NSNumber(value: plotYMinRange!), length: NSNumber(value: plotYMaxRange!))
        }
        graph?.reloadData()
    }
    
    //MARK: - NORScannerDelegate
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral){
        // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
        bluetoothManager = aManager;
        bluetoothManager!.delegate = self;
        
        // The sensor has been selected, connect to it
        peripheral = aPeripheral;
        aPeripheral.delegate = self;
        let options = NSDictionary(object: NSNumber(value: true as Bool), forKey: CBConnectPeripheralOptionNotifyOnNotificationKey as NSCopying)
        bluetoothManager!.connect(aPeripheral, options: options as? [String : AnyObject])
    }
    
    
    //MARK: - CPTPlotDataSource
    
    func numberOfRecords(for plot :CPTPlot) -> UInt {
        return UInt(hrValues!.count)
    }
    
    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        let fieldVal = NSInteger(fieldEnum)
        let scatterPlotField = CPTScatterPlotField(rawValue: fieldVal)
        switch (scatterPlotField!) {
            case .X:
                // The xValues stores timestamps. To show them starting from 0 we have to subtract the first one.
                return (xValues?.object(at: Int(idx)) as! NSDecimalNumber).subtracting(xValues?.firstObject as! NSDecimalNumber)
            case .Y:
                return hrValues?.object(at: Int(idx)) as AnyObject?
        }
    }

    //MARK: - CPRPlotSpaceDelegate
    func plotSpace(_ space: CPTPlotSpace, shouldScaleBy interactionScale: CGFloat, aboutPoint interactionPoint: CGPoint) -> Bool {
        return false
    }

    func plotSpace(_ space: CPTPlotSpace, willDisplaceBy proposedDisplacementVector: CGPoint) -> CGPoint {
        return CGPoint(x: proposedDisplacementVector.x, y: 0)
    }
    
    func plotSpace(_ space: CPTPlotSpace, willChangePlotRangeTo newRange: CPTPlotRange, for coordinate: CPTCoordinate) -> CPTPlotRange? {
        // The Y range does not change here
        if coordinate == CPTCoordinate.Y {
            return newRange;
        }

        // Adjust axis on scrolling
        let axisSet = space.graph?.axisSet as! CPTXYAxisSet
        
        if newRange.location.intValue >= plotXMinRange! {
            // Adjust axis to keep them in view at the left and bottom;
            // adjust scale-labels to match the scroll.
            axisSet.yAxis!.orthogonalPosition = NSNumber(value: newRange.locationDouble - Double(plotXMinRange!))
            return newRange
        }
        axisSet.yAxis!.orthogonalPosition = 0
        return CPTPlotRange(location: NSNumber(value: plotXMinRange!), length: NSNumber(value: plotXMaxRange!))
    }
    
    //MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOff {
            print("Bluetooth powered off")
        } else {
            print("Bluetooth powered on")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async {
            self.deviceName.text = peripheral.name
            self.connectionButton.setTitle("DISCONNECT", for: UIControlState())
            self.hrValues?.removeAllObjects()
            self.xValues?.removeAllObjects()
            self.resetPlotRange()
        }
        
        if UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:))){
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound], categories: nil))
        }
        NotificationCenter.default.addObserver(self, selector: #selector(NORHRMViewController.appDidEnterBackgroundCallback), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NORHRMViewController.appDidBecomeActiveCallback), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        // Peripheral has connected. Discover required services
        peripheral.discoverServices([hrServiceUUID, batteryServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async(execute: {
            NORAppUtilities.showAlert(title: "Error", andMessage: "Connecting to peripheral failed. Try again")
            self.connectionButton.setTitle("CONNCECT", for: UIControlState())
            self.peripheral = nil
            self.clearUI()
        });
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async(execute: {
            self.connectionButton.setTitle("CONNECT", for: UIControlState())
            self.peripheral = nil;
            self.clearUI()
            
            if NORAppUtilities.isApplicationInactive() {
                let name = peripheral.name ?? "Peripheral"
                NORAppUtilities.showBackgroundNotification(message: "\(name) is disconnected.")
            }
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        });
    }
    
    //MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("An error occured while discovering services: \(error!.localizedDescription)")
            bluetoothManager!.cancelPeripheralConnection(peripheral)
            return
        }
        
        for aService : CBService in peripheral.services! {
            if aService.uuid.isEqual(hrServiceUUID){
                print("HRM Service found")
                peripheral.discoverCharacteristics(nil, for: aService)
            } else if aService.uuid.isEqual(batteryServiceUUID) {
              print("Battery service found")
                peripheral.discoverCharacteristics(nil, for: aService)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Error occurred while discovering characteristic: \(error!.localizedDescription)")
            bluetoothManager!.cancelPeripheralConnection(peripheral)
            return
        }
        
        if service.uuid.isEqual(hrServiceUUID) {
            for aCharactersistic : CBCharacteristic in service.characteristics! {
                if aCharactersistic.uuid.isEqual(hrMeasurementCharacteristicUUID) {
                    print("Heart rate measurement characteristic found")
                    peripheral.setNotifyValue(true, for: aCharactersistic)
                }else if aCharactersistic.uuid.isEqual(hrLocationCharacteristicUUID) {
                    print("Heart rate sensor location characteristic found")
                    peripheral.readValue(for: aCharactersistic)
                }
            }
        } else if service.uuid.isEqual(batteryServiceUUID) {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.uuid.isEqual(batteryLevelCharacteristicUUID) {
                    print("Battery level characteristic found")
                    peripheral.readValue(for: aCharacteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error occurred while updating characteristic value: \(error!.localizedDescription)")
            return
        }
        
        DispatchQueue.main.async {
            if characteristic.uuid.isEqual(self.hrMeasurementCharacteristicUUID) {
                let value = self.decodeHRValue(withData: characteristic.value!)
                self.addHRvalueToGraph(data: Int(value))
                self.hrValue.text = "\(value)"
            } else if characteristic.uuid.isEqual(self.hrLocationCharacteristicUUID) {
                self.hrLocation.text = self.decodeHRLocation(withData: characteristic.value!)
            } else if characteristic.uuid.isEqual(self.batteryLevelCharacteristicUUID) {
                let data = characteristic.value as NSData?
                let array : UnsafePointer<UInt8> = (data?.bytes)!.assumingMemoryBound(to: UInt8.self)
                let batteryLevel : UInt8 = array[0]
                let text = "\(batteryLevel)%"
                self.battery.setTitle(text, for: UIControlState.disabled)
                
                if self.battery.tag == 0 {
                    if characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue > 0 {
                       self.battery.tag = 1 // Mark that we have enabled notifications
                       peripheral.setNotifyValue(true, for: characteristic)
                    }
                }
            }
        }
    }
    
    //MARK: - UIApplicationDelegate callbacks
    func appDidEnterBackgroundCallback() {
        let name = peripheral?.name ?? "peripheral"
        NORAppUtilities.showBackgroundNotification(message: "You are still connected to \(name). It will collect data also in background.")
    }
    
    func appDidBecomeActiveCallback() {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    //MARK: - Segue management
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
        return identifier != "scan" || peripheral == nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scan" {
            // Set this contoller as scanner delegate
            let nc                = segue.destination as! UINavigationController
            let controller        = nc.childViewControllerForStatusBarHidden as! NORScannerViewController
            controller.filterUUID = hrServiceUUID
            controller.delegate   = self
        }
    }
    
    //MARK: - Helpers
    static func longUnixEpoch() -> NSDecimalNumber {
        return NSDecimalNumber(value: Date().timeIntervalSince1970 as Double)
    }

    func decodeHRValue(withData data: Data) -> Int {
        let count = data.count / MemoryLayout<UInt8>.size
        var array = [UInt8](repeating: 0, count: count)
        (data as NSData).getBytes(&array, length:count * MemoryLayout<UInt8>.size)
        
        var bpmValue : Int = 0;
        if ((array[0] & 0x01) == 0) {
            bpmValue = Int(array[1])
        } else {
            //Convert Endianess from Little to Big
            bpmValue = Int(UInt16(array[2] * 0xFF) + UInt16(array[1]))
        }
        return bpmValue
    }
    
    func decodeHRLocation(withData data:Data) -> String {
        let location = (data as NSData).bytes.bindMemory(to: UInt16.self, capacity: data.count)
        switch (location[0]) {
            case 0:
                return "Other"
            case 1:
                return "Chest"
            case 2:
                return "Wrist"
            case 3:
                return "Finger"
            case 4:
                return "Hand";
            case 5:
                return "Ear Lobe"
            case 6:
                return "Foot"
            default:
                return "Invalid";
        }
    }
}
