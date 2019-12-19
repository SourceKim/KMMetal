////  MetalTexture+CGImage.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/19.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

extension CGImage {
    
    func toTexture(device: MTLDevice, specificSize: CGSize? = nil) -> MTLTexture? {
        let bytesPerPixel = 4
        let bitsPerComponent = 8

        var width = self.width
        var height = self.height
        if let ss = specificSize {
            width = Int(ss.width)
            height = Int(ss.height)
        }
        let bounds = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))

        let rowBytes = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: rowBytes,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.order32Big.rawValue) else {
            return nil
        }

        context.clear(bounds)
        if let sSize = specificSize {
            let width_cgfloat = CGFloat(self.width)
            let height_cgfloat = CGFloat(self.height)
            // use the longer side
            let wRatio = sSize.width / width_cgfloat
            let hRatio = sSize.height / height_cgfloat
            let ratio = max(wRatio, hRatio)
            let newW = width_cgfloat * ratio
            let newH = height_cgfloat * ratio
            let offsetX = (sSize.width - newW) / 2
            let offsetY = (sSize.height - newH) / 2
            let newF = CGRect(x: offsetX, y: offsetY, width: newW, height: newH)
            context.draw(self, in: newF)
        } else {
            context.draw(self, in: bounds)
        }

        let texDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)

        let texture = device.makeTexture(descriptor: texDescriptor)

        guard let pixelsData = context.data else { return nil }

        let region = MTLRegionMake2D(0, 0, width, height)
        texture?.replace(region: region, mipmapLevel: 0, withBytes: pixelsData, bytesPerRow: rowBytes)

        return texture
    }
}
