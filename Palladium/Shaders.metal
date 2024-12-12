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
                             constant ModelTransformation *models [[ buffer(2) ]],
                             unsigned int vid [[ vertex_id ]],
                             unsigned int iid [[ instance_id ]])
{
    Vertex inVertex = vertex_array[vid];
    float4 vert = float4(inVertex.position.xyz, 1.0);
    ModelTransformation model = models[iid];
    
    float4x4 modelMatrix = model.translation * model.scaling * model.rotation;
    float4 projectedPosition = viewProj.projection * viewProj.view * modelMatrix * vert;
    float4 worldPosition = modelMatrix * vert;
    float4 worldNormal = model.rotation * float4(inVertex.normal, 1.0);
    float4 projectedNormal = viewProj.projection * model.rotation * float4(inVertex.normal, 1.0);
    return {
        .position = projectedPosition,
        .worldPosition = worldPosition,
        .color = inVertex.color,
        .normal = projectedNormal.xyz,
        .worldNormal = worldNormal.xyz,
        .uvs = inVertex.uvs
    };
    
}


constexpr sampler textureSampler (mag_filter::linear,
                                  min_filter::linear);

fragment half4 basic_fragment(ProjectedVertex vert [[stage_in]],
                              texture2d<half> colorTexture [[ texture(0)]],
                              constant FragmentParams &params [[ buffer(0) ]],
                              constant DirectionalLight *directionalLights [[ buffer(1) ]],
                              constant PointLight *pointLights [[ buffer(2) ]])
{
    half4 flatColor;
    if (is_null_texture(colorTexture)) {
        flatColor = half4(vert.color);
    }
    else {
        simd_float2 newUv = simd_float2(vert.uvs.x, 1.0 - vert.uvs.y);
        flatColor = colorTexture.sample(textureSampler, newUv);
    }
    
    float ambient = 0.1;
    float3 color = float3(flatColor.xyz) * ambient;
    float specularCoeff = params.specularCoefficient;
    
    float3 cameraToVertex = params.cameraPosition - vert.worldPosition.xyz;
    
    // Point light contribution
    for (int i = 0; i < params.numPointLights; i++) {
        float3 vertexToLight = pointLights[i].position - vert.worldPosition.xyz;
        float distanceSquared = dot(vertexToLight, vertexToLight);
        vertexToLight = normalize(vertexToLight);
        float3 reflectedColor = pointLights[i].color * float3(flatColor.xyz);
        float attenuation = fmax((1 - (distanceSquared / pointLights[i].radius)), 0.0);
        float diffuse = max(dot(vertexToLight, vert.worldNormal), 0.0);
        color += reflectedColor * attenuation * diffuse * pointLights[i].intensity;
        
        // specular highlights contribution
        float3 halfway = normalize(normalize(vertexToLight) + normalize(cameraToVertex));
        color += powr(fmax(dot(float3(vert.worldNormal.xyz), halfway),0.0),32.0) * float3(reflectedColor) * specularCoeff * attenuation;
    }
    
    // Directional light contribution
    for (int i = 0; i < params.numDirectionalLights; i++) {
        float diffuse = max(dot(vert.worldNormal, directionalLights[i].direction), 0.0);
        float3 reflectedColor = directionalLights[i].color * float3(flatColor.xyz);
        color += reflectedColor * diffuse * directionalLights[i].intensity;
    }
    
    color = saturate(color);
    return half4(half3(color), 1.0);
}
                        
                           
                           


