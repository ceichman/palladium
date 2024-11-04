//
//  Shaders.metal
//  Palladium
//
//  Created by Eichman, Charlotte on 10/29/24.
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

struct ProjectionParams {
    float aspectRatio;
    float fovRadians;
    float nearZ;
    float farZ;
};

struct FragmentParams {
    float4 color;
};

struct Vertex {
    simd_float3 position;
    simd_float4 color;
    simd_float4 normal;
};

struct ProjectedVertex {
    simd_float4 position [[position]];
    simd_float4 color;
    simd_float4 normal;
};

// ---- MATRIX UTILS ----

static inline simd_float4x4 projection_matrix(float aspectRatio, float fovRadians, float nearZ, float farZ) {
    float y = 1.0 / tan(fovRadians * 0.5);
    float x = y * aspectRatio;
    float z = farZ / (farZ - nearZ);
    
    float4 X = { x, 0, 0,           0};
    float4 Y = { 0, y, 0,           0};
    float4 Z = { 0, 0, z,           1};
    float4 W = { 0, 0, z * -nearZ,  0};
    
    return simd_float4x4 {{X, Y, Z, W}};
}

matrix_float4x4 translation_matrix(vector_float3 t)
{
    vector_float4 X = { 1, 0, 0, 0 };
    vector_float4 Y = { 0, 1, 0, 0 };
    vector_float4 Z = { 0, 0, 1, 0 };
    vector_float4 W = { t.x, t.y, t.z, 1 };

    matrix_float4x4 mat = { X, Y, Z, W };
    return mat;
}

matrix_float4x4 rotation_matrix(vector_float3 axis, float theta)
{
    float c = cos(theta);
    float s = sin(theta);
    
    vector_float4 X;
        X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c;
        X.y = axis.x * axis.y * (1 - c) - axis.z * s;
        X.z = axis.x * axis.z * (1 - c) + axis.y * s;
        X.w = 0.0;
        
        vector_float4 Y;
        Y.x = axis.x * axis.y * (1 - c) + axis.z * s;
        Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c;
        Y.z = axis.y * axis.z * (1 - c) - axis.x * s;
        Y.w = 0.0;
        
        vector_float4 Z;
        Z.x = axis.x * axis.z * (1 - c) - axis.y * s;
        Z.y = axis.y * axis.z * (1 - c) + axis.x * s;
        Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c;
        Z.w = 0.0;
        
        vector_float4 W;
        W.x = 0.0;
        W.y = 0.0;
        W.z = 0.0;
        W.w = 1.0;
        
        matrix_float4x4 mat = { X, Y, Z, W };
        return mat;
}

// ---- END MATRIX UTILS ----

vertex ProjectedVertex project_vertex(
                             const device Vertex* vertex_array [[ buffer(0) ]],
                             constant ProjectionParams &params [[ buffer(1) ]],
                             unsigned int vid [[ vertex_id ]])
{
    Vertex inVertex = vertex_array[vid];
    float4x4 projMatrix = projection_matrix(params.aspectRatio, params.fovRadians, params.nearZ, params.farZ);
    float4 projected = projMatrix * float4(inVertex.position.xyz, 1.0);
    // then normalize in z
    float4 normalized = projected;
    if (projected.w != 0.0) {
        normalized.x /= projected.w;
        normalized.y /= projected.w;
        normalized.z /= projected.w;
    }
    return { .position =  normalized, .color =  inVertex.color, .normal =  inVertex.normal };
}


fragment half4 basic_fragment(constant FragmentParams &params [[buffer(0)]]) {
    
    return half4(1, 1, 1, 1);
    // return half4(params.color);  // make all fragments white for now
}
                        
                           
                           


