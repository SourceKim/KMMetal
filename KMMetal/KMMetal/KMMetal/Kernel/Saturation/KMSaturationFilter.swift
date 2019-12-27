////  KMSaturationFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/27.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMSaturationFilter: KMMetalFilter, KMMetalOneParameterFilter {
    
    var maxValue: Float = 2
    
    var minValue: Float = 0
    
    var defaultValue: Float = 1

    var saturation: Float = 1
    
    init() {
        super.init(kernelName: "saturationKernel")!
    }
    
    override func updateUniforms(encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&self.saturation, length: MemoryLayout<Float>.size, index: 0)
    }
}
