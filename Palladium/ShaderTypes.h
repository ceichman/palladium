//
//  ShaderTypes.h
//  Palladium
//
//  Created by Eichman, Charlotte on 12/4/24.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h


#endif /* ShaderTypes_h */


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
    simd_float2 uvs;
};

struct ProjectedVertex {
    simd_float4 position [[position]];
    simd_float4 worldPosition;
    simd_float4 color;
    simd_float3 normal;
    simd_float3 worldNormal;
    simd_float2 uvs;
};

struct DirectionalLight {
    simd_float3 direction;
    simd_float3 color;
    float intensity;
};

struct PointLight {
    simd_float3 position;
    simd_float3 color;
    float intensity;
    float radius;
};

struct FragmentParams {
    simd_float3 cameraPosition;
    float specularCoefficient;
    int numDirectionalLights;
    int numPointLights;
};

struct ConvolutionKernel {
    int size;   // should be odd sqrt(sizeof(mat))
    constant float *mat;
};
