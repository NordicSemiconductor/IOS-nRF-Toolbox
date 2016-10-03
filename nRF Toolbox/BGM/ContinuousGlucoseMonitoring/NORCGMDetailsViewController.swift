/*
 * Copyright (c) 2015, Nordic Semiconductor
 * All rights reserved.
 *
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

class NORCGMDetailsViewController : UIViewController {

    //MARK: - Class Properties
    var reading     : NORCGMReading?
    var dateFormat  : DateFormatter?

    //MARK: - View Outlets/Actions
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var sequenceNumber: UILabel!
    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var concentration: UILabel!
    @IBOutlet weak var unit: UILabel!
    @IBOutlet weak var lowBatteryStatus: UILabel!
    @IBOutlet weak var sensorMalfunctionStatus: UILabel!
    @IBOutlet weak var insufficienSampleStatus: UILabel!
    @IBOutlet weak var stripInsertionStatus: UILabel!
    @IBOutlet weak var stripTypeStatus: UILabel!
    @IBOutlet weak var resultTooHighStatus: UILabel!
    @IBOutlet weak var resultTooLowStatus: UILabel!
    @IBOutlet weak var tempTooHighStatus: UILabel!
    @IBOutlet weak var tempTooLowStatus: UILabel!
    @IBOutlet weak var stripPulledTooSoonStatus: UILabel!
    @IBOutlet weak var deviceFaultStatus: UILabel!
    @IBOutlet weak var timeStatus: UILabel!
    @IBOutlet weak var contextPresentStatus: UILabel!
    @IBOutlet weak var carbohydrateId: UILabel!
    @IBOutlet weak var carbohydrate: UILabel!
    @IBOutlet weak var meal: UILabel!
    @IBOutlet weak var tester: UILabel!
    @IBOutlet weak var health: UILabel!
    @IBOutlet weak var exerciseDuration: UILabel!
    @IBOutlet weak var exerciseIntensity: UILabel!
    @IBOutlet weak var medication: UILabel!
    @IBOutlet weak var medicationUnit: UILabel!
    @IBOutlet weak var medicationId: UILabel!
    @IBOutlet weak var HbA1c: UILabel!
    
    
    //MARK: - Initializer
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        dateFormat = DateFormatter()
        dateFormat?.dateFormat = "dd.MM.yyy, hh:mm:ss"
    }
    
    //MARK: - UIViewController methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        timestamp.text = dateFormat?.string(from: reading!.timeStamp! as Date)
        self.type.text = reading?.typeAsString()
        self.location.text = reading?.locationAsSting()
        self.concentration.text = String(format:"%.1f", reading!.glucoseConcentration)
        self.unit.text = "mg/dL";
        
        if (reading?.sensorStatusAnnunciationPresent)! {
            print("Sensor annuciation is not fully implemented, updates will be ignored")
            //        UInt16 status = reading.sensorStatusAnnunciation;
            //        [self updateView:self.lowBatteryStatus withStatus:(status & 0x0001) > 0];
            //        [self updateView:self.sensorMalfunctionStatus withStatus:(status & 0x0002) > 0];
            //        [self updateView:self.insufficienSampleStatus withStatus:(status & 0x0004) > 0];
            //        [self updateView:self.stripInsertionStatus withStatus:(status & 0x0008) > 0];
            //        [self updateView:self.stripTypeStatus withStatus:(status & 0x0010) > 0];
            //        [self updateView:self.resultTooHighStatus withStatus:(status & 0x0020) > 0];
            //        [self updateView:self.resultTooLowStatus withStatus:(status & 0x0040) > 0];
            //        [self updateView:self.tempTooHighStatus withStatus:(status & 0x0080) > 0];
            //        [self updateView:self.tempTooLowStatus withStatus:(status & 0x0100) > 0];
            //        [self updateView:self.stripPulledTooSoonStatus withStatus:(status & 0x0200) > 0];
            //        [self updateView:self.deviceFaultStatus withStatus:(status & 0x0400) > 0];
            //        [self updateView:self.timeStatus withStatus:(status & 0x0800) > 0];
        }
        
    }
    
    func updateView(withLabel aLabel : UILabel, andStatus status : Bool) {
        if status == true {
            aLabel.text = "YES"
            aLabel.textColor = UIColor.red
        }else{
            aLabel.text = "NO"
        }
    }
}
