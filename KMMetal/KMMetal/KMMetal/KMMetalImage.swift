////  KMMetalImage.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/19.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMMetalImage: NSObject, KMMetalOutput {
    
    func delete(input: KMMetalInput) {
        self.lock.wait()
        self.childs.removeAll { (ip) -> Bool in
            return ip.object === input.object
        }
        self.lock.signal()
    }
    
    
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
    
    func add(input: KMMetalInput) {
        self.lock.wait()
        self.childs.append(input)
        self.lock.signal()
        input.onBeAdded()
    }
    
    var object: NSObject {
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
