//
//  SDFShaders.metal
//  Palladium
//
//  Created by Charlotte Eichman on 4/10/26.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "ShaderTypes.h"

using namespace metal;

// Via Inigo Quilez:
// https://iquilezles.org/articles/distgradfunctions3d/
// TODO: Pull the SDF query functions out into a separate file.
// Returns a packed vec4 encoding distance sample and local-space normal at p.
float4 sdgBox(float3 p, float3 b, float r )
{
    float3 w = abs(p) - (b - r);
    float g = max(w.x, max(w.y, w.z));
    float3  q = max(w, 0.0);
    float l = length(q);
    float4  f = (g > 0.0) ? float4(l, q / l) :
        float4(g, w.x == g ? 1.0 : 0.0,
                  w.y == g ? 1.0 : 0.0,
                  w.z == g ? 1.0 : 0.0);
    return float4(f.x - r, f.yzw * sign(p));
}

// TODO: Returns a packed vec4 encoding distance sample and local-space normal at p.
// .x: distance to object
// .yzw: local-space normal at point p
float4 sample(float4 p, SDF sdf)
{
    matrix_float4x4 worldToLocalMatrix = sdf.worldToLocal.translation * sdf.worldToLocal.rotation * sdf.worldToLocal.scaling;
    float4 local = worldToLocalMatrix * p;
    float4 sample = float4(1, 1, 1, 1);
    switch (sdf.type)
    {
        case Box:
            sample = sdgBox(local.xyz, float3(1, 2, 3), 0.2);
            break;
        case Plane:
            sample = sdgBox(local.xyz, float3(1, 2, 3), 0.2);
            break;
    }
    return sample;
}

// Essentially performs an intersection with all the scene geometry.
// TODO: Returns a cast_result including distance to closest object, world-space normal, and object index.
float map(float4 p, constant SDF *sdfArray, int numSDFs)
{
    float distance = MAXFLOAT;
    for (int i = 0; i < numSDFs; i++)
    {
        SDF sdf = sdfArray[i];
        float4 s = sample(p, sdf);
        distance = min(s.x, distance);
    }
    return distance;
}

kernel void drawSDFs(uint2 gid [[ thread_position_in_grid ]],
                     constant SDFPassParams &params [[ buffer(0) ]],
                     constant SDF *sdfArray [[ buffer(1) ]],
                     texture2d<half, access::read_write> outColor [[ texture(0) ]])
{
    // deproject through the view plane
    float4 deviceCoords = float4(  // remap to NDC
        ((float) gid.x / outColor.get_width() - 0.5) * 2.0,
        ((float) gid.y / outColor.get_height() - 0.5) * 2.0, 1, 1);
    float4 deprojected = params.inverseViewProjection * deviceCoords;
    float3 marchDirection = normalize(deprojected.xyz);
    
    int maxIters = 120;
    float t = 0.; // total distance traveled by ray
    int i;
    half4 color = outColor.read(gid);
    
    for (i = 0; i < maxIters; ++i)
    {
        // current marched position
        float4 p = float4(params.cameraPosition + t * marchDirection, 1.0);
        
        float res = map(p, sdfArray, params.numSDFs);

        // adaptive precision: scale hit distance based on ray length t
        if (res < 0.001 * t)
        {
            color = half4(1, 0, 1, 1);
            break;
        }

        // march forward based on distance to closest object
        t += res;
        if (t > 50.)
        {
            // didn't hit anything
            return;
        }
        
    }
    
    outColor.write(color, gid);
    
}
