////  CGAffineTransform+Matrix.swift
//  KMFaceDetector
//
//  Created by Su Jinjin on 2019/12/23.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

extension CGAffineTransform {
    static func transformMatrix(fromSize: CGSize, toSize: CGSize) -> Self {
        let toW = toSize.width
        let toH = toSize.height
        let fromW = fromSize.width
        let fromH = fromSize.height
        
        let toRatio = toW / toH
        let fromRatio = fromW / fromH
        let scale = toRatio > fromRatio ? toH / fromH : toW / fromW
        
        let xValue = (toW - fromW * scale) / 2.0
        let yValue = (toH - fromH * scale) / 2.0
        return Self.identity.translatedBy(x: xValue, y: yValue).scaledBy(x: scale, y: scale)
    }

    static func cropMaxtrix(fromSize: CGSize, toSize: CGSize) -> Self {
        let toW = toSize.width
        let toH = toSize.height
        let fromW = fromSize.width
        let fromH = fromSize.height
        
        let wRatio = toW / fromW
        let hRatio = toH / fromH
        let scale = max(wRatio, hRatio)
        
        let xValue = (toW - fromW * scale) / 2.0
        let yValue = (toH - fromH * scale) / 2.0
        return Self.identity.translatedBy(x: xValue, y: yValue).scaledBy(x: scale, y: scale)
    }

}

