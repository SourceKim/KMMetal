////  KMFaceDetector.swift
//  KMFaceDetector
//
//  Created by Su Jinjin on 2019/12/23.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

protocol KMFaceDetectorDelegate: AnyObject {
    func onDetetionFinished(res: [[NSValue]])
}

class KMFaceDetector {
    
    var currentMetadata = [AVMetadataObject]()
    
    var dlibHelper = DlibHelper()
    
    weak var del: KMFaceDetectorDelegate?
    
    func setup() {
        self.dlibHelper.loadModel()
    }
    
    func onMetadataObjectsOuput(_ objs: [AVMetadataObject]) {
        self.currentMetadata = objs
    }
    
    func onSamplebufferOutput(_ sampleBuffer: CMSampleBuffer,
                              output: AVCaptureOutput,
                              connection: AVCaptureConnection) {
        
        if !self.currentMetadata.isEmpty {
            let rects = self.currentMetadata
                .compactMap { $0 as? AVMetadataFaceObject }
                .map { (faceObject) -> NSValue in
                    let convertedObject = output.transformedMetadataObject(for: faceObject, connection: connection)
                    return NSValue(cgRect: convertedObject!.bounds)
            }
            
            let res = self.dlibHelper.detect(sampleBuffer, inside: rects)
            self.del?.onDetetionFinished(res: res)
        }
    }
}
