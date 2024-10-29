//
//  Shaders.metal
//  Palladium
//
//  Created by Eichman, Charlotte on 10/29/24.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 basic_vertex(
                           const device packed_float3* vertex_array [[ buffer(0) ]], // indicate attributes, i.e. that first buffer of data sent to basic_vertex will populate vertex_array
                           unsigned int vid [[ vertex_id ]])
{
    // gotta convert vertices to float4s so that 3d transformations can be applied
    return float4(vertex_array[vid], 1.0);
}

struct FragmentParams {
    float4 color;
};

fragment half4 basic_fragment(constant FragmentParams &params [[buffer(0)]]) {
    return half4(params.color);  // make all fragments white for now
}
                        
                           
                           
                           


