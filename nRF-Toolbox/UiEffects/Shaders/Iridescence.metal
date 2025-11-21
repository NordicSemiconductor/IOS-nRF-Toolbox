//
//  Iridescence.metal
//  iOSCommonLibraries
//
//  Created by Dinesh Harjani on 12/3/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

#if __METAL_VERSION__ >= 240
#include <metal_stdlib>
using namespace metal;

// MARK: - rot (Rate of Turn)

float2x2 rateOfTurn(float radians) {
    return float2x2(cos(radians), sin(radians),
                    -sin(radians), cos(radians));
}

// MARK: - iridescent

// Source: https://www.shadertoy.com/view/MlcGWr
[[ stitchable ]] half4 iridescence(float2 position, half4 color, float2 size, float time) {
    half t = time / 3. + 5.; // slow down time
    position *= log(t) / size.y; // scaling (slow zoom out)
    position.x += t; // translation
    position *= rateOfTurn(t / 22.); // slow rotation

    half2 halfPosition = half2(position);
    // colour transform
    color += sin(2. * sin(color * 22 + t + t) + halfPosition.yxyy - halfPosition.yyxy * .5) / 12.;

    return color;
}
#endif
