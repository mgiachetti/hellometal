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
    packed_float2 textcoord;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float2 textcoord;
};

vertex VertexOut basic_vertex(
    const device VertexIn *vertex_array [[ buffer(0) ]],
    constant Constants &uniforms [[buffer(1)]],
    unsigned int vid [[ vertex_id ]]) {
    
    VertexIn vertexIn = vertex_array[vid];
    VertexOut vertexOut;
    vertexOut.position = uniforms.modelViewProjectionMatrix * float4(vertexIn.position, 1.0);
    vertexOut.color = vertexIn.color;
    vertexOut.textcoord = vertexIn.textcoord;
    
    return vertexOut;
}

fragment half4 color_fragment(VertexOut interpolated [[stage_in]]) {
    return half4(interpolated.color);
}

fragment half4 texture_fragment(VertexOut interpolated [[stage_in]],
                                texture2d<half>  diffuseTexture [[ texture(0) ]]
                                ) {
//    constexpr sampler defaultSampler;
    constexpr sampler defaultSampler(coord::normalized,
      address::repeat,
      filter::linear);
    
    half4 color = diffuseTexture.sample(defaultSampler, float2(interpolated.textcoord));
    
//    if (color.a < 0.1)
//        discard_fragment();
    
    return color;
}
