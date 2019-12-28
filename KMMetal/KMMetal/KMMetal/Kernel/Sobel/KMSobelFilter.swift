////  KMSobelFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/28.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMSobelFilter: KMMetalFilter {

    var edgeStrength: Float = 1
    
    init() {
        super.init(kernelName: "sobelKernel")!
    }
    
    override func updateUniforms(encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&self.edgeStrength, length: MemoryLayout<Float>.size, index: 0)
    }
}
