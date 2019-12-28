////  KMMetalFilterGroup.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/28.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMMetalFilterGroup: NSObject, KMMetalFilterProtocol {
    
    var outputKMTexture: KMMetalTexture?
    
    private var filters: [KMMetalFilterProtocol]
    
    private let lock = DispatchSemaphore(value: 1)
    
    var childs = [KMMetalInput]()
    
    init(filters: [KMMetalFilter]) {
        self.filters = filters
        super.init()
        
        var lastFilter: KMMetalFilter?
        for filter in filters {
            if let lf = lastFilter {
                lf.add(input: filter)
            }
            lastFilter = filter
        }
    }
    
    func next(texture: KMMetalTexture) {
        
        self.lock.wait()
        let _childs = self.childs
        self.lock.signal()
        
        var lastOutKMTexture: KMMetalTexture? = texture
        
        for filter in self.filters {
            guard let t = lastOutKMTexture else { continue }
            filter.next(texture: t)
            lastOutKMTexture = filter.outputKMTexture
        }
        
        self.outputKMTexture = lastOutKMTexture
        
        guard let lastTexture = lastOutKMTexture else { return }
        for c in _childs {
            c.next(texture: lastTexture)
        }
    }
    
    func onBeAdded() {
        
    }
    
    func onProcessEnd() {
        
    }
    
    var object: AnyObject {
        return self
    }
    
    func add(input: KMMetalInput) {
        self.lock.wait()
        self.childs.append(input)
        self.lock.signal()
        input.onBeAdded()
    }
    
    func delete(input: KMMetalInput) {
        self.lock.wait()
        self.childs.removeAll { (ip) -> Bool in
            return ip.object === input.object
        }
        self.lock.signal()
    }
    
}
