//
//  Shader.metal
//  PhotonMetal
//
//  Created by realxie on 2019/1/4.
//  Copyright © 2019 realxie. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

typedef struct
{
    float4 Color [[id(0)]];
} UniformBuffer;

typedef struct{
    float4 position[[position]];
    float4 color;
} VertexOut;

vertex VertexOut vertex_shader(
                            const device packed_float3* vertex_array [[ buffer(0) ]],
                            constant UniformBuffer& uniformBuffer[[ buffer(1) ]],
                            unsigned int vid [[ vertex_id ]])
{
    VertexOut out;
    out.position = float4(vertex_array[vid], 1.0);
    out.color = uniformBuffer.Color;
    return out;
}

fragment half4 fragment_shader(VertexOut in[[stage_in]])
{
    return half4(in.color);
}


