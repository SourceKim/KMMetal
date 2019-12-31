////  KMMetalFilterGroup.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/28.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMMetalFilterGroup: NSObject, KMMetalFilterProtocol {
    
    var isSync: Bool = true
    
    var outputKMTexture: KMMetalTexture?
    
    func onBeAdded() {
        for filter in self.filters {
            filter.onBeAdded()
        }
    }
    
    func onBeDeleted() {
        
    }
    
    func setProcessCallback(_ processCallback: (() -> ())?) {
        
    }
    
    var object: AnyObject {
        return self
    }
    
    
    private var filters: [KMMetalFilterProtocol]
    private var terminateFilter: KMMetalFilterProtocol
    
    private let lock = DispatchSemaphore(value: 1)
    
    init(filters: [KMMetalFilterProtocol], terminateFilter: KMMetalFilterProtocol) {
        self.filters = filters
        self.terminateFilter = terminateFilter
        super.init()
    }
    
    func next(texture: KMMetalTexture) {
        
        for filter in self.filters {
            filter.next(texture: texture)
        }
        self.outputKMTexture = self.terminateFilter.outputKMTexture
        
    }
    
    func add(input: KMMetalInput) {
        self.lock.wait()
        self.terminateFilter.add(input: input)
        self.lock.signal()
    }
    
    func delete(input: KMMetalInput) {
        self.lock.wait()
        self.terminateFilter.delete(input: input)
        self.lock.signal()
        input.onBeDeleted()
    }
    
}
