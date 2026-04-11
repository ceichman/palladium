//
//  PostProcessShaders.metal
//  Palladium
//
//  Created by Eichman, Charlotte on 11/25/24.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "ShaderTypes.h"

using namespace metal;

// default sampler
constexpr sampler textureSampler (mag_filter::linear,
                                  min_filter::linear);

kernel void invert_color(uint2 gid [[thread_position_in_grid]],
                       texture2d<half, access::read> inColor [[texture(0)]],
                       texture2d<half, access::write> outColor [[texture(1)]])
{
    // Invert the pixel's color by subtracting it from 1.0.
    outColor.write(1.0 - inColor.read(gid), gid);
}

kernel void motion_blur(uint2 gid [[ thread_position_in_grid ]],
                        texture2d<half> inColor [[ texture(0) ]],
                        texture2d<half, access::write> outColor [[ texture(1) ]],
                        texture2d<float, access::read> velocityTexture [[ texture(2) ]])
{
    float numSamples = 30.0;  // put an option for this later
    float samplesTaken = 1.0;
    float2 coord = float2(gid);
    // negate in order to walk towards previous position
    float2 velocity = -1.0 * velocityTexture.read(gid).xy / numSamples;
    half4 color = inColor.read(gid);
    for (int i = 0; i < numSamples; ++i) {
        coord += velocity;
        float2 sampleLocation = float2(coord.x / inColor.get_width(), coord.y / inColor.get_height());
        samplesTaken += 1.0;
        color += inColor.sample(textureSampler, sampleLocation);
    }
    half4 finalColor = half4(color / samplesTaken);
    outColor.write(finalColor, gid);
    
}

kernel void copy(uint2 gid [[thread_position_in_grid]],
                       texture2d<half, access::read> inColor [[texture(0)]],
                       texture2d<half, access::write> outColor [[texture(1)]])
{
    outColor.write(inColor.read(gid), gid);
}

kernel void clear(uint2 gid [[thread_position_in_grid]],
                       texture2d<half, access::read> inColor [[texture(0)]],
                       texture2d<half, access::write> outColor [[texture(1)]])
{
    outColor.write(half4(0, 0, 0, 0), gid);
}


kernel void composite_unweighted(uint2 gid [[thread_position_in_grid]],
                       texture2d<half, access::read> inColorA [[texture(0)]],
                       texture2d<half, access::read> inColorB [[texture(1)]],
                       texture2d<half, access::write> outColor [[texture(2)]])
{
    outColor.write(saturate(inColorA.read(gid) + inColorB.read(gid)), gid);
}

kernel void skybox(uint2 gid [[thread_position_in_grid]],
                   texturecube<half> skyboxTexture [[texture(0)]],
                   texture2d<half, access::write> outColor [[texture(1)]],
                   constant SkyboxParams &params [[buffer(0)]])
                
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    float4 deviceCoords = float4(  // remap to NDC
        ((float) gid.x / outColor.get_width() - 0.5) * 2.0,
        ((float) gid.y / outColor.get_height() - 0.5) * 2.0, 1, 1);
    float4 deprojected = params.inverseViewProjection * deviceCoords;
    // deprojected /= deprojected.w;
    float3 sampleCoord = normalize(deprojected.xyz);
    half4 color = skyboxTexture.sample(textureSampler, sampleCoord);
    outColor.write(saturate(color), gid);
}
