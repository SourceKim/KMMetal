////  ViewController.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/17.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private lazy var metalView = KMMetalView(frame: self.view.bounds)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let img = UIImage(named: "img1.png")!
        let texture = img.toTexture(device: KMMetalShared.shared.device)
        self.view.addSubview(self.metalView)
        let t = KMTexture(texture: texture!, cameraPosition: .front)
        self.metalView.next(texture: t)
        
    }


}

