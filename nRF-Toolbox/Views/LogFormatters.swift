//
//  LogFormatters.swift
//  nRF Toolbox
//
//  Created by Sylwester Zielinski on 28/01/2026.
//  Copyright © 2026 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOS_Common_Libraries

extension TemperatureMeasurement : BeautifulLogFormat {
    
    public func getLogString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        var lines = [String]()
        lines.append("Temperature: \(temperature)")
        
        if let timestamp {
            lines.append("Date: \(timestamp)")
        }
        if let location {
            lines.append("Location: \(location)")
        }
        
        return lines.joined(separator: "\n")
    }
}

extension HeartRateValue: BeautifulLogFormat {
    
    func getLogString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        var lines = [String]()
        lines.append("Heart rate: \(measurement.heartRateValue)")
        lines.append("\(measurement.sensorContact)")
        
        if let energyExpended = measurement.energyExpended {
            lines.append("Energy expanded: \(energyExpended) kJ")
        }
        if let intervals = measurement.intervals {
            lines.append("Intervals: \(intervals)")
        }
        lines.append("Date: \(f.string(from: date))")

        return lines.joined(separator: "\n")
    }
}

extension CyclingData : BeautifulLogFormat {
    
    func getLogString() -> String {
        var lines = [String]()
        if let wheelData = wheelData {
            lines.append("Wheel data")
            lines.append("Revolutions: \(wheelData.revolutions)")
            lines.append("Time: \(wheelData.time)")
        }

        if let crankData = crankData {
            lines.append("Crank data")
            lines.append("Revolutions: \(crankData.revolutions)")
            lines.append("Time: \(crankData.time)")
        }

        return lines.joined(separator: "\n")
    }
}

extension RSCSMeasurement : BeautifulLogFormat {
    
    func getLogString() -> String {
        var lines = [String]()
        lines.append("Flags: \(flags.bitsetMembers())")
        lines.append("Instantaneous speed: \(instantaneousSpeed)")
        lines.append("Instantaneous cadence: \(instantaneousCadence) stride/minute")
        if let instantaneousStrideLength = instantaneousStrideLength {
            lines.append("Instantaneous stride length: \(instantaneousStrideLength)")
        }
        if let totalDistance = totalDistance {
            lines.append("Total distance: \(totalDistance)")
        }

        return lines.joined(separator: "\n")
    }
}

extension BloodPressureMeasurement : BeautifulLogFormat {
    
    func getLogString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        var lines = [String]()
        lines.append("Systolic pressure: \(systolicPressure)")
        lines.append("Diastolic pressure: \(diastolicPressure)")
        lines.append("Mean arterial pressure: \(meanArterialPressure)")
        
        if let date = date {
            lines.append("Date: \(f.string(from: date))")
        }
        if let pulseRate = pulseRate {
            lines.append("Pulse rate: \(pulseRate)")
        }
        if let userID = userID {
            lines.append("User ID: \(userID)")
        }
        if let status = status {
            lines.append("Status: \(status.bitsetMembers())")
        }

        return lines.joined(separator: "\n")
    }
}

extension GlucoseMeasurement : BeautifulLogFormat {
    
    func getLogString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        var lines = [String]()
        lines.append("Sequence number: \(sequenceNumber)")
        lines.append("Timestamp: \(f.string(from: timestamp))")

 
        if let timeOffset = timeOffset {
            lines.append("Time offset: \(timeOffset)")
        }
        if let measurement = measurement {
            lines.append("Measurement: \(measurement)")
        }
        if let status = status {
            lines.append("Status: \(status.bitsetMembers())")
        }

        return lines.joined(separator: "\n")
    }
}

extension CGMSMeasurement : BeautifulLogFormat {
    
    func getLogString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        var lines = [String]()
        lines.append("Measurement: \(measurement)")
        lines.append("Time offset: \(timeOffset)")
        lines.append("Date: \(f.string(from: date))")

        if let sensorStatus = sensorStatus {
            lines.append("Sensor status: \(sensorStatus.bitsetMembers())")
        }
        if let calTempStatus = calTempStatus {
            lines.append("Calibration temperature status: \(calTempStatus)")
        }
        if let warningStatus = warningStatus {
            lines.append("Warning status: \(warningStatus.bitsetMembers())")
        }
        
        if let trend = trend {
            lines.append("Trend: \(trend)")
        }
        if let quality = quality {
            lines.append("Quality: \(quality)")
        }
        if let crc = crc {
            lines.append("CRC: \(crc)")
        }
        if let calculatedCrc = calculatedCrc {
            lines.append("Calculated CRC: \(calculatedCrc)")
        }
        
        return lines.joined(separator: "\n")
    }
}
