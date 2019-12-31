////  KMSkinSmoothFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/30.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMSkinSmoothFilter: KMMetalFilterGroup {
    
    private let blurFilter: KMBilateralBlurFilter
    private let sobelFilter: KMSobelFilter
    private let skinSmoothFilter: KMInternalSkinSmoothFilter
    
    var smoothDegree: Float {
        get {
            self.skinSmoothFilter.smoothDegree
        }
        set {
            self.skinSmoothFilter.smoothDegree = newValue
        }
    }

    init() {
        blurFilter = KMBilateralBlurFilter()
        sobelFilter = KMSobelFilter()
        
        skinSmoothFilter = KMInternalSkinSmoothFilter()
        
        blurFilter.add(input: skinSmoothFilter)
        sobelFilter.add(input: skinSmoothFilter)
        super.init(filters: [blurFilter, sobelFilter, skinSmoothFilter], terminateFilter: skinSmoothFilter)
    }
}

fileprivate class KMInternalSkinSmoothFilter: KMMetalFilter {
    
    var smoothDegree: Float = 0.5
    
    init() {
        super.init(kernelName: "skinSmoothKernel")!
    }
    
    override func updateUniforms(encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&smoothDegree, length: MemoryLayout<Float>.size, index: 0)
    }
}
