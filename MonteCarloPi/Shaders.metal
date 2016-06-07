//
//  Shaders.metal
//  MonteCarloPi
//
//  Created by Naohiro Hamada on 2016/05/25.
//  Copyright © 2016年 HaNoHito. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void monteCarloPi(const device float2 *inVector [[ buffer(0) ]],
                         device bool *outVector [[ buffer(1) ]],
                         uint id [[ thread_position_in_grid ]])
{
    float2 loc = inVector[id];
    outVector[id] = (length_squared(loc) < 1.0) ? true  : false;
}
