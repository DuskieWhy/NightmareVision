package funkin.objects.shader;

import flixel.system.FlxAssets.FlxShader;
using StringTools;


class FuckScorp extends FlxShader {
	@:glFragmentSource('
#pragma header

#pragma format R8G8B8A8_SRGB

#define NTSC_CRT_GAMMA 1.25
#define NTSC_MONITOR_GAMMA 1.0

#define TWO_PHASE
#define COMPOSITE
//#define THREE_PHASE
// #define SVIDEO

// begin params
#define PI 3.14159265

#if defined(TWO_PHASE)
	#define CHROMA_MOD_FREQ (4.0 * PI / 15.0)
#elif defined(THREE_PHASE)
	#define CHROMA_MOD_FREQ (PI / 3.0)
#endif

#if defined(COMPOSITE)
	#define SATURATION 1.0
	#define BRIGHTNESS 1.0
	#define ARTIFACTING 1.0
	#define FRINGING 1.0
#elif defined(SVIDEO)
	#define SATURATION 1.0
	#define BRIGHTNESS 1.0
	#define ARTIFACTING 0.0
	#define FRINGING 0.0
#endif
// end params

uniform int uFrame;
uniform float uInterlace;

// fragment compatibility #defines

#if defined(COMPOSITE) || defined(SVIDEO)
mat3 mix_mat = mat3(
	BRIGHTNESS, FRINGING, FRINGING,
	ARTIFACTING, 2.0 * SATURATION, 0.0,
	ARTIFACTING, 0.0, 2.0 * SATURATION
);
#endif

// begin ntsc-rgbyuv
const mat3 yiq2rgb_mat = mat3(
	1.0, 0.956, 0.6210,
	1.0, -0.2720, -0.6474,
	1.0, -1.1060, 1.7046);

vec3 yiq2rgb(vec3 yiq)
{
	return yiq * yiq2rgb_mat;
}

const mat3 yiq_mat = mat3(
	0.2989, 0.5870, 0.1140,
	0.5959, -0.2744, -0.3216,
	0.2115, -0.5229, 0.3114
);

vec3 rgb2yiq(vec3 col)
{
	return col * yiq_mat;
}
// end ntsc-rgbyuv

#define TAPS 32
const float luma_filter[TAPS + 1] = float[TAPS + 1](
	-0.000174844,
	-0.000205844,
	-0.000149453,
	-0.000051693,
	0.000000000,
	-0.000066171,
	-0.000245058,
	-0.000432928,
	-0.000472644,
	-0.000252236,
	0.000198929,
	0.000687058,
	0.000944112,
	0.000803467,
	0.000363199,
	0.000013422,
	0.000253402,
	0.001339461,
	0.002932972,
	0.003983485,
	0.003026683,
	-0.001102056,
	-0.008373026,
	-0.016897700,
	-0.022914480,
	-0.021642347,
	-0.008863273,
	0.017271957,
	0.054921920,
	0.098342579,
	0.139044281,
	0.168055832,
	0.178571429);

const float chroma_filter[TAPS + 1] = float[TAPS + 1](
	0.001384762,
	0.001678312,
	0.002021715,
	0.002420562,
	0.002880460,
	0.003406879,
	0.004004985,
	0.004679445,
	0.005434218,
	0.006272332,
	0.007195654,
	0.008204665,
	0.009298238,
	0.010473450,
	0.011725413,
	0.013047155,
	0.014429548,
	0.015861306,
	0.017329037,
	0.018817382,
	0.020309220,
	0.021785952,
	0.023227857,
	0.024614500,
	0.025925203,
	0.027139546,
	0.028237893,
	0.029201910,
	0.030015081,
	0.030663170,
	0.031134640,
	0.031420995,
	0.031517031);

// #define fetch_offset(offset, one_x) \\
// 	pass1(uv - vec2(0.5 / openfl_TextureSize.x, 0.0) + vec2((offset) * (one_x), 0.0)).xyzw

#define fetch_offset(offset, one_x) \\
	pass1(uv + vec2((offset - 0.5) * one_x, 0.0)).xyzw

vec4 pass1(vec2 uv)
{
	vec2 fragCoord = uv * openfl_TextureSize;

	vec4 cola = texture2D(bitmap, uv).rgba;
	vec3 yiq = rgb2yiq(cola.rgb);

	#if defined(TWO_PHASE)
		float chroma_phase = PI * (mod(fragCoord.y, 2.0) + float(uFrame));
	#elif defined(THREE_PHASE)
		float chroma_phase = 0.6667 * PI * (mod(fragCoord.y, 3.0) + float(uFrame));
	#endif

	float mod_phase = chroma_phase + fragCoord.x * CHROMA_MOD_FREQ;

	float i_mod = cos(mod_phase);
	float q_mod = sin(mod_phase);

	if(uInterlace == 1.0) {
		yiq.yz *= vec2(i_mod, q_mod); // Modulate.
		yiq *= mix_mat; // Cross-talk.
		yiq.yz *= vec2(i_mod, q_mod); // Demodulate.
	}
	return vec4(yiq, cola.a);
}

void main()
{
	vec2 uv = openfl_TextureCoordv;
	vec2 fragCoord = uv * openfl_TextureSize;

	float one_x = 1.0 / openfl_TextureSize.x;
	vec4 signal = vec4(0.0);

	for (int i = 0; i < TAPS; i++)
	{
		float offset = float(i);

		vec4 sums = fetch_offset(offset - float(TAPS), one_x) +
			fetch_offset(float(TAPS) - offset, one_x);

		signal += sums * vec4(luma_filter[i], chroma_filter[i], chroma_filter[i], 1.0);
	}
	signal += pass1(uv - vec2(0.5 / openfl_TextureSize.x, 0.0)).xyzw *
		vec4(luma_filter[TAPS], chroma_filter[TAPS], chroma_filter[TAPS], 1.0);

	vec3 rgb = yiq2rgb(signal.xyz);
	float alpha = signal.a/(TAPS+1); //idk can go back maybe later
	vec4 color = vec4(pow(rgb, vec3(NTSC_CRT_GAMMA / NTSC_MONITOR_GAMMA)), flixel_texture2D(bitmap,openfl_TextureCoordv).a);
	gl_FragColor = color;
}
')

	var topPrefix:String = "";

	public function new() {
		topPrefix = "#version 120\n\n";
		__glSourceDirty = true;

		super();

		this.uFrame.value = [0];
		this.uInterlace.value = [1];
	}

	public var interlace(get, set):Bool;

	function get_interlace() {
		return this.uInterlace.value[0] == 1.0;
	}
	function set_interlace(val:Bool) {
		this.uInterlace.value[0] = val ? 1.0 : 0.0;
		return val;
	}

	override function __updateGL() {
		//this.uFrame.value[0]++;
		this.uFrame.value[0] = (this.uFrame.value[0] + 1) % 2;

		super.__updateGL();
	}

	@:noCompletion private override function __initGL():Void
	{
		if (__glSourceDirty || __paramBool == null)
		{
			__glSourceDirty = false;
			program = null;

			__inputBitmapData = new Array();
			__paramBool = new Array();
			__paramFloat = new Array();
			__paramInt = new Array();

			__processGLData(glVertexSource, "attribute");
			__processGLData(glVertexSource, "uniform");
			__processGLData(glFragmentSource, "uniform");
		}

		@:privateAccess if (__context != null && program == null)
		{
			var gl = __context.gl;

			#if (js && html5)
			var prefix = (precisionHint == FULL ? "precision mediump float;\n" : "precision lowp float;\n");
			#else
			var prefix = "#ifdef GL_ES\n"
				+ (precisionHint == FULL ? "#ifdef GL_FRAGMENT_PRECISION_HIGH\n"
					+ "precision highp float;\n"
					+ "#else\n"
					+ "precision mediump float;\n"
					+ "#endif\n" : "precision lowp float;\n")
				+ "#endif\n\n";
			#end

			var vertex = topPrefix + prefix + glVertexSource;
			var fragment = topPrefix + prefix + glFragmentSource;

			var id = vertex + fragment;

			if (__context.__programs.exists(id))
			{
				program = __context.__programs.get(id);
			}
			else
			{
				program = __context.createProgram(GLSL);

				// TODO
				// program.uploadSources (vertex, fragment);
				program.__glProgram = __createGLProgram(vertex, fragment);

				__context.__programs.set(id, program);
			}

			if (program != null)
			{
				glProgram = program.__glProgram;

				for (input in __inputBitmapData)
				{
					if (input.__isUniform)
					{
						input.index = gl.getUniformLocation(glProgram, input.name);
					}
					else
					{
						input.index = gl.getAttribLocation(glProgram, input.name);
					}
				}

				for (parameter in __paramBool)
				{
					if (parameter.__isUniform)
					{
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					}
					else
					{
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}

				for (parameter in __paramFloat)
				{
					if (parameter.__isUniform)
					{
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					}
					else
					{
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}

				for (parameter in __paramInt)
				{
					if (parameter.__isUniform)
					{
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					}
					else
					{
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}
			}
		}
	}
}