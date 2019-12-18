////  PassthroughShaders.metal
//  KMMetal
//
//  Created by Su Jinjin on 2019/12/18.
//  Copyright © 2019 苏金劲. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct RasterizerData {
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex RasterizerData vertexPassThrough(uint vertexId [[vertex_id]],
                                        constant float2 *position [[buffer(0)]],
                                        constant float2 *textureCoordinate [[buffer(1)]]) {
    
    RasterizerData out;
    out.position.xy = position[vertexId];
    out.position.z = 0;
    out.position.w = 1;
    out.textureCoordinate = textureCoordinate[vertexId];
    
    return out;
}

fragment half4 fragmentPassThrough(RasterizerData in [[stage_in]],
                                   texture2d<half> texture [[texture(0)]]) {
    
    constexpr sampler quadSampler;
    return texture.sample(quadSampler, in.textureCoordinate);
}
