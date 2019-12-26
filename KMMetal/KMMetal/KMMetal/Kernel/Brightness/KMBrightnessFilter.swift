////  KMBrightnessFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/19.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMBrightnessFilter: KMMetalFilter, KMMetalOneParameterFilter {
    
    var maxValue: Float = 1
    
    var minValue: Float = -1
    
    var defaultValue: Float = 0
    
    var brightness: Float = 0

    init() {
        
        super.init(kernelName: "brightnessKernel")!
    }
    
    override func updateUniforms(encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&brightness, length: MemoryLayout<Float>.size, index: 0)
    }
}
