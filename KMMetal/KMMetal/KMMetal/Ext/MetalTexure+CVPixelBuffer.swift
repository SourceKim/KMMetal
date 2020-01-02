////  MetalTexure+CVPixelBuffer.swift
//  KMMetal
//
//  Created by Su Jinjin on 2020/1/2.
//  Copyright © 2020 苏金劲. All rights reserved.
//

import Foundation

extension CVPixelBuffer {
    
    func toTexture(with textureCache: CVMetalTextureCache) -> MTLTexture? {
        
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        
        var cvMetalTextureOut: CVMetalTexture?
        let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                               textureCache,
                                                               self,
                                                               nil,
                                                               .bgra8Unorm, // camera ouput BGRA
            width,
            height,
            0,
            &cvMetalTextureOut)
        
        if result == kCVReturnSuccess,
            let cvMetalTexture = cvMetalTextureOut,
            let texture = CVMetalTextureGetTexture(cvMetalTexture) {
            return texture
        }
        
        return nil
    }
}
