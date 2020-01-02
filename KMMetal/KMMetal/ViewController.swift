////  ViewController.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/17.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    private let camera = KMMetalCamera(cameraPosition: .front, preset: .high)
    private let sourceImage = KMMetalImage(uiImage: UIImage(named: "img0.png")!)
    private lazy var metalView = KMMetalView()
    private let brightnessKernel = KMBrightnessFilter()
    private let faceDetector = KMFaceDetector()
    let thinFaceFilter0 = KMThinFaceFilter()
    let thinFaceFilter1 = KMThinFaceFilter()
    let skinSmoothFilter = KMSkinSmoothFilter()
    let cropFilter = KMCropFilter()
    var previewLayer: AVCaptureVideoPreviewLayer!
    let boxV = UIView()
    var views = [UILabel]()
    let intensitySlider = UISlider(frame: CGRect(x: 10, y: 50, width: 300, height: 40))
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.faceDetector.setup()
        self.faceDetector.del = self
        
//        self.camera?.add(input: self.thinFaceFilter0)
//        self.sourceImage.add(input: self.cropFilter)
//        self.cropFilter.normalizedRect = KMNormalizedRect(x: 0, y: 0, width: 1, height: 0.5)
//        self.cropFilter.add(input: self.metalView)
        self.camera?.del = self
        self.camera?.add(input: self.thinFaceFilter0)
        self.thinFaceFilter0.add(input: self.thinFaceFilter1)
        self.thinFaceFilter1.add(input: self.metalView)
//        self.camera?.add(input: self.metalView)
        self.metalView.frame = self.view.bounds
//        previewLayer = AVCaptureVideoPreviewLayer(session: self.camera!.session)
//        previewLayer.videoGravity = .resizeAspectFill
//        previewLayer.frame = self.view.bounds
//        view.layer.insertSublayer(previewLayer, at: 0)
//        self.lookupKernel.setLutImage(uiImage: UIImage(named: "lookup_amatorka.png")!)
//        self.sourceImage.add(input: self.lookupKernel)
//        self.lookupKernel.add(input: self.metalView)
//        self.sourceImage.add(input: self.metalView)
        self.view.addSubview(self.metalView)
        
        self.camera?.run()
//        DispatchQueue.main.asyncAfter(deadline: .now()) {
//            self.sourceImage.process()
//        }
        
//        self.view.addSubview(self.boxV)
//        self.boxV.backgroundColor = .red
//
//        self.camera?.run()
        
        for i in 0..<75 {
            let v = UILabel()
            v.frame = CGRect(x: 0, y: 0, width: 35, height: 10)
//            v.backgroundColor = .systemPurple
            v.font = UIFont.systemFont(ofSize: 10)
            v.textColor = .black
            v.text = "\(i)"
            self.views.append(v)
            self.metalView.addSubview(v)
        }
        
        self.intensitySlider.addTarget(self, action: #selector(ViewController.onSliderChanged(sender:)), for: .valueChanged)
        self.intensitySlider.minimumValue = 0
        self.intensitySlider.maximumValue = 5
        self.intensitySlider.value = 0
        self.view.addSubview(self.intensitySlider)
        
//        self.sourceImage.add(input: self.brightnessKernel)
//        self.camera?.add(input: self.brightnessKernel)
//        self.brightnessKernel.add(input: self.metalView)
//        
//        self.sourceImage.process()

    }
    
    @objc private func onSliderChanged(sender: UISlider) {
        self.thinFaceFilter0.intensity = sender.value
        self.thinFaceFilter1.intensity = sender.value
    }

}

extension ViewController: KMFaceDetectorDelegate {
    func onDetetionFinished(res: [[NSValue]]) {
        if let firstRes = res.first {
            
            DispatchQueue.main.async {
                let matrix = CGAffineTransform.transformMatrix(fromSize: CGSize(width: 1080, height: 1920), toSize: self.metalView.bounds.size)
                for i in 0..<firstRes.count {
                    let p = firstRes[i].cgPointValue.applying(matrix)
                    self.views[i].center = p
                }
            }

            self.thinFaceFilter0.setParams(startPoint: firstRes[7].cgPointValue, radiusPoint: firstRes[5].cgPointValue, referencePoint: firstRes[28].cgPointValue)
            self.thinFaceFilter1.setParams(startPoint: firstRes[9].cgPointValue, radiusPoint: firstRes[11].cgPointValue, referencePoint: firstRes[28].cgPointValue)
        }
    }
}
extension ViewController: KMMetalCameraDelegate {
    func onCapture(sampleBuffer: CMSampleBuffer, output: AVCaptureOutput, connection: AVCaptureConnection) {
        self.faceDetector.onSamplebufferOutput(sampleBuffer, output: output, connection: connection)
    }
    
    func onCapture(faceMetaObjects: [AVMetadataObject]) {
        self.faceDetector.onMetadataObjectsOuput(faceMetaObjects)
    }
    
    func onCapture(sampleBuffer: CMSampleBuffer) {
//        self.outputQueue.async {
//            self.faceDetector.detect(sampleBuffer: sampleBuffer) { (results) in
//                if results.count != 0 {
//                    let res = results[0]
                    
//                    DispatchQueue.main.async {
//                        let faceBounds = res.boundingBox
//                        let convetedBox = CGRect(x: faceBounds.origin.x * 360, y: faceBounds.origin.y * 480, width: faceBounds.width * 360, height: faceBounds.height * 480)
//                        let mtx = CGAffineTransform.transformMatrix(fromSize: CGSize(width: 360, height: 480), toSize: CGSize(width: self.view.bounds.width, height: self.view.bounds.height))
//                        let r2 = faceBounds.applying(mtx)
//                        self.boxV.frame = r2 //CGRect(x: 360 - r2.origin.x - r2.width, y: r2.origin.y, width: r2.width, height: r2.height)
//                        self.thinFaceFilter0.setParams(startPoint: res.points[65], radiusPoint: res.points[63], referencePoint: res.points[47])
//                        self.thinFaceFilter1.setParams(startPoint: res.points[69], radiusPoint: res.points[71], referencePoint: res.points[47])
//                        var idx = 0
//                        for p in self.views {
//                            p.center = res.points[idx].applying(mtx)
//                            idx += 1
//                        }
//                    }

//                    let affineTransform = CGAffineTransform(translationX: faceBounds.origin.x, y: faceBounds.origin.y)
//                    .scaledBy(x: faceBounds.size.width, y: faceBounds.size.height)

//                    self.thinFaceFilter.setParams(startPoint: res.points[65], radiusPoint: res.points[63], referencePoint: res.points[47])
//                    print(res.points[65].applying(affineTransform))
//                }
//            }
//        }

        var didDetect = false
//        if let size = self.faceDetector.loadResource(sampleBuffer) {
//            if let res = self.faceDetector.detect(transformSize: size).first {
//                self.thinFaceFilter.setParams(startPoint: res.points[65], radiusPoint: res.points[63], referencePoint: res.points[47])
//                didDetect = true
//            }
//        }
        if !didDetect {
//            self.thinFaceFilter.noFaceDetected()
        }
    }
    
}

