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
    var batteryServiceUUID              : CBUUID?
    var batteryLevelCharacteristicUUID  : CBUUID?
    var hrServiceUUID                   : CBUUID?
    var hrMeasurementCharacteristicUUID : CBUUID?
    var hrLocationCharacteristicUUID    : CBUUID?
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
    @IBAction func connectionButtonTapped(sender: AnyObject) {
        if peripheral != nil
        {
            bluetoothManager?.cancelPeripheralConnection(peripheral!)
        }
    }
    @IBAction func aboutButtonTapped(sender: AnyObject) {
        self.showAbout(message: NORAppUtilities.getHelpTextForService(service: .HRM))
    }
    //MARK: - UIViewController delegate
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        hrServiceUUID                    = CBUUID(string: NORServiceIdentifiers.hrsServiceUUIDString)
        hrMeasurementCharacteristicUUID  = CBUUID(string: NORServiceIdentifiers.hrsHeartRateCharacteristicUUIDString)
        hrLocationCharacteristicUUID     = CBUUID(string: NORServiceIdentifiers.hrsSensorLocationCharacteristicUUIDString)
        batteryServiceUUID               = CBUUID(string: NORServiceIdentifiers.batteryServiceUUIDString)
        batteryLevelCharacteristicUUID   = CBUUID(string: NORServiceIdentifiers.batteryLevelCharacteristicUUIDString)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Rotate the vertical label
        verticalLabel.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(-120.0, 0.0), CGFloat(-M_PI_2))
        isBluetoothOn           = false
        isDeviceConnected       = false
        isBackButtonPressed     = false
        peripheral              = nil
        
        hrValues = NSMutableArray()
        xValues  = NSMutableArray()
        
        initLinePlot()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if peripheral != nil && isBackButtonPressed == true
        {
            bluetoothManager?.cancelPeripheralConnection(peripheral!)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        isBackButtonPressed = true
    }

    //MARK: - CTPPlot Implementation
    
    func initLinePlot() {
        //Initialize and display Graph (x and y axis lines)
        graph = CPTXYGraph(frame: graphView.bounds)
        self.graphView.hostedGraph = self.graph;
        
        //apply styling to Graph
        graph?.applyTheme(CPTTheme(named: kCPTPlainWhiteTheme))
        
        //set graph backgound area transparent
        graph?.fill = CPTFill(color: CPTColor.clearColor())
        graph?.plotAreaFrame?.fill = CPTFill(color: CPTColor.clearColor())
        graph?.plotAreaFrame?.fill = CPTFill(color: CPTColor.clearColor())
        
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
        
        let axisLabelFormatter = NSNumberFormatter()
        axisLabelFormatter.generatesDecimalNumbers = false
        axisLabelFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        
        
        //Define x-axis properties
        //x-axis intermediate interval 2
        let xAxis = axisSet.xAxis
        xAxis?.majorIntervalLength = plotXInterval
        xAxis?.minorTicksPerInterval = 4;
        xAxis?.minorTickLength = 5;
        xAxis?.majorTickLength = 7;
        xAxis?.title = "Time (s)"
        xAxis?.titleOffset = 25;
        xAxis?.labelFormatter = axisLabelFormatter
        
        //Define y-axis properties
        let yAxis = axisSet.yAxis
        yAxis?.majorIntervalLength = plotYInterval
        yAxis?.minorTicksPerInterval = 4
        yAxis?.minorTickLength = 5
        yAxis?.majorTickLength = 7
        yAxis?.title = "BPM"
        yAxis?.titleOffset = 30
        yAxis?.labelFormatter = axisLabelFormatter
        
        
        //Define line plot and set line properties
        linePlot = CPTScatterPlot()
        linePlot?.dataSource = self
        graph?.addPlot(linePlot!, toPlotSpace: plotSpace)
        
        //set line plot style
        let lineStyle = linePlot?.dataLineStyle!.mutableCopy() as! CPTMutableLineStyle
        lineStyle.lineWidth = 2
        lineStyle.lineColor = CPTColor.blackColor()
        linePlot!.dataLineStyle = lineStyle;
        
        let symbolLineStyle = CPTMutableLineStyle(style: lineStyle)
        symbolLineStyle.lineColor = CPTColor.blackColor()
        let symbol = CPTPlotSymbol.ellipsePlotSymbol()
        symbol.fill = CPTFill(color: CPTColor.blackColor())
        symbol.lineStyle = symbolLineStyle
        symbol.size = CGSizeMake(3.0, 3.0)
        linePlot?.plotSymbol = symbol;
        
        //set graph grid lines
        let gridLineStyle = CPTMutableLineStyle()
        gridLineStyle.lineColor = CPTColor.grayColor()
        gridLineStyle.lineWidth = 0.5
        xAxis?.majorGridLineStyle = gridLineStyle
        yAxis?.majorGridLineStyle = gridLineStyle
    }
    
    func resetPlotRange() {
        plotXMaxRange = 121
        plotXMinRange = -1
        plotYMaxRange = 201
        plotYMinRange = -1
        plotXInterval = 20
        plotYInterval = 50
         
        let plotSpace = graph?.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.xRange = CPTPlotRange(location: NSNumber(integer: plotXMinRange!), length: NSNumber(integer: plotXMaxRange!))
        plotSpace.yRange = CPTPlotRange(location: NSNumber(integer: plotYMinRange!), length: NSNumber(integer: plotYMaxRange!))
    }
    
    func clearUI() {
        deviceName.text = "DEFAULT HRM";
        battery.setTitle("N/A", forState: UIControlState.Normal)
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
        hrValues?.addObject(NSDecimalNumber(integer: value))
        
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
        
        let previous : Double = lastValue.decimalNumberBySubtracting(firstValue).doubleValue
        xValues?.addObject(NORHRMViewController.longUnixEpoch())
        lastValue  = xValues?.lastObject as! NSDecimalNumber
        firstValue = xValues?.firstObject as! NSDecimalNumber
        let last : Double = lastValue.decimalNumberBySubtracting(firstValue).doubleValue
        
        // Here we calculate the max value visible on the graph
        let plotSpace = graph!.defaultPlotSpace as! CPTXYPlotSpace
        let max = plotSpace.xRange.locationDouble + plotSpace.xRange.lengthDouble
        
        if last > max && previous <= max {
            let location = Int(last) - plotXMaxRange! + 1
            plotSpace.xRange = CPTPlotRange(location: NSNumber(integer: (location)), length: NSNumber(integer: plotXMaxRange!))
        }
        
        // Rescale Y axis to display higher values
        if value >= plotYMaxRange {
            while (value >= plotYMaxRange)
            {
                plotYMaxRange = plotYMaxRange! + 50
            }
            
            plotSpace.yRange = CPTPlotRange(location: NSNumber(integer: plotYMinRange!), length: NSNumber(integer: plotYMaxRange!))
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
        peripheral!.delegate = self;
        let options = NSDictionary(object: NSNumber(bool: true), forKey: CBConnectPeripheralOptionNotifyOnNotificationKey)
        bluetoothManager?.connectPeripheral(peripheral!, options: options as? [String : AnyObject])
    }
    
    
    //MARK: - CPTPlotDataSource
    
    func numberOfRecordsForPlot(plot :CPTPlot) -> UInt {
        return UInt(hrValues!.count)
    }
    
    func numberForPlot(plot: CPTPlot, field fieldEnum: UInt, recordIndex idx: UInt) -> AnyObject? {
        let fieldVal = NSInteger(fieldEnum)
        let scatterPlotField = CPTScatterPlotField(rawValue: fieldVal)
        switch (scatterPlotField!) {
            case .X:
                // The xValues stores timestamps. To show them starting from 0 we have to subtract the first one.
                return (xValues?.objectAtIndex(Int(idx)) as! NSDecimalNumber).decimalNumberBySubtracting(xValues?.firstObject as! NSDecimalNumber)
            case .Y:
                return hrValues?.objectAtIndex(Int(idx))
        }
    }

    //MARK: - CPRPlotSpaceDelegate
    func plotSpace(space: CPTPlotSpace, shouldScaleBy interactionScale: CGFloat, aboutPoint interactionPoint: CGPoint) -> Bool {
        return false
    }

    func plotSpace(space: CPTPlotSpace, willDisplaceBy proposedDisplacementVector: CGPoint) -> CGPoint {
        return CGPointMake(proposedDisplacementVector.x, 0)
    }
    
    func plotSpace(space: CPTPlotSpace, willChangePlotRangeTo newRange: CPTPlotRange, forCoordinate coordinate: CPTCoordinate) -> CPTPlotRange? {
        // The Y range does not change here
        if coordinate == CPTCoordinate.Y {
            return newRange;
        }

        // Adjust axis on scrolling
        let axisSet = space.graph?.axisSet as! CPTXYAxisSet
        
        if newRange.location.integerValue >= plotXMinRange! {
            // Adjust axis to keep them in view at the left and bottom;
            // adjust scale-labels to match the scroll.
            axisSet.yAxis!.orthogonalPosition = NSNumber(double: newRange.locationDouble - Double(plotXMinRange!))
            return newRange
        }
        axisSet.yAxis!.orthogonalPosition = 0
        return CPTPlotRange(location: plotXMinRange!, length: plotXMaxRange!)
    }
    
    //MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOn {
            // TODO
        }else{
            // TODO
            print("Bluetooth not ON");
        }
    }

    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue()) {
            self.deviceName.text = peripheral.name
            self.connectionButton.setTitle("DISCONNECT", forState: UIControlState.Normal)
            self.hrValues?.removeAllObjects()
            self.xValues?.removeAllObjects()
            self.resetPlotRange()
        }
        
        if UIApplication.instancesRespondToSelector(#selector(UIApplication.registerUserNotificationSettings(_:))){
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: nil))
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NORHRMViewController.appDidEnterBackgroundCallback), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NORHRMViewController.appDidBecomeActiveCallback), name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        // Peripheral has connected. Discover required services
        peripheral.discoverServices([hrServiceUUID!,batteryServiceUUID!])
        peripheral.discoverServices(nil)
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            NORAppUtilities.showAlert(title: "Error", andMessage: "Connecting to peripheral failed. Try again")
            self.connectionButton.setTitle("CONNCECT", forState: UIControlState.Normal)
            self.peripheral = nil
            self.clearUI()
        });
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            self.connectionButton.setTitle("CONNECT", forState: UIControlState.Normal)
            self.peripheral = nil;
            self.clearUI()
            
            if NORAppUtilities.isApplicationInactive() {
                NORAppUtilities.showBackgroundNotification(message: String(format: "%@ peripheral is disconnected.", peripheral.name!))
            }
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        });
    }
    
    //MARK: - CBPeripheralDelegate
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        guard error == nil else {
            print(String(format: "An error occured while discovering services: %@", (error?.localizedDescription)!))
            return
        }
        for aService : CBService in peripheral.services! {
            if aService.UUID.isEqual(hrServiceUUID){
                print("HRM Service found")
                peripheral.discoverCharacteristics(nil, forService: aService)
            } else if aService.UUID.isEqual(batteryServiceUUID) {
              print("Battery service found")
                peripheral.discoverCharacteristics(nil, forService: aService)
            }
        }
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {

        guard error == nil else {
            print(String(format:"Error occurred while discovering characteristic: %@", (error?.localizedDescription)!))
            return
        }
        
        if service.UUID.isEqual(hrServiceUUID) {
            for aCharactersistic : CBCharacteristic in service.characteristics! {
                if aCharactersistic.UUID.isEqual(hrMeasurementCharacteristicUUID) {
                    print("Heart rate measurement characteristic found")
                    peripheral.setNotifyValue(true, forCharacteristic: aCharactersistic)
                }else if aCharactersistic.UUID.isEqual(hrLocationCharacteristicUUID) {
                    print("Heart rate sensor location characteristic found")
                    peripheral.readValueForCharacteristic(aCharactersistic)
                }
            }
        } else if service.UUID.isEqual(batteryServiceUUID) {
            for aCharacteristic : CBCharacteristic in service.characteristics! {
                if aCharacteristic.UUID.isEqual(batteryLevelCharacteristicUUID) {
                    print("Battery level characteristic found")
                    peripheral.readValueForCharacteristic(aCharacteristic)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        guard error == nil else {
            print(String(format: "Error occurred while updating characteristic value: %@", (error?.localizedDescription)!))
            return
        }
        dispatch_async(dispatch_get_main_queue()) {
            if characteristic.UUID.isEqual(self.hrMeasurementCharacteristicUUID) {
                let value = self.decodeHRValue(withData: characteristic.value!)
                self.addHRvalueToGraph(data: Int(value))
                self.hrValue.text = String(format: "%d", value)
            } else if characteristic.UUID.isEqual(self.hrLocationCharacteristicUUID) {
                self.hrLocation.text = self.decodeHRLocation(withData: characteristic.value!)
            } else if characteristic.UUID.isEqual(self.batteryLevelCharacteristicUUID) {
                let array : UnsafePointer<UInt8> = UnsafePointer<UInt8>((characteristic.value?.bytes)!)
                let batteryLevel : UInt8 = array[0]
                let text = String(format: "%d%%", batteryLevel)
                self.battery.setTitle(text, forState: UIControlState.Disabled)
                
                if self.battery.tag == 0 {
                    if characteristic.properties.rawValue & CBCharacteristicProperties.Notify.rawValue > 0 {
                       self.battery.tag = 1 // Mark that we have enabled notifications
                       peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    }
                }
            }
        }
    }
    
    //MARK: - UIApplicationDelegate callbacks
    func appDidEnterBackgroundCallback() {
        NORAppUtilities.showBackgroundNotification(message: String(format: "You are still connected to %@ sensor. It will collect data also in background.", peripheral!.name!))
    }
    
    func appDidBecomeActiveCallback() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
    
    //MARK: - Segue management
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
        return identifier != "scan" || peripheral == nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "scan" {
            // Set this contoller as scanner delegate
            let nc                = segue.destinationViewController as! UINavigationController
            let controller        = nc.childViewControllerForStatusBarHidden() as! NORScannerViewController
            controller.filterUUID = hrServiceUUID
            controller.delegate   = self
        }
    }
    
    //MARK: - Helpers
    static func longUnixEpoch() -> NSDecimalNumber {
        return NSDecimalNumber(double: NSDate().timeIntervalSince1970)
    }

    func decodeHRValue(withData data: NSData) -> Int {
        let count = data.length / sizeof(UInt8)
        var array = [UInt8](count: count, repeatedValue: 0)
        data.getBytes(&array, length:count * sizeof(UInt8))
        
        var bpmValue : Int = 0;
        if ((array[0] & 0x01) == 0) {
            bpmValue = Int(array[1])
        } else {
            //Convert Endianess from Little to Big
            bpmValue = Int(UInt16(array[2] * 0xFF) + UInt16(array[1]))
        }
        return bpmValue
    }
    
    func decodeHRLocation(withData data:NSData) -> String {
        let location = UnsafePointer<UInt16>(data.bytes)
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
