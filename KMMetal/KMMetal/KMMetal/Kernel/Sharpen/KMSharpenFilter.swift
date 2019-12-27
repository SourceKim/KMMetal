////  KMSharpenFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/27.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMSharpenFilter: KMMetalFilter, KMMetalOneParameterFilter {
    
    var maxValue: Float = 4
    
    var minValue: Float = -4
    
    var defaultValue: Float = 0
    
    var sharpeness: Float = 0
    
    init() {
        super.init(kernelName: "sharpenKernel")!
    }
    
    override func updateUniforms(encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&self.sharpeness, length: MemoryLayout<Float>.size, index: 0)
    }
}
