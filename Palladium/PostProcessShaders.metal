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

inline bool check_bounds(uint2 gid, uint maxWidth, uint maxHeight) {
    return ((gid.x <= maxWidth) && (gid.y <= maxHeight));
};

kernel void invert_color(uint2 gid [[thread_position_in_grid]],
                       texture2d<half, access::read> inColor [[texture(0)]],
                       texture2d<half, access::write> outColor [[texture(1)]])
{
    // Invert the pixel's color by subtracting it from 1.0.
    outColor.write(1.0 - inColor.read(gid), gid);
}

kernel void motion_blur(uint2 gid [[ thread_position_in_grid ]],
                        texture2d<half, access::read> inColor [[ texture(0) ]],
                        texture2d<half, access::write> outColor [[ texture(1) ]],
                        texture2d<half, access::read> velocityTexture [[ texture(2) ]])
{
    int numSamples = 40;  // put an option for this later
    int samplesTaken = 1;
    half2 coord = half2(gid);
    half2 velocity = velocityTexture.read(gid).xy / 50;
    half4 color = inColor.read(gid);
    for (int i = 0; i < numSamples; ++i) {
        coord += velocity;
        uint2 sampleLocation = uint2(coord);
        if (check_bounds(sampleLocation, inColor.get_width(), inColor.get_height())) {
            samplesTaken += 1;
            color += inColor.read(sampleLocation);
        }
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
