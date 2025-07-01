#pragma header

vec2 iResolution = openfl_TextureSize;

uniform float intensity;

uniform float pixel_f;
uniform float color_f;


const mat4 ditherTable = mat4(
    -4.0, 0.0, -3.0, 1.0,
    2.0, -2.0, 3.0, -1.0,
    -3.0, 1.0, -4.0, 0.0,
    3.0, -1.0, 2.0, -2.0
);


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{                  
    // Reduce pixels   
    float PIXEL_FACTOR = pixel_f * (intensity);
    float COLOR_FACTOR = color_f * (intensity);
    vec2 size = PIXEL_FACTOR * iResolution.xy/iResolution.x;
    vec2 coor = floor( fragCoord/iResolution.xy * size) ;
    vec2 uv = coor / size;   
                
   	// Get source color
    vec3 col = texture(bitmap, uv).xyz;     

    // Dither
    col += ditherTable[int( coor.x ) % 4][int( coor.y ) % 4] * 0.03; // last number is dithering strength

    // Reduce colors    
    col = floor(col * COLOR_FACTOR) / COLOR_FACTOR;    
   
    // Output to screen
    fragColor = vec4(col,1.);
}

void main() {
    mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}