////  KMTexture.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/18.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import Metal
import AVFoundation

struct KMTexture: KMMetalTexture {
    
    var texture: MTLTexture
    
    var cameraPosition: AVCaptureDevice.Position?
    
}
