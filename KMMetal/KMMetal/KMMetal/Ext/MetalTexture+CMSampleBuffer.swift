////  MetalTexture+CMSampleBuffer.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/20.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import AVFoundation

extension CMSampleBuffer {
    
    func toTexture(with textureCache: CVMetalTextureCache) -> MTLTexture? {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else { return nil } // TODO: 优化 & 输出直接用
        
        return imageBuffer.toTexture(with: textureCache)
    }
}
