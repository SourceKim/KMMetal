////  KMMetalView.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/17.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit
import MetalKit

class KMMetalView: MTKView, KMMetalInput {

    var object: AnyObject {
        return self
    }
    
    func onBeAdded() {
        
    }
    
    func onBeDeleted() {
        
    }
    
    private var _processCallback: (() -> ())?
    
    private let lock = DispatchSemaphore(value: 1)
    
    var rotation = KMTextureRotation.Rotate0Degrees
    private var internal_rotation = KMTextureRotation.Rotate0Degrees
    
    var isMirror = false
    private var internal_isMirror = false
    
    var isFrontCamera = false
    private var internal_isFrontCamera = false
    
    var textureContentMode = KMTextureContentMode.AspectRatioFit
    private var internal_textureContentMode = KMTextureContentMode.AspectRatioFit
    
    private var frameSize: CGSize = .zero
    private var internal_frameSize: CGSize = .zero
    
    private var oldTextureWidth = 0
    private var oldTextureHeight = 0
    
    private var vertexBuffer: MTLBuffer?
    private var textureBuffer: MTLBuffer?
    
    private var pipeline: MTLRenderPipelineState?
    private var texture: MTLTexture?

    init() {
        super.init(frame: .zero, device: KMMetalShared.shared.device)
        super.isPaused = true
        
        if let library = self.device?.makeDefaultLibrary(),
            let vertexFunc = library.makeFunction(name: "vertexPassThrough"),
            let fragFunc = library.makeFunction(name: "fragmentPassThrough") {
            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction = vertexFunc
            desc.fragmentFunction = fragFunc
            desc.colorAttachments[0].pixelFormat = self.colorPixelFormat
            if let state = try? self.device?.makeRenderPipelineState(descriptor: desc) {
                self.pipeline = state
            }
        }
        
        self.preferredFramesPerSecond = 30
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.lock.wait()
        self.frameSize = self.bounds.size
        self.lock.signal()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func next(texture: KMMetalTexture) {
        self.lock.wait()
        self.texture = texture.texture
        self.isFrontCamera = texture.cameraPosition == .front
        self.draw()
        self.lock.signal()
    }
    
    func setProcessCallback(_ processCallback: (() -> ())?) {
        self.lock.wait()
        _processCallback = processCallback
        self.lock.signal()
    }
    
    func addFather(output: KMMetalOutput) {
    }
    
    override func draw(_ rect: CGRect) {
        
        guard let texture = self.texture,
            let drawable = self.currentDrawable,
            let desc = self.currentRenderPassDescriptor,
            let commandBuffer = KMMetalShared.shared.queue.makeCommandBuffer(),
            let pipeline = self.pipeline else {
                return
        }
        
//        MTLCaptureManager.shared().startCapture(commandQueue: KMMetalShared.shared.queue)
                let manager = MTLCaptureManager.shared()
                manager.defaultCaptureScope?.begin()
        self.drawableSize = CGSize(width: texture.width, height: texture.height)
        
        self.updateVertexBufferIfNeed(texture: texture)
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: desc) else { return }
        
        encoder.setRenderPipelineState(pipeline)
        
        encoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(self.textureBuffer, offset: 0, index: 1)
        encoder.setFragmentTexture(texture, index: 0)
        
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        
        commandBuffer.commit()
        
        if let callback = self._processCallback {
            commandBuffer.addCompletedHandler { (_) in
                callback()
            }
        }
        
        manager.defaultCaptureScope?.end()
//        MTLCaptureManager.shared().stopCapture()
    }
    
    private func updateVertexBufferIfNeed(texture: MTLTexture) {
        
        if self.frameSize != self.internal_frameSize ||
            self.oldTextureWidth != texture.width ||
            self.oldTextureHeight != texture.height ||
            self.isFrontCamera != self.internal_isFrontCamera ||
            self.isMirror != self.internal_isMirror ||
            self.rotation != self.internal_rotation ||
            self.textureContentMode != self.internal_textureContentMode {
            
            self.internal_frameSize = self.frameSize
            self.oldTextureWidth = texture.width
            self.oldTextureHeight = texture.height
            self.internal_isFrontCamera = self.isFrontCamera
            self.internal_isMirror = self.isMirror
            self.internal_rotation = self.rotation
            self.internal_textureContentMode = self.textureContentMode
            
            var scaleX: Float = 1
            var scaleY: Float = 1
            
            if self.textureContentMode != .Fill {
                if self.oldTextureWidth > 0 && self.oldTextureHeight > 0 {
                    switch self.internal_rotation {
                    case .Rotate0Degrees, .Rotate180Degrees:
                        scaleX = Float(self.internal_frameSize.width / CGFloat(self.oldTextureWidth))
                        scaleY = Float(self.internal_frameSize.height / CGFloat(self.oldTextureHeight))
                        
                    case .Rotate90Degrees, .Rotate270Degrees:
                        scaleX = Float(self.internal_frameSize.width / CGFloat(self.oldTextureHeight))
                        scaleY = Float(self.internal_frameSize.height / CGFloat(self.oldTextureWidth))
                    }
                }
                if scaleX < scaleY {
                    if self.textureContentMode == .AspectRatioFill {
                        scaleX = scaleY / scaleX
                        scaleY = 1
                    } else {
                        scaleY = scaleX / scaleY
                        scaleX = 1
                    }
                } else {
                    if textureContentMode == .AspectRatioFit {
                        scaleY = scaleX / scaleY
                        scaleX = 1
                    } else {
                        scaleX = scaleY / scaleX
                        scaleY = 1
                    }
                }
            }
            
            if self.internal_isMirror != self.internal_isFrontCamera { scaleX = -scaleX }
            
            let vertexData: [Float] = [
                -scaleX, -scaleY,
                +scaleX, -scaleY,
                -scaleX, +scaleY,
                +scaleX, +scaleY,
            ]
            
            self.vertexBuffer = device!.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
            
            var textData: [Float]
            switch self.rotation {
            case .Rotate0Degrees:
                textData = [
                    0.0, 1.0,
                    1.0, 1.0,
                    0.0, 0.0,
                    1.0, 0.0
                ]
            case .Rotate180Degrees:
                textData = [
                    1.0, 0.0,
                    0.0, 0.0,
                    1.0, 1.0,
                    0.0, 1.0
                ]
            case .Rotate90Degrees:
                textData = [
                    1.0, 1.0,
                    1.0, 0.0,
                    0.0, 1.0,
                    0.0, 0.0
                ]
            case .Rotate270Degrees:
                textData = [
                    0.0, 0.0,
                    0.0, 1.0,
                    1.0, 0.0,
                    1.0, 1.0
                ]
            }
            self.textureBuffer = device?.makeBuffer(bytes: textData, length: textData.count * MemoryLayout<Float>.size, options: [])
            
        }
    }
}
