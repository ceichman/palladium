//
//  Shaders.metal
//  Palladium
//
//  Created by Eichman, Charlotte on 10/29/24.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "ShaderTypes.h"

using namespace metal;

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
    float4 worldPosition = modelMatrix * vert;
    float4 projectedNormal = viewProj.projection * model.rotation * float4(inVertex.normal, 1.0);
    return {
        .position = projectedPosition,
        .worldPosition = worldPosition,
        .color = inVertex.color,
        .normal = projectedNormal.xyz,
        .uvs = inVertex.uvs
    };
    
}


constexpr sampler textureSampler (mag_filter::linear,
                                  min_filter::linear);

fragment half4 basic_fragment(ProjectedVertex vert [[stage_in]],
                              texture2d<half> colorTexture [[ texture(0)]],
                              constant FragmentParams &params [[ buffer(0) ]],
                              constant DirectionalLight *directionalLights [[ buffer(1) ]],
                              constant PointLight *pointLights [[ buffer(2) ]] )
{
    half4 diffuseColor;
    if (is_null_texture(colorTexture)) {
        diffuseColor = half4(vert.color);
    }
    else {
        simd_float2 newUv = simd_float2(vert.uvs.x, 1.0 - vert.uvs.y);
        diffuseColor = colorTexture.sample(textureSampler, newUv);
    }
    
    float pointLightContribution = 0.0;
    for (int i = 0; i < params.numPointLights; ++i) {
        float3 vertexToLight = pointLights[i].position - vert.worldPosition.xyz;
    }
    simd_float3 lightDirection = normalize(simd_float3(1, 0, 0));
    float d = dot(vert.normal, lightDirection);
    return half4(diffuseColor * (d + 0.2));
}
                        
                           
                           


