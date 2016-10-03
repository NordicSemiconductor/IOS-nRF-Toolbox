/*
 * NORBGMDetailsViewController.swift
 * nRF Toolbox

 * Created by Mostafa Berg on 29/04/16.
 * Copyright © 2016 Nordic Semiconductor. All rights reserved.
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit

class NORBGMDetailsViewController: UIViewController {
    //MARK: - Referencing outlets
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var carbohydrateId: UILabel!
    @IBOutlet weak var carbohydrate: UILabel!
    @IBOutlet weak var glucose: UILabel!
    @IBOutlet weak var contextPresentStatus: UILabel!
    @IBOutlet weak var deviceFaultStats: UILabel!
    @IBOutlet weak var exerciseDuration: UILabel!
    @IBOutlet weak var exerciseIntensity: UILabel!
    @IBOutlet weak var hbA1c: UILabel!
    @IBOutlet weak var health: UILabel!
    @IBOutlet weak var insufficcientSampleStatus: UILabel!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var lowBatteryStatus: UILabel!
    @IBOutlet weak var meal: UILabel!
    @IBOutlet weak var medication: UILabel!
    @IBOutlet weak var medicationId: UILabel!
    @IBOutlet weak var medicationUnit: UILabel!
    @IBOutlet weak var resultTooHighStatus: UILabel!
    @IBOutlet weak var resultTooLowStatus: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var sensorMalfunctionStatus: UILabel!
    @IBOutlet weak var sequenceNumber: UILabel!
    @IBOutlet weak var stripInsertionStatus: UILabel!
    @IBOutlet weak var stripPulledTooSoonStatus: UILabel!
    @IBOutlet weak var stripTypeIncorrectStatus: UILabel!
    @IBOutlet weak var tempTooHighStatus: UILabel!
    @IBOutlet weak var tempTooLowstatus: UILabel!
    @IBOutlet weak var tester: UILabel!
    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var timeFaultStatus: UILabel!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var unit: UILabel!
    
    //MARK: - Properties
    var reading     : NORGlucoseReading?
    var dateFormat  : DateFormatter?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        dateFormat = DateFormatter()
        dateFormat?.dateFormat = "dd.MM.yy, hh:mm:ss"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sequenceNumber.text = String(format: "%d", (reading?.sequenceNumber)!)
        timestamp.text = dateFormat?.string(from: (reading?.timestamp)! as Date)
        
        if (reading?.glucoseConcentrationTypeAndLocationPresent)! == true {
            type.text       = reading?.typeAsString()
            location.text   = reading?.locationAsString()
            
            switch (reading?.unit)! {
            case .mol_L:
                glucose.text = String(format: "%0.1f", (reading?.glucoseConcentration)! * 1000.0)  //mol/l to mmol/l conversion
                unit.text = "mmol/l"
                break;
            case .kg_L:
                glucose.text = String(format: "%.0f", (reading?.glucoseConcentration)! * 100000.0) //kg/l to mg/dl conversion
                unit.text = "mg/dl"
                break;
            }
        } else {
            type.text = "Unavailable"
            location.text = "Unavailable"
            glucose.text = "-"
            unit.text = ""
        }
        
        if reading?.sensorStatusAnnunciationPresent == true {
            let status = (reading?.sensorStatusAnnunciation)!
            updateView(label: lowBatteryStatus,          withStatus: (status & 0x0001) > 0)
            updateView(label: sensorMalfunctionStatus,   withStatus: (status & 0x0002) > 0)
            updateView(label: insufficcientSampleStatus, withStatus: (status & 0x0004) > 0)
            updateView(label: stripInsertionStatus,      withStatus: (status & 0x0008) > 0)
            updateView(label: stripTypeIncorrectStatus,  withStatus: (status & 0x0010) > 0)
            updateView(label: resultTooHighStatus,       withStatus: (status & 0x0020) > 0)
            updateView(label: resultTooLowStatus,        withStatus: (status & 0x0040) > 0)
            updateView(label: tempTooHighStatus,         withStatus: (status & 0x0080) > 0)
            updateView(label: tempTooLowstatus,          withStatus: (status & 0x0100) > 0)
            updateView(label: stripPulledTooSoonStatus,  withStatus: (status & 0x0200) > 0)
            updateView(label: deviceFaultStats,          withStatus: (status & 0x0400) > 0)
            updateView(label: timeFaultStatus,           withStatus: (status & 0x0800) > 0)
        }
        
        if reading?.context != nil {
            let context = reading?.context
            contextPresentStatus.text = "Available"
            
            if context?.carbohydratePresent == true {
                carbohydrateId.text = context?.carbohydrateIdAsString()
                carbohydrate.text   = String(format: "%.1f", (context?.carbohydrate)! * 1000)
            }
            
            if context?.mealPresent == true {
                meal.text = context?.mealIdAsString()
            }
            
            if context?.testerAndHealthPresent == true {
                tester.text = context?.testerAsString()
                health.text = context?.healthAsString()
            }
            
            if context?.exercisePresent == true {
                exerciseDuration.text   = String(format: "%d", (context?.exerciseDuration)! / 60)
                exerciseIntensity.text  = String(format: "%d", (context?.exerciseIntensity)!)
            }
            
            if context?.medicationPresent == true {
                medicationId.text = context?.medicationIdAsString()
                medication.text   = String(format: "%.0f", (context?.medication)! * 1000)
                
                    switch (context?.medicationUnit)! {
                    case .kilograms:
                        medicationUnit.text = "mg"
                        break
                    case .liters:
                        medicationUnit.text = "ml"
                        break
                    }
            }
            
            if context?.HbA1cPresent == true {
                hbA1c.text = String(format: "%.2f", (context?.HbA1c)!)
            }
        }
    }
    
    //MARK: - View Population Logic
    func updateView(label aLabel: UILabel, withStatus aStatus: Bool) {
        if aStatus == true {
            aLabel.text = "YES"
            aLabel.textColor = UIColor.red
        } else {
            aLabel.text = "NO"
        }
        
    }
}
