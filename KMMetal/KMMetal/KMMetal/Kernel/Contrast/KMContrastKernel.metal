////  KMContrastKernel.metal
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/27.
//  Copyright © 2019 苏金劲. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void contrastKernel(texture2d<half, access::write> outputTexture [[texture(0)]],
                           texture2d<half, access::read> inputTexture [[texture(1)]],
                           constant float *contrast [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]]) {
    
    if ((gid.x >= outputTexture.get_width()) || (gid.y >= outputTexture.get_height())) { return; }
    
    const half4 inColor = inputTexture.read(gid);
    const half4 outColor(((inColor.rgb - half3(0.5)) * half3(*contrast) + half3(0.5)), inColor.a);
    outputTexture.write(outColor, gid);
}
