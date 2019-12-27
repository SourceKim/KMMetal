////  KMContrastFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/27.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMContrastFilter: KMMetalFilter, KMMetalOneParameterFilter {

    var maxValue: Float = 4
    
    var minValue: Float = 0
    
    var defaultValue: Float = 1

    var contrast: Float = 1
    
    init() {
        super.init(kernelName: "contrastKernel")!
    }
    
    override func updateUniforms(encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&self.contrast, length: MemoryLayout<Float>.size, index: 0)
    }
}
