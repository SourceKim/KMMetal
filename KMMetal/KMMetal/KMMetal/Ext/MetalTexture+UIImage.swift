////  MetalTexture+UIImage.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/17.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

extension UIImage {
    
    func toTexture(device: MTLDevice, specificSize: CGSize? = nil) -> MTLTexture? {
        let bytesPerPixel = 4
        let bitsPerComponent = 8

        let width = Int(specificSize?.width ?? self.size.width)
        let height = Int(specificSize?.height ?? self.size.height)
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
        
        guard let cgImage = self.cgImage else {
            return nil
        }

        context.clear(bounds)
//        context.translateBy(x: CGFloat(width), y: CGFloat(height))
//        context.scaleBy(x: -1.0, y: -1.0)
        if let sSize = specificSize {
            // use the longer side
            let wRatio = sSize.width / self.size.width
            let hRatio = sSize.height / self.size.height
            let ratio = max(wRatio, hRatio)
            let newW = self.size.width * ratio
            let newH = self.size.height * ratio
            let offsetX = (sSize.width - newW) / 2
            let offsetY = (sSize.height - newH) / 2
            let newF = CGRect(x: offsetX, y: offsetY, width: newW, height: newH)
            context.draw(cgImage, in: newF)
        } else {
            context.draw(cgImage, in: bounds)
        }

        let texDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)

        let texture = device.makeTexture(descriptor: texDescriptor)
//        texture?.label = UIImage.imageNamed

        guard let pixelsData = context.data else { return nil }

        let region = MTLRegionMake2D(0, 0, width, height)
        texture?.replace(region: region, mipmapLevel: 0, withBytes: pixelsData, bytesPerRow: rowBytes)

        return texture
    }
}
