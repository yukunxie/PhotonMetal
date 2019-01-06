//
//  cube.metal
//  PhotonMetal
//
//  Created by realxie on 2019/1/6.
//  Copyright © 2019 realxie. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

typedef struct {
    float4 position[[position]];
    float3 color;
} VertexOut;

typedef struct{
    packed_float3 position;
    packed_float3 color;
} VertexData;

typedef struct {
    float4x4 pMatrix[[id(0)]];
    float4x4 mvMatrix[[id(1)]];
} UniformBuffer;

vertex VertexOut cube_vertex_shader(
                               const device VertexData* vertex_array [[ buffer(0) ]],
                               constant UniformBuffer& uniformBuffer[[ buffer(1) ]],
                               unsigned int vid [[ vertex_id ]])
{
    VertexOut out;
    out.position =  float4(vertex_array[vid].position, 1.0);
    out.position = uniformBuffer.pMatrix * uniformBuffer.mvMatrix * out.position;
    out.color = vertex_array[vid].color;
    return out;
}

fragment half4 cube_fragment_shader(VertexOut in[[stage_in]])
{
    return half4(in.color.x, in.color.y, in.color.z, 1.0);
}
