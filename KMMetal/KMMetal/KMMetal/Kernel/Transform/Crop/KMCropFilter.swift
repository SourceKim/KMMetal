////  KMCropFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/31.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

struct KMNormalizedRect {
    var x: Float
    var y: Float
    var width: Float
    var height: Float
    
    static var `default`: KMNormalizedRect {
        return KMNormalizedRect(x: 0, y: 0, width: 1, height: 1)
    }
}

class KMCropFilter: KMMetalFilter {

    var normalizedRect: KMNormalizedRect = .default
    
    init() {
        super.init(kernelName: "cropKernel")!
    }
    
    override func getOutputTextureSize(by inputSize: KMTextureSize) -> KMTextureSize {
        return KMTextureSize(width: Int(self.normalizedRect.width * Float(inputSize.width)),
                             height: Int(self.normalizedRect.height * Float(inputSize.height)))
    }
    
    override func updateUniforms(encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&self.normalizedRect, length: MemoryLayout<KMNormalizedRect>.size, index: 0)
    }
    
}
