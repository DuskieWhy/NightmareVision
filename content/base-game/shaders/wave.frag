#pragma header
vec2 uv = openfl_TextureCoordv.xy;
vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
vec2 iResolution = openfl_TextureSize;
uniform float iTime;
#define iChannel0 bitmap
#define texture flixel_texture2D
#define fragColor gl_FragColor
#define mainImage main
uniform float spacing;
uniform float intensity;

void mainImage( )
{
	// Get the UV Coordinate of your texture or Screen Texture, yo!
	vec2 uv = fragCoord.xy / iResolution.xy;
	
	// Flip that shit, cause shadertool be all "yolo opengl"
	// uv.y = -1.0 - uv.y;
	
	// Modify that X coordinate by the sin of y to oscillate back and forth up in this.
	uv.x += sin(uv.y*spacing+iTime)/intensity;
	
	// Get the pixel color at the index.
	// vec4 color = texture(iChannel0, uv);
	
	fragColor = texture(iChannel0, uv);
}