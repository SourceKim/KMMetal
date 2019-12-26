////  ViewController.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/17.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    private let camera = KMMetalCamera(cameraPosition: .front, preset: .medium)
    private let sourceImage = KMMetalImage(uiImage: UIImage(named: "img0.png")!)
    private lazy var metalView = KMMetalView()
    private let brightnessKernel = KMBrightnessFilter()
    private let faceDetector = KMFaceDetector()
    var previewLayer: AVCaptureVideoPreviewLayer!
    let boxV = UIView()
    var views = [UIView]()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.camera?.del = self
//        self.camera?.add(input: self.thinFaceFilter)
//        self.thinFaceFilter.add(input: self.metalView)
        self.camera?.add(input: self.metalView)
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
        
        self.view.addSubview(self.boxV)
        self.boxV.backgroundColor = .red
        
        self.camera?.run()
        
        for i in 0..<75 {
            let v = UIView()
            v.frame = CGRect(x: 0, y: 0, width: 5, height: 5)
            v.backgroundColor = .systemPurple
            self.views.append(v)
            self.metalView.addSubview(v)
        }
        
//        self.sourceImage.add(input: self.brightnessKernel)
//        self.camera?.add(input: self.brightnessKernel)
//        self.brightnessKernel.add(input: self.metalView)
//        
//        self.sourceImage.process()

    }
    
    private let outputQueue = DispatchQueue(label: "com.kedc.detectQueue")

}

extension ViewController: KMMetalCameraDelegate {
    func onCapture(sampleBuffer: CMSampleBuffer) {
//        self.outputQueue.async {
            self.faceDetector.detect(sampleBuffer: sampleBuffer) { (results) in
                if results.count != 0 {
                    let res = results[0]
                    
                    DispatchQueue.main.async {
                        let faceBounds = res.boundingBox
                        let convetedBox = CGRect(x: faceBounds.origin.x * 360, y: faceBounds.origin.y * 480, width: faceBounds.width * 360, height: faceBounds.height * 480)
                        let mtx = CGAffineTransform.transformMatrix(fromSize: CGSize(width: 360, height: 480), toSize: CGSize(width: self.view.bounds.width, height: self.view.bounds.height))
//                        let r2 = faceBounds.applying(mtx)
//                        self.boxV.frame = r2 //CGRect(x: 360 - r2.origin.x - r2.width, y: r2.origin.y, width: r2.width, height: r2.height)
                        
                        var idx = 0
                        for p in self.views {
                            p.center = res.points[idx].applying(mtx)
                            idx += 1
                        }
                    }

//                    let affineTransform = CGAffineTransform(translationX: faceBounds.origin.x, y: faceBounds.origin.y)
//                    .scaledBy(x: faceBounds.size.width, y: faceBounds.size.height)

//                    self.thinFaceFilter.setParams(startPoint: res.points[65], radiusPoint: res.points[63], referencePoint: res.points[47])
//                    print(res.points[65].applying(affineTransform))
                }
            }
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

