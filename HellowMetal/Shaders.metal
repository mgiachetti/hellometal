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

fragment half4 color_fragment(VertexOut vertexIn [[stage_in]]) {
    float4 color = vertexIn.color;
    return half4(color.r, color.g, color.b, color.a);
}

fragment half4 texture_fragment(VertexOut vertexIn [[stage_in]],
                                texture2d<half>  diffuseTexture [[ texture(0) ]]
                                ) {
//    constexpr sampler defaultSampler;
    constexpr sampler defaultSampler(coord::normalized,
      address::repeat,
      filter::linear);
    
    half4 color = diffuseTexture.sample(defaultSampler, float2(vertexIn.textcoord));
    
//    if (color.a < 0.1)
//        discard_fragment();
    
    return color;
//    return half4(color.rgb, 0.5);
}
