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

static inline float4x4 projection_matrix(float aspectRatio, float fovRadians, float nearZ, float farZ) {
    float y = 1.0 / tan(fovRadians * 0.5);
    float x = y * aspectRatio;
    float z = farZ / (farZ - nearZ);
    
    float4 X = { x, 0, 0,           0};
    float4 Y = { 0, y, 0,           0};
    float4 Z = { 0, 0, z,           1};
    float4 W = { 0, 0, z * -nearZ,  0};
    
    return float4x4 {{X, Y, Z, W}};
}

struct ProjectionParams {
    float aspectRatio;
    float fovRadians;
    float nearZ;
    float farZ;
};

vertex float4 project_vertex(
                             const device packed_float3* vertex_array [[ buffer(0) ]],
                             constant ProjectionParams &params [[buffer(1)]],
                             unsigned int vid [[ vertex_id ]])
{
    float3 rawvert = vertex_array[vid];
    float4x4 projMatrix = projection_matrix(params.aspectRatio, params.fovRadians, params.nearZ, params.farZ);
    float4 projected = projMatrix * float4(rawvert.x, rawvert.y, rawvert.z, 1.0);
    // then normalize in z
    float4 normalized = projected;
    if (projected.w != 0.0) {
        normalized.x /= projected.w;
        normalized.y /= projected.w;
        normalized.z /= projected.w;
    }
    
    return normalized;
}


struct FragmentParams {
    float4 color;
};

fragment half4 basic_fragment(constant FragmentParams &params [[buffer(0)]]) {
    return half4(1, 1, 1, 1);
    // return half4(params.color);  // make all fragments white for now
}
                        
                           
                           
                           


