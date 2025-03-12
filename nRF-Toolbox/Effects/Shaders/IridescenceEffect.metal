//
//  IridescenceEffect.metal
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 11/3/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

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
    float4 c = float4(color);
    
    half t = time / 3. + 5.;
    // scaling (slow zoom out)
    position *= log(t) / size.y;
    // translation
    position.x += t;
    position *= rateOfTurn(t / 22.);

    // colour transform
    c += sin(2. * sin(c * 22 + t + t) + position.yxyy - position.yyxy * .5) / 12.;

    return half4(c);
}
