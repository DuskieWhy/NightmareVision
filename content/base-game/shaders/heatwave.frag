#pragma header

uniform float time;
uniform float strength;
uniform float speed;

float rand(vec2 n) { return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);}
float noise(vec2 n) {
const vec2 d = vec2(0.0, 1.0);
vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

void main() {
	vec2 p_m = openfl_TextureCoordv.xy;
    vec2 p_d = p_m;

    p_d.y = 1.0-p_d.y;
    p_d.t += (time * 0.1) * speed;

    p_d = mod(p_d, 1.0);
    vec4 dst_map_val = vec4(noise(p_d * vec2(50)));
    
    vec2 dst_offset = dst_map_val.xy;
    dst_offset -= vec2(.5,.5);
    dst_offset *= 2.;
    dst_offset *= (0.01 * strength);
	
    //reduce effect towards Y top
    dst_offset *= (1. - p_m.t);
    
    vec2 dist_tex_coord = p_m.st + dst_offset;
    gl_FragColor = flixel_texture2D(bitmap, dist_tex_coord); 
}