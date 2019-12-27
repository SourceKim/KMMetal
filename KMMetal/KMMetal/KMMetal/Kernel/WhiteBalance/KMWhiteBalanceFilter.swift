////  KMWhiteBalanceFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/27.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMWhiteBalanceFilter: KMMetalFilter {

    let temperatureValue = valueStruct(maxValue: 7000, minValue: 4000, defaultValue: 5000)
    let tintValue = valueStruct(maxValue: 200, minValue: -200, defaultValue: 0)
    
    private var _temperature: Float = 5000
    private var _tint: Float = 0
    
    func updateTemperature(_ temperature: Float) {
        _temperature = temperature < 5000 ? 0.0004 * (temperature - 5000) : 0.00006 * (temperature - 5000)
    }
    
    func updateTint(_ tint: Float) {
        _tint = tint / 100
    }
    
    override func updateUniforms(encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&_temperature, length: MemoryLayout<Float>.size, index: 0)
        encoder.setBytes(&_tint, length: MemoryLayout<Float>.size, index: 1)
    }
    
}
