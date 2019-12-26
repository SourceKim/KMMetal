////  KMFaceDetector.swift
//  KMFaceDetector
//
//  Created by Su Jinjin on 2019/12/23.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

struct KMFaceDetectResult {
    let trackId: String // 脸部标记
    let boundingBox: CGRect
    let points: [CGPoint]
}

typealias KMFaceDetectorCallback = (_ results: [KMFaceDetectResult]) -> ()

class KMFaceDetector {
    
    // Vision requests
    var sequenceHandler = VNSequenceRequestHandler()
    
    
    func detect(sampleBuffer: CMSampleBuffer,
                callback: KMFaceDetectorCallback?) {
        // 1
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // 2
//        let detectFaceRequest = VNDetectFaceLandmarksRequest()
        let detectFaceRequest = VNDetectFaceLandmarksRequest { (req, err) in
            guard let ress = req.results as? [VNFaceObservation], let callback = callback else {
                return
            }

            var outputs = [KMFaceDetectResult]()
            for res in ress {
                let box = VNImageRectForNormalizedRect(res.boundingBox, 360, 480)
                let points = res.landmarks?.allPoints?.pointsInImage(imageSize: CGSize(width: 360, height: 480))
                let output = KMFaceDetectResult(trackId: "1", boundingBox: box, points: points!)
                outputs.append(output)
            }
            callback(outputs)
        }
//
        // 3
        do {
            try sequenceHandler.perform(
                [detectFaceRequest],
                on: imageBuffer,
                orientation: .down) // Front camera detecting is 'down'
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func exifOrientationForCurrentDeviceOrientation() -> CGImagePropertyOrientation {
        return exifOrientationForDeviceOrientation(UIDevice.current.orientation)
    }
    
    private func exifOrientationForDeviceOrientation(_ deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
        
        switch deviceOrientation {
        case .portraitUpsideDown:
            return .rightMirrored
            
        case .landscapeLeft:
            return .downMirrored
            
        case .landscapeRight:
            return .upMirrored
            
        default:
            return .leftMirrored
        }
    }
    
    private func outputResults(_ results: [VNFaceObservation],
                               bufferWidth: Int,
                               bufferHeight: Int,
                               callback: KMFaceDetectorCallback) {
        
        var kmResults = [KMFaceDetectResult]()
        for result in results {
            
            guard let points = result.landmarks?.allPoints?.normalizedPoints else {
                continue
            }
            
            let id = result.uuid.uuidString
            let faceBounds = VNImageRectForNormalizedRect(result.boundingBox, bufferWidth, bufferHeight)
            
            let kmResult = KMFaceDetectResult(trackId: id,
                                              boundingBox: faceBounds,
                                              points: points)
            kmResults.append(kmResult)
        }
        
        callback(kmResults)
    }
    
    //    func loadResource(_ sampleBuffer: CMSampleBuffer) -> CGSize? {
    //        if let bufferRef = CMSampleBufferGetImageBuffer(sampleBuffer) {
    //            self.handler = VNImageRequestHandler(cvPixelBuffer: bufferRef, options: [:])
    //            let w = CGFloat(CVPixelBufferGetWidth(bufferRef))
    //            let h = CGFloat(CVPixelBufferGetHeight(bufferRef))
    //            return CGSize(width: w, height: h)
    //        }
    //        return nil
    //    }
    //
    //    func loadResource(_ cgImage: CGImage) -> CGSize? {
    //        self.handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    //        let w = CGFloat(cgImage.width)
    //        let h = CGFloat(cgImage.height)
    //        return CGSize(width: w, height: h)
    //    }
    //
    //    func loadResource(_ uiImage: UIImage) -> CGSize? {
    //        if let cgImage = uiImage.cgImage {
    //            return self.loadResource(cgImage)
    //        }
    //        return nil
    //    }
    
    /// 检测脸部
    /// - Parameter transformSize: 转换 size，会把结果 （包括 BoundingBox 和 Points）转换到 image (对应的 size) 上
    //    func detect(transformSize: CGSize? = nil) -> [KMFaceDetectResult] {
    //        var results = [KMFaceDetectResult]()
    //        if let handler = self.handler {
    //            if let _ = try? handler.perform([self.req]) {
    //                if let faces = self.req.results as? [VNFaceObservation] {
    //                    for face in faces {
    //                        let trackId = face.uuid.uuidString
    //                        var boundingBox = CGRect()
    //                        var points = [CGPoint]()
    //                        if let size = transformSize { // 有传入转化 size
    //                            if let ps = face.landmarks?.allPoints?.pointsInImage(imageSize: size) {
    //                                points = ps
    //                            }
    //                            boundingBox = CGRect(x: face.boundingBox.origin.x * size.width,
    //                                                 y: face.boundingBox.origin.y * size.height,
    //                                                 width: face.boundingBox.size.width * size.width,
    //                                                 height: face.boundingBox.size.height * size.height)
    //                        } else { // 无传入转化 size
    //                            if let ps = face.landmarks?.allPoints?.normalizedPoints {
    //                                points = ps
    //                            }
    //                            boundingBox = face.boundingBox
    //                        }
    //                        let res = KMFaceDetectResult(trackId: trackId,
    //                                                     boundingBox: boundingBox,
    //                                                     points: points)
    //                        results.append(res)
    //                    }
    //
    //                }
    //            }
    //        }
    //        return results
    //    }
}
