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

kernel void convolve_kernel(uint2 gid [[thread_position_in_grid]],
                       texture2d<half, access::read> inColor [[texture(0)]],
                       texture2d<half, access::write> outColor [[texture(1)]],
                       texture2d<float, access::read> kern [[ texture(2) ]])
{
    // Kernel is full of float weights
    int width = kern.get_width();
    int height = kern.get_height();
    float weightAccumulator = 0.0;
    half4 colorAccumulator = half4(0, 0, 0, 0);
    for (int row = 0; row < height; ++row) {
        for (int col = 0; col < width; ++col) {
            uint2 pixelOffset = uint2(row - height / 2, col - width / 2);
            uint2 pixelCoord = gid + pixelOffset;
            // if (!check_bounds(pixelCoord, inColor.get_width(), inColor.get_height())) continue;
            uint2 kernelCoord = uint2(row, col);
            float4 weight = kern.read(kernelCoord).rrrr;
            weightAccumulator += weight.r;
            colorAccumulator += inColor.read(pixelCoord) * weight.r;
        }
    }
    outColor.write(half4(colorAccumulator.rgb / weightAccumulator, 1.0), gid);
}
