//
//  Shaders.metal
//  HellowMetal
//
//  Created by Martin Giachetti on 5/25/17.
//  Copyright © 2017 Tactivos. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Constants {
    float4x4 modelViewProjectionMatrix;
};

struct VertexIn {
    packed_float3 position;
    packed_float4 color;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut basic_vertex(
    const device VertexIn *vertex_array [[ buffer(0) ]],
    constant Constants &uniforms [[buffer(1)]],
    unsigned int vid [[ vertex_id ]]) {
    
    VertexIn VertexIn = vertex_array[vid];
    VertexOut VertexOut;
    VertexOut.position = uniforms.modelViewProjectionMatrix * float4(VertexIn.position, 1.0);
//    VertexOut.position = float4(VertexIn.position, 1.0);
    VertexOut.color = VertexIn.color;
    
    return VertexOut;
}

fragment half4 basic_fragment(VertexOut interpolated [[stage_in]]) {
    return half4(interpolated.color);
}
