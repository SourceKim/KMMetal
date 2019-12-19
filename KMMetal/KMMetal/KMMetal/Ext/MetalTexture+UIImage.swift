////  MetalTexture+UIImage.swift
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/17.
//  Copyright © 2019 苏金劲. All rights reserved.
//

import UIKit

extension UIImage {

    func toTexture(device: MTLDevice, specificSize: CGSize? = nil) -> MTLTexture? {

        guard let cgImage = self.cgImage else {
            return nil
        }

        return cgImage.toTexture(device: device, specificSize: specificSize)
    }
}
