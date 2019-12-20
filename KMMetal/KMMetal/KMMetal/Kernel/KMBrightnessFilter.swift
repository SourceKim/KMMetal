////  KMBrightnessFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/19.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMBrightnessFilter: KMMetalFilter {
    
    var brightness: Float

    init() {
        self.brightness = 0.3
        super.init(kernelName: "brightnessKernel")!
    }
    
    override func updateUniforms(encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&brightness, length: MemoryLayout<Float>.size, index: 0)
    }
}
