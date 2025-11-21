//
//  Flicker.metal
//  iOSCommonLibraries
//  nRF-Connect
//
//  Created by Dinesh Harjani on 12/3/25.
//  Created by Dinesh Harjani on 16/12/24.
//  Copyright © 2024 Nordic Semiconductor. All rights reserved.
//

#if __METAL_VERSION__ >= 240
#include <metal_stdlib>
using namespace metal;

// MARK: - flicker

// Source: https://www.reddit.com/r/godot/comments/mslgpu/flickering_neon_shader_for_a_comrade_better_with/?rdt=40964
[[ stitchable ]] half4 flicker(float2 position, half4 color, float2 size, float time) {
    half brightness = 1.0;
    half brightnessDropPercent = 0.35;
    half glowPeriod = 1.202;
    half flickerPeriod = 30.391;
    half flickerSpikes = 30.81;
    
    half4 c = color;
    half flicker = sin(time * (flickerPeriod + sin(time) * flickerPeriod * 0.3));
    half graph = (sin(time * glowPeriod) * flickerSpikes - (flickerSpikes - 1.0));
    graph = half(graph > 0.0);
    
    half lowerEdge = 0.9;
    half upperEdge = 0.95;
    half cycle = smoothstep(lowerEdge, upperEdge, graph * flicker);
    
    c.rgb *= brightness - brightnessDropPercent * cycle;
    return c;
}
#endif
