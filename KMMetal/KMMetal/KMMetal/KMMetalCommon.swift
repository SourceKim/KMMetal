////  KMMetalCommon.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/17.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit
import simd
import AVFoundation

protocol KMMetalTexture {
    var texture: MTLTexture { get set }
    var cameraPosition: AVCaptureDevice.Position? { get }
}
protocol KMMetalInput {
    func next(texture: KMMetalTexture)
    func onBeAdded()
    func onProcessEnd()
}

protocol KMMetalOutput {
    @discardableResult func add(input: KMMetalInput) -> Self
}

protocol KMMetalOneParameterFilter {
    var maxValue: Float { get set }
    var minValue: Float { get set }
    var defaultValue: Float { get set }
}

struct valueStruct: KMMetalOneParameterFilter {
    var maxValue: Float
    
    var minValue: Float
    
    var defaultValue: Float
}

enum KMTextureRotation {
    case Rotate0Degrees
    case Rotate90Degrees
    case Rotate180Degrees
    case Rotate270Degrees
}

enum KMTextureContentMode {
    case AspectRatioFill
    case AspectRatioFit
    case Fill
}
