////  KMSingleBilateralBlurFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/28.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMSingleBilateralBlurFilter: KMMetalFilter {

    var distanceNormalizationFactor: Float = 8
    var stepOffsetX: Float = 4
    var stepOffsetY: Float = 4
    
    init() {
        super.init(kernelName: "singleBilateralBlurKernel")!
    }
    
    override func updateUniforms(encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&self.distanceNormalizationFactor, length: MemoryLayout<Float>.size, index: 0)
        encoder.setBytes(&self.stepOffsetX, length: MemoryLayout<Float>.size, index: 1)
        encoder.setBytes(&self.stepOffsetY, length: MemoryLayout<Float>.size, index: 2)
    }
    
}
