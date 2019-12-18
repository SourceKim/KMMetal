////  KMMetalShared.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/18.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMMetalShared {

    static let shared = KMMetalShared()
    
    var device: MTLDevice
    var queue: MTLCommandQueue
    var colorSpace: CGColorSpace
    
    private init() {
        guard let device = MTLCreateSystemDefaultDevice(),
            let queue = device.makeCommandQueue() else {
            fatalError("Can't use")
        }
        
        self.device = device
        self.queue = queue
        self.colorSpace = CGColorSpaceCreateDeviceRGB()
    }
}
