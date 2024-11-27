//
//  Shaders.metal
//  Palladium
//
//  Created by Eichman, Charlotte on 10/29/24.
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

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

vertex ProjectedVertex project_vertex(
                             const device Vertex* vertex_array [[ buffer(0) ]],
                             constant ViewProjection &viewProj [[ buffer(1) ]],
                             constant ModelTransformation &model [[ buffer(2) ]],
                             unsigned int vid [[ vertex_id ]])
{
    Vertex inVertex = vertex_array[vid];
    float4 vert = float4(inVertex.position.xyz, 1.0);
    
    float4x4 modelMatrix = model.translation * model.scaling * model.rotation;
    float4 projectedPosition = viewProj.projection * viewProj.view * modelMatrix * vert;
    float4 projectedNormal = viewProj.projection * model.rotation * float4(inVertex.normal, 1.0);
    return { .position = projectedPosition, .color = inVertex.color, .normal = projectedNormal.xyz };
}


fragment half4 basic_fragment(ProjectedVertex vert [[stage_in]]) {
    
    simd_float3 lightDirection = normalize(simd_float3(1, 0, 0));
    float d = dot(vert.normal, lightDirection);
    return half4(vert.color * d);
}
                        
                           
                           


