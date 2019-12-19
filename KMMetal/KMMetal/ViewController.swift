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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.metalView)
        self.sourceImage.add(output: self.metalView)
        self.sourceImage.process()
    }

}

