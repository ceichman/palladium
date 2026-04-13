//
//  ShaderTypes.h
//  Palladium
//
//  Created by Eichman, Charlotte on 12/4/24.
//

#import <simd/simd.h>

#ifndef ShaderTypes_h
#define ShaderTypes_h

struct ViewProjection {
    simd_float4x4 view;
    simd_float4x4 projection;
};

struct ModelTransform {
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
    simd_float4 prevPosition;
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
    simd_uint2 viewDimensions;
    float specularCoefficient;
    float bloomThreshold;
    int numDirectionalLights;
    int numPointLights;
};

struct FragmentOut {
    simd_float4 sceneColor [[ color(0) ]];
    simd_float4 bloomMask  [[ color(1) ]];
    simd_float2 screenSpaceVelocity [[ color(2) ]];
};

struct SkyboxParams {
    simd_float4x4 inverseViewProjection;
};

enum SDFType {
    Plane = 0,
    Box = 1
};

struct SDF {
    struct ModelTransform worldToLocal;  // for transforming a point from world space into SDF-local space
    enum SDFType type;
};

struct SDFPassParams {
    simd_float4x4 inverseViewProjection;
    simd_float3 cameraPosition;
    int numSDFs;
};

#endif /* ShaderTypes_h */
