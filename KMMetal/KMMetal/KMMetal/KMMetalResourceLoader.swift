////  KMMetalResourceLoader.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/17.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMMetalResourceLoader {

    private var textures = [Int: MTLTexture]()
    
    private var idx = 0
    
    private var device: MTLDevice
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    func loadImage(_ image: UIImage) {
        let texture = image.toTexture(device: self.device)
        self.textures[idx] = texture
        idx += 1
    }

}
