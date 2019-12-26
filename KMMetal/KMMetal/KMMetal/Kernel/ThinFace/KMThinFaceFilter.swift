//
//  KMThinFaceFilter.swift
//  KMMetal
//
//  Created by 苏金劲 on 2019/12/23.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

struct FloatPoint {
    let x: Float
    let y: Float
    
    init(from cgPoint: CGPoint) {
        self.x = Float(cgPoint.x)
        self.y = Float(cgPoint.y)
    }
    
    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
    
    static let zero = FloatPoint(x: 0, y: 0)
}

class KMThinFaceFilter: KMMetalFilter {
    
    private let lock = DispatchSemaphore(value: 1)
    
    private var _startPoint: FloatPoint = .zero
    private var _referencePoint: FloatPoint = .zero
    private var _r: Float = 0
    private var _mc2: Float = 0
    
    init() {
        super.init(kernelName: "thinFaceKernel")!
    }
    
    func setParams(startPoint: CGPoint, radiusPoint: CGPoint, referencePoint: CGPoint) {
        
        self.lock.wait()
        
        _startPoint = FloatPoint(from: startPoint)
        _referencePoint = FloatPoint(from: referencePoint)
        
        _r = Float(sqrt(pow(startPoint.x - radiusPoint.x, 2) + pow(startPoint.y - radiusPoint.y, 2)))
        
        _mc2 = Float(pow(referencePoint.x - startPoint.x, 2) + pow(referencePoint.y - startPoint.y, 2))
        
        self.lock.signal()
    }
    
    override func updateUniforms(encoder: MTLComputeCommandEncoder) {
        
        self.lock.wait()
        
        var sp = _startPoint
        var rp = _referencePoint
        var r = _r
        var mc2 = _mc2
        
        self.lock.signal()
        
        encoder.setBytes(&sp, length: MemoryLayout<FloatPoint>.size, index: 0)
        encoder.setBytes(&rp, length: MemoryLayout<FloatPoint>.size, index: 1)
        encoder.setBytes(&r, length: MemoryLayout<Float>.size, index: 2)
        encoder.setBytes(&mc2, length: MemoryLayout<FloatPoint>.size, index: 3)
        
    }
}
