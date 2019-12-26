////  KMExposureFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/26.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMExposureFilter: KMMetalFilter, KMMetalOneParameterFilter {
    
    var maxValue: Float = 10
    
    var minValue: Float = -10
    
    var defaultValue: Float = 0
    
    var exposure: Float = 0
    
    init() {
        super.init(kernelName: "exposureKernel")!
    }
    
    override func updateUniforms(encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&exposure, length: MemoryLayout<Float>.size, index: 0)
    }

}
