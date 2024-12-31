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
                             constant ViewProjection &prevViewProj [[ buffer(3) ]],
                             constant ModelTransformation *prevModels [[ buffer(4) ]],
                             unsigned int vid [[ vertex_id ]],
                             unsigned int iid [[ instance_id ]])
{
    Vertex inVertex = vertex_array[vid];
    float4 vert = float4(inVertex.position.xyz, 1.0);
    ModelTransformation model = models[iid];
    ModelTransformation prevModel = prevModels[iid];
    
    float4x4 modelMatrix = model.translation * model.scaling * model.rotation;
    float4 projectedPosition = viewProj.projection * viewProj.view * modelMatrix * vert;
    float4 worldPosition = modelMatrix * vert;
    float4 worldNormal = model.rotation * float4(inVertex.normal, 1.0);
    float4 projectedNormal = viewProj.projection * model.rotation * float4(inVertex.normal, 1.0);
    
    float4x4 prevModelMatrix = prevModel.translation * prevModel.scaling * prevModel.rotation;
    float4 prevProjectedPosition = prevViewProj.projection * prevViewProj.view * prevModelMatrix * vert;
    
    return {
        .position = projectedPosition,
        .prevPosition = prevProjectedPosition,
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
                              texture2d<half, access::write> velocityTexture [[ texture(1) ]],
                              constant FragmentParams &params [[ buffer(0) ]],
                              constant DirectionalLight *directionalLights [[ buffer(1) ]],
                              constant PointLight *pointLights [[ buffer(2) ]])
{
    
    half4 flatColor;
    // compute diffuse color using either vertex color or object color texture
    if (is_null_texture(colorTexture)) {
        flatColor = half4(vert.color);
    }
    else {
        simd_float2 newUv = simd_float2(vert.uvs.x, 1.0 - vert.uvs.y);
        flatColor = colorTexture.sample(textureSampler, newUv);
    }
    
    // populate screen-space velocity vector texture
    if (!is_null_texture(velocityTexture)) {
        uint2 viewportSize = uint2(velocityTexture.get_width(), velocityTexture.get_height());
        // first normalize prev position in w, like [[ position ]] during raster
        if (vert.prevPosition.w != 0.0) {
            vert.prevPosition.x /= vert.prevPosition.w;
            vert.prevPosition.y /= vert.prevPosition.w;
            vert.prevPosition.z /= vert.prevPosition.w;
        }
        // now prevPosition is on [-1, 1] x [-1, 1]
        float2 interpolated = (vert.prevPosition.xy + 1) / 2.0;
        // scale into view dimensions
        float2 prevNormalized = float2(interpolated.x * viewportSize.x, interpolated.y * viewportSize.y);
        // flip y axis (??)
        prevNormalized.y = velocityTexture.get_height() - prevNormalized.y;
        half4 velocity4 = half4(vert.position.x - prevNormalized.x, vert.position.y - prevNormalized.y, 0, 0);
        velocityTexture.write(velocity4, uint2(vert.position.xy));
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
        float diffuse = max(dot(vert.worldNormal, normalize(directionalLights[i].direction)), 0.0);
        float3 reflectedColor = saturate(directionalLights[i].color) * float3(flatColor.xyz);
        color += reflectedColor * diffuse * directionalLights[i].intensity;
    }
    
    color = saturate(color);
    return half4(half3(color), 1.0);
}
                        
                           
                           


