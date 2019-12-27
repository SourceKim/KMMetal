////  KMHighLightShadowFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/27.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMHighLightShadowFilter: KMMetalFilter {
    
    var shadowsValue = valueStruct(maxValue: 1, minValue: 0, defaultValue: 0)
    
    var highlightsValue = valueStruct(maxValue: 1, minValue: 0, defaultValue: 1)
    
    var shadows: Float = 0
    
    var highlights: Float = 1

    init() {
        super.init(kernelName: "highlightShadowKernel")!
    }
    
    override func updateUniforms(encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&self.shadows, length: MemoryLayout<Float>.size, index: 0)
        encoder.setBytes(&self.highlights, length: MemoryLayout<Float>.size, index: 1)
    }
}
