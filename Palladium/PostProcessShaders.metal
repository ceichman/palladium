//
//  PostProcessShaders.metal
//  Palladium
//
//  Created by Eichman, Charlotte on 11/25/24.
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

inline bool check_bounds(uint2 gid, uint maxWidth, uint maxHeight) {
    return ((gid.x <= maxWidth) && (gid.y <= maxHeight));
};

static constant constexpr int num_offsets = 8;

constant uint2 offsets[] = {
    uint2(-1, -1),
    uint2(-1, 0),
    uint2(-1, 1),
    uint2(0, -1),
    uint2(0, 1),
    uint2(1, -1),
    uint2(1, 0),
    uint2(1, 1),
};

kernel void box_blur(uint2 gid [[thread_position_in_grid]],
                       texture2d<half, access::read> inColor [[texture(0)]],
                       texture2d<half, access::write> outColor [[texture(1)]])
{
    
    uint maxWidth = inColor.get_width();
    uint maxHeight = inColor.get_height();

    simd_half4 accumulator = simd_half4(0, 0, 0, 0);
    int n = 0;

    for (int i = 0; i < num_offsets; ++i) {
        uint2 newGid = offsets[i] + gid;
        if (!check_bounds(newGid, maxWidth, maxHeight)) continue;
        accumulator += inColor.read(newGid);
        n++;
    }

    // race condition... ?
    outColor.write(accumulator / n, gid);
}

inline float gaussian_weight(float dx, float dy, float sigma) {
    float coeff = 1 / (2 * M_PI_F * sigma * sigma);
    float exponent = -1 * (dx * dx + dy * dy) / (2 * sigma * sigma);
    return coeff * exp(exponent);
}

kernel void gaussian_blur(uint2 gid [[thread_position_in_grid]],
                       texture2d<half, access::read> inColor [[texture(0)]],
                       texture2d<half, access::write> outColor [[texture(1)]])
{
    uint maxWidth = inColor.get_width();
    uint maxHeight = inColor.get_height();
    
    int size = 5;
    int radius = size / 2;
 
    half4 accumColor(0, 0, 0, 0);
    float accumWeights = 0;
    for (int j = 0; j < size; ++j)
    {
        for (int i = 0; i < size; ++i)
        {
            uint2 textureIndex(gid.x + (i - radius), gid.y + (j - radius));
            if (!check_bounds(textureIndex, maxWidth, maxHeight)) continue;
            half4 color = inColor.read(textureIndex);
            float weight = gaussian_weight(float(i), float(j), radius / 2);
            accumColor += weight * color;
            accumWeights += weight;
        }
    }
 
    outColor.write(half4(accumColor.rgb / accumWeights, 1), gid);
}

kernel void invert_color(uint2 gid [[thread_position_in_grid]],
                       texture2d<half, access::read> inColor [[texture(0)]],
                       texture2d<half, access::write> outColor [[texture(1)]])
{
    // if (!check_bounds(gid, inColor.get_width(), inColor.get_height())) return;
    // Invert the pixel's color by subtracting it from 1.0.
    outColor.write(1.0 - inColor.read(gid), gid);
}
