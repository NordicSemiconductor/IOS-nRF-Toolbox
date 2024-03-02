//
//  HealthThermometer+Preview.swift
//  nRF-Toolbox
//
//  Created by Nick Kibysh on 02/03/2024.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

import Foundation

extension HealthThermometerScreen.VM.Env {
    typealias Rec = HealthThermometerScreen.VM.TemperatureRecord
    
    static var preview1: HealthThermometerScreen.VM.Env {
        HealthThermometerScreen.VM.Env(
            records: [
                Rec(temperature: Measurement(value: 36.7, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704063600)),
                Rec(temperature: Measurement(value: 36.6, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704067200)),
                Rec(temperature: Measurement(value: 36.9, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704070800)),
                Rec(temperature: Measurement(value: 37.0, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704074400)),
                Rec(temperature: Measurement(value: 37.1, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704078000)),
                Rec(temperature: Measurement(value: 37.2, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704081600)),
                Rec(temperature: Measurement(value: 37.1, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704085200)),
                Rec(temperature: Measurement(value: 37.4, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704088800)),
                Rec(temperature: Measurement(value: 37.3, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704092400)),
                Rec(temperature: Measurement(value: 37.5, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704096000)),
                Rec(temperature: Measurement(value: 37.7, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704099600)),
                Rec(temperature: Measurement(value: 37.8, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704103200)),
                Rec(temperature: Measurement(value: 37.9, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704106800)),
                Rec(temperature: Measurement(value: 38.0, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704110400)),
                Rec(temperature: Measurement(value: 38.0, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704114000)),
                Rec(temperature: Measurement(value: 38.2, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704117600)),
                Rec(temperature: Measurement(value: 38.1, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704121200)),
                Rec(temperature: Measurement(value: 38.4, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704124800)),
                Rec(temperature: Measurement(value: 38.3, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704128400)),
                Rec(temperature: Measurement(value: 37.6, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704132000)),
                Rec(temperature: Measurement(value: 37.7, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704135600)),
                Rec(temperature: Measurement(value: 37.8, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704139200)),
                Rec(temperature: Measurement(value: 37.9, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704142800)),
                Rec(temperature: Measurement(value: 39.0, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704146400)),
                Rec(temperature: Measurement(value: 38.9, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704150000)),
                Rec(temperature: Measurement(value: 39.2, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704153600)),
                Rec(temperature: Measurement(value: 39.3, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704157200)),
                Rec(temperature: Measurement(value: 39.0, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704160800)),
                Rec(temperature: Measurement(value: 39.0, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704164400)),
                Rec(temperature: Measurement(value: 39.2, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704168000)),
                Rec(temperature: Measurement(value: 39.3, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704171600)),
                Rec(temperature: Measurement(value: 39.1, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704175200)),
                Rec(temperature: Measurement(value: 39.4, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704178800)),
                Rec(temperature: Measurement(value: 40.0, unit: UnitTemperature.celsius), date: Date(timeIntervalSince1970: 1704182400)),
            ]
        )
    }
    
}
