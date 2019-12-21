////  KMMetalFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/17.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMMetalFilter: KMMetalInput, KMMetalOutput {
    func onBeAdded() {
        self.lock.wait()
        self.parentCount += 1
        self.lock.signal()
    }
    
    private var outputTexture: MTLTexture?
    
    let pipelineState: MTLComputePipelineState
    let threadsPerThreadgroup: MTLSize
    var threadgroupsPerGrid: MTLSize?
    
    var childs = [KMMetalInput]()
    
    private var parentTextures = [KMMetalTexture]()
    private var parentCount = 0
    
    private let lock = DispatchSemaphore(value: 1)

    init?(kernelName: String) {
        guard let library = KMMetalShared.shared.device.makeDefaultLibrary(),
            let kernelFunc = library.makeFunction(name: kernelName),
            let pipelineState = try? KMMetalShared.shared.device.makeComputePipelineState(function: kernelFunc) else {
            return nil
        }
        self.pipelineState = pipelineState
        
        let w = self.pipelineState.threadExecutionWidth
        let h = self.pipelineState.maxTotalThreadsPerThreadgroup / w
        self.threadsPerThreadgroup = MTLSizeMake(w, h, 1)

    }
    
    /// 子类重写
    func updateUniforms(encoder: MTLComputeCommandEncoder) {
        
    }
    
    func next(texture: KMMetalTexture) {
        
//        MTLCaptureManager.shared().startCapture(commandQueue: KMMetalShared.shared.queue)
        
        self.lock.wait()
        self.parentTextures.append(texture)
        let ps = self.parentTextures
        let parentCount = self.parentCount
        self.lock.signal()
        
        // Check is textures all ready
        if ps.count != parentCount {
            self.lock.wait()
            self.lock.signal()
            return
        }
        
        // todo, 考虑 resize filter
        
        guard let commandBuffer = KMMetalShared.shared.queue.makeCommandBuffer() else {
            return
        }
        
        let w = self.threadsPerThreadgroup.width
        let h = self.threadsPerThreadgroup.height
        
        guard let firstTexture = ps.first?.texture else { return }
        
        // 重新创建 OutputTexture
        self.lock.wait()
        if self.outputTexture == nil ||
            self.outputTexture?.width != firstTexture.width ||
            self.outputTexture?.height != firstTexture.height {
            let desc = MTLTextureDescriptor()
            desc.pixelFormat = .rgba8Unorm
            desc.width = firstTexture.width
            desc.height = firstTexture.height
            desc.usage = [.shaderRead, .shaderWrite]
            if let o = KMMetalShared.shared.device.makeTexture(descriptor: desc) {
                self.outputTexture = o
            } else {
                self.lock.signal()
                return
            }
        }
            
        self.threadgroupsPerGrid = MTLSize(width: (firstTexture.width + w - 1) / w,
                                           height: (firstTexture.height + h - 1) / h,
                                           depth: 1)
        
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        encoder.setComputePipelineState(self.pipelineState)
        encoder.setTexture(self.outputTexture, index: 0)
        var idx = 1
        for texture in ps {
            encoder.setTexture(texture.texture, index: idx)
            idx += 1
        }
        
        self.updateUniforms(encoder: encoder)
        
        encoder.dispatchThreadgroups(self.threadgroupsPerGrid!, threadsPerThreadgroup: self.threadsPerThreadgroup)
        encoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
//        MTLCaptureManager.shared().stopCapture()
        
        // 清除 parents 的 texture
        self.parentTextures.removeAll()
        guard let ot = self.outputTexture else {
            self.lock.signal()
            return
        }
        let outkmt = KMTexture(texture: ot, cameraPosition: nil)
        self.lock.signal()
        
        for child in self.childs {
            child.next(texture: outkmt)
        }
        
    }
    
    func onProcessEnd() {
        
    }
    
    func add(input: KMMetalInput) -> Self {
        self.lock.wait()
        self.childs.append(input)
        self.lock.signal()
        input.onBeAdded()
        return self
    }

}
