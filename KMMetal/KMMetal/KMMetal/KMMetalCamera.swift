////  KMCameraView.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/19.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit
import AVFoundation

protocol KMMetalCameraDelegate: AnyObject {
    func onCapture(sampleBuffer: CMSampleBuffer)
}

class KMMetalCamera: NSObject, KMMetalOutput {
    
    var texture: MTLTexture?
    
    var childs = [KMMetalInput]()
    
    weak var del: KMMetalCameraDelegate?
    
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
    }
    
    func clearTexture() {
        
    }
    
    let lock = DispatchSemaphore(value: 1)
    
    var isPause: Bool {
        get {
            self.lock.wait()
            let ip = self._isPause
            self.lock.signal()
            return ip
        }
        set {
            self.lock.wait()
            self._isPause = newValue
            self.lock.signal()
        }
    }
    private var _isPause = false
    
    var canTakePhoto: Bool {
        get {
            self.lock.wait()
            let ctp = self._canTakePhoto
            self.lock.signal()
            return ctp
        }
        set {
            self.lock.wait()
            self._canTakePhoto = newValue
            self.lock.signal()
        }
    }
    private var _canTakePhoto = false
    
    private var cameraPosition: AVCaptureDevice.Position
    var session: AVCaptureSession
    private var device: AVCaptureDevice
    private var input: AVCaptureInput
    private var output: AVCaptureVideoDataOutput
    
    private let outputQueue = DispatchQueue(
      label: "com.kedc.KMMetal.videoOutput",
      qos: .userInitiated,
      attributes: [],
      autoreleaseFrequency: .workItem)
    
    private var textureCache: CVMetalTextureCache!
    
    init?(cameraPosition: AVCaptureDevice.Position = .back,
          preset: AVCaptureSession.Preset = .high) {
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
            let input = try? AVCaptureDeviceInput(device: device) else {
            return nil
        }
        
        self.session = AVCaptureSession()
        self.cameraPosition = cameraPosition
        self.device = device
        self.input = input
        self.output = AVCaptureVideoDataOutput()
        
        super.init()
        
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, KMMetalShared.shared.device, nil, &self.textureCache) != kCVReturnSuccess ||
            self.textureCache == nil {
            return nil
        }
        
        self.session.beginConfiguration()
        self.session.sessionPreset = preset
        
        if !self.session.canAddInput(input) {
            self.session.commitConfiguration()
            return nil
        }
        
        self.session.addInput(input)
        
        self.output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
        self.output.setSampleBufferDelegate(self, queue: self.outputQueue)
        if !self.session.canAddOutput(self.output) {
            self.session.commitConfiguration()
            return nil
        }
        self.session.addOutput(self.output)
        
        guard let connection = self.output.connection(with: .video) else {
                self.session.commitConfiguration()
                return nil
        }
        connection.videoOrientation = .portrait
        
        self.session.commitConfiguration()
        
    }
    
    func run() {
        self.lock.wait()
        self.session.startRunning()
        self.lock.signal()
    }
    
    func stop() {
        self.lock.wait()
        self.session.stopRunning()
        self.lock.signal()
    }

}

extension KMMetalCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        self.del?.onCapture(sampleBuffer: sampleBuffer)
        
        // Video
        self.lock.wait()
        let paused = self._isPause
        let childs = self.childs
        let cameraPosition = self.device.position
        lock.signal()
        
        guard !paused,
            !childs.isEmpty,
            let texture = sampleBuffer.toTexture(with: self.textureCache) else { return }
        
        self.texture = texture
//        let sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//        let output = BBMetalDefaultTexture(metalTexture: texture.metalTexture,
//                                           sampleTime: sampleTime,
//                                           cameraPosition: cameraPosition,
//                                           cvMetalTexture: texture.cvMetalTexture)
        for child in childs {
            child.next(texture: KMTexture(texture: texture, cameraPosition: cameraPosition))
        }
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print(#function)
    }
}
