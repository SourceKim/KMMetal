////  KMCameraView.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/19.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit
import AVFoundation

protocol KMMetalCameraDelegate: AnyObject {
    func onCapture(sampleBuffer: CMSampleBuffer, output: AVCaptureOutput, connection: AVCaptureConnection)
    func onCapture(faceMetaObjects: [AVMetadataObject])
    func onCapturePhoto(texuture: KMTexture?)
}

class KMMetalCamera: NSObject, KMMetalOutput {
    
    var outputKMTexture: KMMetalTexture?
    
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
    
    var cameraPosition: AVCaptureDevice.Position {
        return self.device.position
    }
    
    var session: AVCaptureSession
    private var device: AVCaptureDevice
    private var input: AVCaptureInput
    private var output: AVCaptureVideoDataOutput
    private var metaOutput: AVCaptureMetadataOutput?
    private let outputQueue = DispatchQueue(
      label: "com.kedc.KMMetal.videoOutput",
      qos: .userInitiated,
      attributes: [],
      autoreleaseFrequency: .workItem)
    
    private let metaOutputQueue = DispatchQueue(
      label: "com.kedc.KMMetal.metalOutput",
      qos: .userInitiated,
      attributes: [],
      autoreleaseFrequency: .workItem)
    
    private var textureCache: CVMetalTextureCache!
    
    init?(cameraPosition: AVCaptureDevice.Position = .back,
          preset: AVCaptureSession.Preset = .high,
          needCaptureMetadata: Bool = true) {
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
            let input = try? AVCaptureDeviceInput(device: device) else {
            return nil
        }
        
        self.session = AVCaptureSession()
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
        
        if needCaptureMetadata {
            let mo = AVCaptureMetadataOutput()
            if self.session.canAddOutput(mo) {
                self.session.addOutput(mo)
            }
            self.metaOutput = mo
            self.metaOutput?.setMetadataObjectsDelegate(self, queue: self.metaOutputQueue)
        }

        
        guard let connection = self.output.connection(with: .video) else {
                self.session.commitConfiguration()
                return nil
        }
        connection.videoOrientation = .portrait
//        connection.isVideoMirrored = true
        
        self.session.commitConfiguration()
        
        // availableMetadataObjectTypes change when output is added to session.
        // before it is added, availableMetadataObjectTypes is empty
        metaOutput?.metadataObjectTypes = [AVMetadataObject.ObjectType.face]
        
    }
    
    func switchCamera() -> Bool {
        self.lock.wait()
        self.session.beginConfiguration()
        
        let newPosition: AVCaptureDevice.Position = self.cameraPosition == .back ? .front : .back
        
        guard
            let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
        let newInput = try? AVCaptureDeviceInput(device: newDevice)
        else {
            self.session.commitConfiguration()
            self.lock.signal()
            return false
        }
        
        self.session.removeInput(self.input)
        
        guard self.session.canAddInput(newInput) else {
            self.session.addInput(self.input)
            self.session.commitConfiguration()
            self.lock.signal()
            return false
        }
        
        self.session.addInput(newInput)
        self.device = newDevice
        self.input = newInput
                
        guard
            let connection = self.output.connections.first,
            connection.isVideoOrientationSupported else {
                self.session.addInput(self.input)
                self.session.commitConfiguration()
                self.lock.signal()
                return false
        }
        
        connection.videoOrientation = .portrait
        
        self.session.commitConfiguration()
        self.lock.signal()
        
        return true
    }
    
    // MARK: - Photo ouput
    private var photoOutput: AVCapturePhotoOutput?
    func addPhotoOutput() -> Bool {
        self.lock.wait()
        
        guard self.photoOutput == nil else {
            self.lock.signal()
            return false
        }
        
        self.session.beginConfiguration()
        
        let output = AVCapturePhotoOutput()
        
        guard self.session.canAddOutput(output) else {
            self.session.commitConfiguration()
            self.lock.signal()
            return false
        }
        
        self.session.canAddOutput(output)
        self.photoOutput = output
        self.session.commitConfiguration()
        self.lock.signal()
        return true
    }
    
    func takePhoto() {
        self.lock.wait()
        if let output = self.photoOutput {
            output.capturePhoto(with: AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]),
                                delegate: self)
        }
        self.lock.signal()
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

extension KMMetalCamera: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        self.lock.wait()
        self.del?.onCapture(sampleBuffer: sampleBuffer, output: output, connection: connection)
        self.lock.signal()
        
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
        let outKMTexture = KMTexture(texture: texture, cameraPosition: cameraPosition)
        self.outputKMTexture = outKMTexture
        for child in childs {
            child.next(texture: outKMTexture)
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        self.del?.onCapture(faceMetaObjects: metadataObjects)
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print(#function)
    }
}

extension KMMetalCamera: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard
            let pixelBuffer = photo.pixelBuffer,
            let metalTexture = pixelBuffer.toTexture(with: self.textureCache)
        else {
                self.del?.onCapturePhoto(texuture: nil)
                return
        }
        
        self.del?.onCapturePhoto(texuture: KMTexture(texture: metalTexture,
                                                     cameraPosition: self.cameraPosition))
        
    }
}
