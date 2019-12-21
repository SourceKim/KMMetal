////  KMLookUpFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/21.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMLookUpFilter: KMMetalFilter {

    var intensity: Float
    
    private var lookUpTexture: MTLTexture
    
    init(lookUpTexture: MTLTexture? = nil) {
        
        self.intensity = 1
        if let t = lookUpTexture {
            self.lookUpTexture = t
        } else {
            self.lookUpTexture = UIImage(named: "lookup.png")!.toTexture(device: KMMetalShared.shared.device)!
        }
        super.init(kernelName: "lookupKernel")!
        
    }
    
    func setLutImage(uiImage: UIImage) {
        self.lookUpTexture = uiImage.toTexture(device: KMMetalShared.shared.device)!
    }
    
    override func updateUniforms(encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&intensity, length: MemoryLayout<Float>.size, index: 0)
        encoder.setTexture(self.lookUpTexture, index: 2)
    }
}
