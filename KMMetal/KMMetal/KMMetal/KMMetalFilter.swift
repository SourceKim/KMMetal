////  KMMetalFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/17.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMMetalFilter: KMMetalInput, KMMetalOutput {
    func clearTexture() {
        self.lock.wait()
        self.texture = nil
        self.lock.signal()
    }
    
    var texture: MTLTexture?
    
    let pipelineState: MTLComputePipelineState
    let threadsPerThreadgroup: MTLSize
    var threadgroupsPerGrid: MTLSize?
    
    var childs = [KMMetalInput]()
    private var parents = [KMMetalOutput]()
    
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
        let ps = self.parents
        self.lock.signal()
        
        guard let parentsTextures = self.checkIsParentsReady(parents: ps) else { return }
        
        // todo, 考虑 resize filter
        
        guard let commandBuffer = KMMetalShared.shared.queue.makeCommandBuffer() else {
            return
        }
        
        let w = self.threadsPerThreadgroup.width
        let h = self.threadsPerThreadgroup.height
        
        guard let firstTexture = parentsTextures.first else { return }
            
        self.threadgroupsPerGrid = MTLSize(width: (firstTexture.width + w - 1) / w,
                                           height: (firstTexture.height + h - 1) / h,
                                           depth: 1)
        
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        encoder.setComputePipelineState(self.pipelineState)
        var idx = 0
        for texture in parentsTextures {
            encoder.setTexture(texture, index: idx)
            idx += 1
        }
        
        self.updateUniforms(encoder: encoder)
        
        encoder.dispatchThreadgroups(self.threadgroupsPerGrid!, threadsPerThreadgroup: self.threadsPerThreadgroup)
        encoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
//        MTLCaptureManager.shared().stopCapture()
        
        // 清除 parents 的 texture
        self.clearTexture()
        self.texture = firstTexture
        
        for child in self.childs {
            child.next(texture: KMTexture(texture: firstTexture, cameraPosition: nil))
        }
        
    }
    
    func onProcessEnd() {
        
    }
    
    func add(input: KMMetalInput) -> Self {
        self.lock.wait()
        self.childs.append(input)
        self.lock.signal()
        input.addFather(output: self)
        return self
    }
    
    func addFather(output: KMMetalOutput) {
        self.lock.wait()
        self.parents.append(output)
        self.lock.signal()
    }
    
    /// Check is all parents output's textures are ready, will return the first output
    private func checkIsParentsReady(parents: [KMMetalOutput]) -> [MTLTexture]? {
        
        let parentsAvailableTextures = parents.compactMap { (op) -> MTLTexture? in
            return op.texture
        }
        
        guard parentsAvailableTextures.count == parents.count else {
            print("Not all parents' textures are available")
            return nil
        }
        
        return parentsAvailableTextures
    }
    
    private func cleanParentsTexture() {
        for parent in self.parents {
            parent.clearTexture()
        }
    }

}
