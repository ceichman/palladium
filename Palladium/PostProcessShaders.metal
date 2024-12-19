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
