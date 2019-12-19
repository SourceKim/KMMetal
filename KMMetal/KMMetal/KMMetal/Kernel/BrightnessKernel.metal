////  BrightnessKernel.metal
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/19.
//  Copyright © 2019 苏金劲. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void brightnessKernel(texture2d<half, access::read_write> texture [[texture(0)]],
                             uint2 gid [[thread_position_in_grid]]) {
    
    if ((gid.x >= texture.get_width()) || (gid.y >= texture.get_height())) { return; }
    
    const half4 inColor = texture.read(gid);
    const half4 outColor(inColor.rgb + half3(0.4), inColor.a);
    texture.write(outColor, gid);
}
