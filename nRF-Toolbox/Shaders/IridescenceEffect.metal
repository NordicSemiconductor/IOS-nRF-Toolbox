//
//  IridescenceEffect.metal
//  nRF-Toolbox
//
//  Created by Dinesh Harjani on 11/3/25.
//  Copyright © 2025 Nordic Semiconductor. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - iridescent

void perlinNoise(float2 position, thread half4 color, thread float s) {
//    vec2 m = fract(p), l = dot(p-m,A.yz) + A.xz,   \
//                     r = mix( fract(57.*sin(l++)) , fract(57.*sin(l)), (m*=m*(3.-m-m)).x ); \
//                k += mix(r.x,r.y,m.y)/(s+=s);                  \
//                p *= mat2(1,1,1,-1);                           \
//              }
    
    //    vec2 m = fract(p)
    float2 m = fract(position);
    float3 A = (0., 1., 157.);
//    l = dot(p-m,A.yz) + A.xz
    float2 l = dot(position - m, A.yz) + A.xz;
//    r = mix( fract(57.*sin(l++))
    // r=mix(fract(57.*sin(l++)),fract(57.*sin(l)),(m*=m*(3.-m-m)).x)
    float2 r = mix( fract(57. * sin(l++)), fract(57.*sin(l)), (m*=m*(3.-m-m)).x);
    
    color += mix(r.x, r.y, m.y) / (s += s);
}

// Source: https://www.shadertoy.com/view/MlcGWr
[[ stitchable ]] half4 iridescence(float2 position, half4 color, float2 size, float time) {
    float4 c = float4(color);
    
    //    float T = iTime/3.+5., s = 1.;
    half T = time / 3. + 5.;
    float s = 1.;
//    
//    //    p *= log(T)/iResolution.y;                          // scaling (slow zoom out)
    position *= log(T) / size.y;
//    //    p.x += T;                                          // translation
    position.x += T;
//    //    p *=  mat2(cos(T/22.+vec4(0,33,11,0)));           // slow field rotation
    position *= float2x2(cos(T / 22), cos(T / 22. + 33.),
                         cos(T / 22. + 11.), cos(T / 22.));
//    //    vec3 A = vec3(0,1,157);
//    float3 A = (0., 1., 157.);
    //    k -= k;
//    c -= c;
    // unrolled perlin noise see https://www.shadertoy.com/view/lt3GWn
    perlinNoise(position, color, s);
    perlinNoise(position, color, s);
    perlinNoise(position, color, s);
    perlinNoise(position, color, s);
//    
////    k += sin(2.*sin(k*22.+T+T)+p.yxyy-p.yyxy*.5)/12.; // colour transform
    c += sin(2. * sin(c * 22 + T + T) + position.yxyy - position.yyxy * .5) / 12.;

    return half4(c);
}
