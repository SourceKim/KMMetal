////  KMMetalImage.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/19.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMMetalImage: KMMetalOutput {
    func clearTexture() {
        self.lock.wait()
        self.internal_texture = nil
        self.lock.signal()
    }
    
    
    var childs = [KMMetalInput]()
    
    private var internal_texture: MTLTexture? // 内部使用
    var texture: MTLTexture? // 外部传值修改
    
    private let lock = DispatchSemaphore(value: 1)
    
    init(uiImage: UIImage) {
        self.texture = uiImage.toTexture(device: KMMetalShared.shared.device, specificSize: nil)
    }
    
    init(cgImage: CGImage) {
        self.texture = cgImage.toTexture(device: KMMetalShared.shared.device, specificSize: nil)
    }
    
    @discardableResult
    func add(input: KMMetalInput) -> Self {
        self.lock.wait()
        self.childs.append(input)
        self.lock.signal()
        input.onBeAdded()
        return self
    }
    
    func process() {
        self.lock.wait()
        if self.internal_texture == nil {
            self.internal_texture = self.texture
        }
        guard let t = self.internal_texture else {
            self.lock.signal()
            return
        }
        let chrs = self.childs
        self.lock.signal()
        
        let kmTexture = KMTexture(texture: t, cameraPosition: nil)
        for chr in chrs {
            chr.next(texture: kmTexture)
        }
        
    }
}
