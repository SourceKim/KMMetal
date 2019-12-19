////  KMBrightnessFilter.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/19.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

class KMBrightnessFilter: KMMetalFilter {

    init() {
        super.init(kernelName: "brightnessKernel")!
    }
}
