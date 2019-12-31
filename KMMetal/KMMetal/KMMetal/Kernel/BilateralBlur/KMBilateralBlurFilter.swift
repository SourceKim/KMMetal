////  KMBilateralBlurFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/28.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMBilateralBlurFilter: KMMetalFilterGroup {

    private let filter0 = KMSingleBilateralBlurFilter()
    private let filter1 = KMSingleBilateralBlurFilter()
    
    private(set) var distanceNormalizationFactor: Float = 8
    private(set) var stepOffset: Float = 4 // 0 - ∞, default is 4
    
    init() {
        self.filter0.stepOffsetY = 0
        self.filter1.stepOffsetX = 0
        
        self.filter0.add(input: self.filter1)
        super.init(filters: [self.filter0], terminateFilter: self.filter1)
    }
    
    func updateDistanceNormalizationFactor(newValue: Float) {
        self.distanceNormalizationFactor = newValue
        self.filter0.distanceNormalizationFactor = newValue
        self.filter1.distanceNormalizationFactor = newValue
    }
    
    func updateStepOffset(newValue: Float) {
        self.filter0.stepOffsetX = newValue
        self.filter1.stepOffsetY = newValue
    }
}
