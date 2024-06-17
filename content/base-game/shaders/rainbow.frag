#pragma header
uniform float iTime; // Hue shift
uniform float sat;
uniform float val;
void main()
{
    vec2 uv = openfl_TextureCoordv;
    vec4 tex0 = flixel_texture2D(bitmap, uv);
    float H = mod(iTime+10, 3.);
    float S = 1.0+sat;       // Saturation scale 0-1
    float V = 1.0+val;                          // Value scale      0-1

// 2 or 3 components of hue_term can be calculated on the CPU if prefered to remove the min/abs/sub here
    vec3 hue_term = 1.0 - min(abs(vec3(H) - vec3(0,2.0,1.0)), 1.0);
    hue_term.x = 1.0 - dot(hue_term.yz, vec2(1));
    vec3 res = vec3(dot(tex0.xyz, hue_term.xyz), dot(tex0.xyz, hue_term.zxy), dot(tex0.xyz, hue_term.yzx));
    res = mix(vec3(dot(res, vec3(0.2, 0.5, 0.3))), res, S);
    res = res * V;
    gl_FragColor = vec4(res*tex0.a, tex0.a);
}