//
//  Shader.metal
//  PhotonMetal
//
//  Created by realxie on 2019/1/4.
//  Copyright © 2019 realxie. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 vertex_shader(
                           const device packed_float3* vertex_array [[ buffer(0) ]],
                           unsigned int vid [[ vertex_id ]])
{
    return float4(vertex_array[vid], 1.0);
}

fragment half4 fragment_shader()
{
    return half4(1.0);
}


