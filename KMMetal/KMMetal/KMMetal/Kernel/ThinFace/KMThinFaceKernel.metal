//
//  KMThinFaceKernel.metal
//  KMMetal
//
//  Created by 苏金劲 on 2019/12/23.
//  Copyright © 2019 苏金劲. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

kernel void thinFaceKernel(texture2d<float, access::write> outputTexture [[ texture(0) ]],
                           texture2d<float, access::read> inputTexture [[ texture(1) ]],
                           constant float2 *startPos [[buffer(0)]],
                           constant float2 *endPos [[buffer(1)]],
                           constant float *r [[buffer(2)]],
                           constant float *mc2 [[buffer(3)]],
                           constant float *intensity [[buffer(4)]],
                           uint2 position [[ thread_position_in_grid ]]) {
    
    float4 color = inputTexture.read(position);
    float2 sp = *startPos;
    float2 ep = *endPos;
//    if (distance(sp, float2(position.x, position.y)) < *r || distance(ep, float2(position.x, position.y)) < *r) {
//        color = float4(0);
//    }
    if (!(abs(position.x - sp.x) > *r) || !(abs(position.y - sp.y) > *r)) { // 优化： 直接判断是否在 startX & startY 矩阵中
//    if (1) {

        // r 平方
        float r2 = pow(*r, 2);

        // 当前点与起始点的距离 的 平方
        float dis2 = pow(float(position.x - sp.x), 2) + pow(float(position.y - sp.y), 2);

        if (dis2 < r2) { // 在半径之内的话，就做变化

            // 1. 计算等号右边平方的部分
            float ratio = pow((dis2 - r2) / (dis2 - r2 + *mc2), 2);

            // 2. 映射到原位置
            float2 newPos = float2(position) - ratio * float2(ep - sp) * *intensity;

            // 3. 双线性插值
            uint2 p1 = uint2(floor(newPos.x), floor(newPos.y));
            uint2 p2 = uint2(ceil(newPos.x), floor(newPos.y));
            uint2 p3 = uint2(floor(newPos.x), ceil(newPos.y));
            uint2 p4 = uint2(ceil(newPos.x), ceil(newPos.y));

            float4 color1 = inputTexture.read(p1);
            float4 color2 = inputTexture.read(p2);
            float4 color3 = inputTexture.read(p3);
            float4 color4 = inputTexture.read(p4);

            float u = newPos.x - floor(newPos.x);
            float v = newPos.y - floor(newPos.y);

            float4 newColor = (1-u) * (1-v) * color1 + (1-u) * v * color3 + u * (1-v) * color2 + u * v * color4;

            // 4. 将新的颜色写入
            color = newColor;
//            color = float4(float3(0), 1);
//            inputTexture.write(newColor, position);
        }

    }
    
    outputTexture.write(color, position);
}
