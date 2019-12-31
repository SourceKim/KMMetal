////  KMCropKernel.metal
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/31.
//  Copyright © 2019 苏金劲. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void cropKernel(texture2d<half, access::write> outputTexture [[texture(0)]],
                       texture2d<half, access::read> inputTexture [[texture(1)]],
                       constant float4 *rectPointer [[buffer(0)]],
                       uint2 gid [[thread_position_in_grid]]) {
    
    if ((gid.x >= outputTexture.get_width()) || (gid.y >= outputTexture.get_height())) { return; }
    
    const float4 rect = float4(*rectPointer);
    const uint minX = inputTexture.get_width() * rect.x;
    const uint minY = inputTexture.get_height() * rect.y;
    const half4 outColor = inputTexture.read(uint2(gid.x + minX, gid.y + minY));
    outputTexture.write(outColor, gid);
}
