////  ViewController.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/17.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private let sourceImage = KMMetalImage(uiImage: UIImage(named: "img1.png")!)
    private lazy var metalView = KMMetalView(frame: self.view.bounds)
    private let brightnessKernel = KMBrightnessFilter()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.metalView)
        
        self.sourceImage.add(input: self.brightnessKernel)
        self.brightnessKernel.add(input: self.metalView)
        
        self.sourceImage.process()

    }

}

