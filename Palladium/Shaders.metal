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

struct ViewProjection {
    simd_float4x4 view;
    simd_float4x4 projection;
};

struct ModelTransformation {
    simd_float4x4 translation;
    simd_float4x4 rotation;
    simd_float4x4 scaling;
};

struct Vertex {
    simd_float3 position;
    simd_float4 color;
    simd_float3 normal;
};

struct ProjectedVertex {
    simd_float4 position [[position]];
    simd_float4 color;
    simd_float3 normal;
};


// TODO: put all of MATRIX UTILS in a different file (so that the work is done on the CPU, not the GPU)
// ---- MATRIX UTILS ----

// TODO: make sure this is correct
static inline float magnitude(simd_float3 vec) {
    return sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z);
}

// TODO: eyebal
static inline simd_float4x4 projection_matrix(float aspectRatio, float fovRadians, float nearZ, float farZ) {
    float y = 1.0 / tan(fovRadians * 0.5);  // y-scale based on FOV
    float x = y * aspectRatio;              // x-scale which abides by aspect ratio
    float z = farZ / (farZ - nearZ);        // z-scale for perspective divide
    
    float4 X = { x, 0, 0,           0};
    float4 Y = { 0, y, 0,           0};
    float4 Z = { 0, 0, z,           1};
    float4 W = { 0, 0, z * -nearZ,  0};
    
    return simd_float4x4 {{X, Y, Z, W}};
}

// TODO: eyebal
matrix_float4x4 translation_matrix(vector_float3 t)
{
    vector_float4 X = { 1, 0, 0, 0 };
    vector_float4 Y = { 0, 1, 0, 0 };
    vector_float4 Z = { 0, 0, 1, 0 };
    vector_float4 W = { t.x, t.y, t.z, 1 };

    matrix_float4x4 mat = { X, Y, Z, W };
    return mat;
}

// TODO: eyebal
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

simd_float4x4 scaling_matrix(simd_float3 scale) {
    
    vector_float4 X = { scale.x, 0, 0, 0 };
    vector_float4 Y = { 0, scale.y, 0, 0 };
    vector_float4 Z = { 0, 0, scale.z, 0 };
    vector_float4 W = { 0, 0, 0, 1 };

    matrix_float4x4 mat = { X, Y, Z, W };
    return mat;
}

constant vector_float3 EAST = vector_float3(1, 0, 0);   // x
constant vector_float3 UP = vector_float3(0, 1, 0);     // y
constant vector_float3 NORTH = vector_float3(0, 0, 1);  // z

// ---- END MATRIX UTILS ----

vertex ProjectedVertex project_vertex(
                             const device Vertex* vertex_array [[ buffer(0) ]],
                             constant ViewProjection &viewProj [[ buffer(1) ]],
                             constant ModelTransformation &model [[ buffer(2) ]],
                             unsigned int vid [[ vertex_id ]])
{
    Vertex inVertex = vertex_array[vid];
    float4 vert = float4(inVertex.position.xyz, 1.0);
    
    float4x4 modelMatrix = model.translation * model.rotation * model.scaling;
    float4 projectedPosition = viewProj.projection * viewProj.view * modelMatrix * vert;
    float4 projectedNormal = viewProj.projection * model.translation * model.rotation * float4(inVertex.normal, 1.0);
    // then normalize in z
    float4 normalizedNormal = projectedNormal;
    if (projectedNormal.w != 0.0) {
        normalizedNormal.x /= projectedNormal.w;
        normalizedNormal.y /= projectedNormal.w;
        normalizedNormal.z /= projectedNormal.w;
    }
    float4 normalizedPosition = projectedPosition;
    if (projectedPosition.w != 0.0) {
        normalizedPosition.x /= projectedPosition.w;
        normalizedPosition.y /= projectedPosition.w;
        normalizedPosition.z /= projectedPosition.w;
    }
    return { .position = normalizedPosition, .color = inVertex.color, .normal = projectedNormal.xyz };
}


fragment half4 basic_fragment(ProjectedVertex vert [[stage_in]]) {
    simd_float3 lightDirection = normalize(simd_float3(1, 0, 0));
    float d = dot(vert.normal, lightDirection);
    return half4(vert.color * d);
}
                        
                           
                           


