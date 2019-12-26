////  ViewController.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/17.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private let camera = KMMetalCamera()
    private let sourceImage = KMMetalImage(uiImage: UIImage(named: "img0.png")!)
    private lazy var metalView = KMMetalView()
    private let brightnessKernel = KMBrightnessFilter()
//    private let lookupKernel = KMLookUpFilter()

    override func viewDidLoad() {
        super.viewDidLoad()

//        self.camera?.add(input: self.lookupKernel)
//        self.lookupKernel.setLutImage(uiImage: UIImage(named: "lookup_amatorka.png")!)
//        self.sourceImage.add(input: self.lookupKernel)
//        self.lookupKernel.add(input: self.metalView)
//        self.sourceImage.add(input: self.metalView)
        self.view.addSubview(self.metalView)
        
        self.camera?.run()
        
//        self.sourceImage.add(input: self.brightnessKernel)
//        self.camera?.add(input: self.brightnessKernel)
//        self.brightnessKernel.add(input: self.metalView)
//        
//        self.sourceImage.process()

    }

}

