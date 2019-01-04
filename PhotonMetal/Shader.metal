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

typedef struct
{
    texture2d<half> diffuse [[id(0)]];
    sampler   texSampler[[id(1)]];
} SamplerBuffer;

typedef struct{
    float4 position[[position]];
    float4 color;
    float4 texcoord;
} VertexOut;

typedef struct{
    packed_float3 position;
    packed_float2 texcoord;
} VertexData;

vertex VertexOut vertex_shader(
                            const device VertexData* vertex_array [[ buffer(0) ]],
                            constant UniformBuffer& uniformBuffer[[ buffer(1) ]],
                            unsigned int vid [[ vertex_id ]])
{
    VertexOut out;
    out.position = float4(vertex_array[vid].position, 1.0);
    out.color = uniformBuffer.Color;
    out.texcoord = float4(vertex_array[vid].texcoord, 0.0, 1.0);
    return out;
}

fragment half4 fragment_shader(VertexOut in[[stage_in]], device SamplerBuffer &uniformBuffer[[ buffer(10) ]])
{
    half4 textureSample = uniformBuffer.diffuse.sample(uniformBuffer.texSampler, in.texcoord.xy);
    return textureSample;
}


