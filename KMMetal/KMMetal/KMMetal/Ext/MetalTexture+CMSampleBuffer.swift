////  MetalTexture+CMSampleBuffer.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/20.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import AVFoundation

extension CMSampleBuffer {
    
    func toTexture(with textureCache: CVMetalTextureCache) -> MTLTexture? {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else { return nil }
        
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        var cvMetalTextureOut: CVMetalTexture?
        let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                               textureCache,
                                                               imageBuffer,
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
