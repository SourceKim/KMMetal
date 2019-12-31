////  KMMetalFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/17.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMMetalFilter: NSObject, KMMetalFilterProtocol {
    
    func onBeDeleted() {
        self.lock.wait()
        self.parentCount -= 1
        self.lock.signal()
    }

    var object: AnyObject {
        return self
    }
    
    private var _processCallback: (() -> ())?
    
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
    
    var outputKMTexture: KMMetalTexture?
    
    var isSync: Bool {
        get {
            self.lock.wait()
            let v = self._isSync
            self.lock.signal()
            return v
        }
        set {
            self.lock.wait()
            self._isSync = newValue
            self.lock.signal()
        }
    }
    
    private var _isSync: Bool = true

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
    
    /// Get output texture size by input texture size
    /// - Parameter inputSize: input texture size
    func getOutputTextureSize(by inputSize: KMTextureSize) -> KMTextureSize {
        return inputSize
    }
    
    func next(texture: KMMetalTexture) {
        
//        let manager = MTLCaptureManager.shared()
//        manager.defaultCaptureScope?.begin()
        
//        MTLCaptureManager.shared().startCapture(commandQueue: KMMetalShared.shared.queue)
        
        self.lock.wait()
        self.parentTextures.append(texture)
        let ps = self.parentTextures
        let parentCount = self.parentCount
        
        // Check is textures all ready
        if ps.count != parentCount {
            self.lock.signal()
            return // If not, will wait here for feeding.
        }
        self.lock.signal()
        
        // todo, 考虑 resize filter
        
        guard let commandBuffer = KMMetalShared.shared.queue.makeCommandBuffer() else {
            return
        }
        
        let w = self.threadsPerThreadgroup.width
        let h = self.threadsPerThreadgroup.height
        
        guard let firstTexture = ps.first?.texture else { return }
        
        let outputTextureSize = self.getOutputTextureSize(by: firstTexture.size)
        
        // 重新创建 OutputTexture
        self.lock.wait()
        if self.outputTexture == nil ||
            self.outputTexture?.width != outputTextureSize.width ||
            self.outputTexture?.height != outputTextureSize.height {
            let desc = MTLTextureDescriptor()
            desc.pixelFormat = .rgba8Unorm
            desc.width = outputTextureSize.width
            desc.height = outputTextureSize.height
            desc.usage = [.shaderRead, .shaderWrite]
            if let o = KMMetalShared.shared.device.makeTexture(descriptor: desc) {
                self.outputTexture = o
            } else {
                self.lock.signal()
                return
            }
        }
            
        self.threadgroupsPerGrid = MTLSize(width: (outputTextureSize.width + w - 1) / w,
                                           height: (outputTextureSize.height + h - 1) / h,
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
        if self._isSync {
            commandBuffer.waitUntilCompleted()
        }
        
        if let callback = self._processCallback {
            commandBuffer.addCompletedHandler { (_) in
                callback()
            }
        }
        
//        MTLCaptureManager.shared().stopCapture()
//        manager.defaultCaptureScope?.end()
        
        // 清除 parents 的 texture
        self.parentTextures.removeAll()
        guard let ot = self.outputTexture else {
            self.lock.signal()
            return
        }
        let outkmt = KMTexture(texture: ot, cameraPosition: texture.cameraPosition)
        self.lock.signal()
        
        self.outputKMTexture = outkmt
        
        for child in self.childs {
            child.next(texture: outkmt)
        }
        
    }
    
    func setProcessCallback(_ processCallback: (() -> ())?) {
        self.lock.wait()
        _processCallback = processCallback
        self.lock.signal()
    }
    
    func add(input: KMMetalInput) {
        self.lock.wait()
        self.childs.append(input)
        self.lock.signal()
        input.onBeAdded()
    }
    
    func delete(input: KMMetalInput) {
        self.lock.wait()
        self.childs.removeAll { (ip) -> Bool in
            return ip.object === input.object
        }
        self.lock.signal()
        input.onBeDeleted()
    }

}
