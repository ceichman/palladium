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
}

constant int num_offsets = 8;

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
    // Check to make sure that the specified thread_position_in_grid value is
    // within the bounds of the framebuffer. This ensures that non-uniform size
    // threadgroups don't trigger an error. For more information, see:
    // https://developer.apple.com/documentation/metal/calculating_threadgroup_and_grid_sizes
    
    
    uint maxWidth = inColor.get_width();
    uint maxHeight = inColor.get_height();

    if (!check_bounds(gid, maxWidth, maxHeight)) return;
    
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
