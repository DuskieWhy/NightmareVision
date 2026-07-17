package funkin.utils;

import haxe.Json;

import funkin.data.NoteSkin;
import funkin.data.NoteSkin.Animation;
import funkin.data.NoteSkin.ColorList;
import funkin.game.shaders.*;
import funkin.game.shaders.RGBShader;

// should be rewritten ngl
// i agree its so ugly please
class NoteUtil
{
	public static var keys:Int = DEFAULT_KEYS;
	
	public static var noteskins:Array<NoteSkin> = [];
	
	public static function getSkinFromID(id:Int = 0)
	{
		// check list of skins and return the one with the specified id
		for (i in noteskins)
		{
			if (i.ID == id) return i;
		}
		
		// if no skin with that id exists, return the first noteskin
		final skin = noteskins[0];
		
		// if all the skins are null, create a new default noteskin
		return (skin == null ? (new NoteSkin('default', 4, 0)) : skin);
	}
	
	// quant stuff
	public static final quants:Array<Int> = [
		4, // quarter note
		8, // eight
		12, // etc
		16, 20, 24, 32, 48, 64, 96, 192];
		
	public static function getQuant(beat:Float)
	{
		var row = Conductor.beatToNoteRow(beat);
		for (data in quants)
		{
			if (row % (Conductor.ROWS_PER_MEASURE / data) == 0)
			{
				return data;
			}
		}
		return quants[quants.length - 1]; // invalid
	}
	
	// constants
	public static final DEFAULT_KEYS:Int = 4;
	
	public static final DEFAULT_TEXTURE:String = 'UI/notes/NOTE_assets';
	
	public static final DEFAULT_SPLASH_TEXTURE:String = 'UI/notes/noteSplashes';
	
	public static final DEFAULT_SUSTAIN_SPLASH_TEXTURE:String = 'UI/notes/sustainHold';
	
	public static final DEFAULT_NOTE_ANIMATIONS:Array<Array<Animation>> = [
		[
			{
				anim: "scroll",
				xmlName: "purple",
				offsets: [0, 0],
				looping: true,
				fps: 24
			},
			{
				anim: "hold",
				xmlName: "purple hold piece",
				offsets: [0, 0],
				looping: true,
				fps: 24
			},
			{
				anim: 'holdend',
				xmlName: 'pruple end hold',
				offsets: [0, 0],
				looping: true,
				fps: 24
			}
		],
		[
			{
				anim: "scroll",
				xmlName: "blue",
				offsets: [0, 0],
				looping: true,
				fps: 24
			},
			{
				anim: "hold",
				xmlName: "blue hold piece",
				offsets: [0, 0],
				looping: true,
				fps: 24
			},
			{
				anim: "holdend",
				xmlName: "blue hold end",
				offsets: [0, 0],
				looping: true,
				fps: 24
			}
		],
		[
			{
				anim: "scroll",
				xmlName: "green",
				offsets: [0, 0],
				looping: true,
				fps: 24
			},
			{
				anim: "hold",
				xmlName: "green hold piece",
				offsets: [0, 0],
				looping: true,
				fps: 24
			},
			{
				anim: "holdend",
				xmlName: "green hold end",
				offsets: [0, 0],
				looping: true,
				fps: 24
			}
		],
		[
			{
				anim: "scroll",
				xmlName: "red",
				offsets: [0, 0],
				looping: true,
				fps: 24
			},
			{
				anim: "hold",
				xmlName: "red hold piece",
				offsets: [0, 0],
				looping: true,
				fps: 24
			},
			{
				anim: "holdend",
				xmlName: "red hold end",
				offsets: [0, 0],
				looping: true,
				fps: 24
			}
		]
	];
	public static final DEFAULT_RECEPTOR_ANIMATIONS:Array<Array<Animation>> = [
		[
			{
				anim: 'static',
				xmlName: "arrowLEFT",
				offsets: [0, 0],
				looping: false,
				fps: 24
			},
			{
				anim: "pressed",
				xmlName: "left press",
				offsets: [0, 0],
				looping: false,
				fps: 24
			},
			{
				anim: "confirm",
				xmlName: "left confirm",
				offsets: [0, 0],
				looping: false,
				fps: 24
			}
		],
		[
			{
				anim: "static",
				xmlName: "arrowDOWN",
				offsets: [0, 0],
				looping: false,
				fps: 24
			},
			{
				anim: "pressed",
				xmlName: "down press",
				offsets: [0, 0],
				looping: false,
				fps: 24
			},
			{
				anim: "confirm",
				xmlName: "down confirm",
				offsets: [0, 0],
				looping: false,
				fps: 24
			}
		],
		[
			{
				anim: "static",
				xmlName: "arrowUP",
				offsets: [0, 0],
				looping: false,
				fps: 24
			},
			{
				anim: "pressed",
				xmlName: "up press",
				offsets: [0, 0],
				looping: false,
				fps: 24
			},
			{
				anim: "confirm",
				xmlName: "up confirm",
				offsets: [0, 0],
				looping: false,
				fps: 24
			}
		],
		[
			{
				anim: "static",
				xmlName: "arrowRIGHT",
				offsets: [0, 0],
				looping: false,
				fps: 24
			},
			{
				anim: "pressed",
				xmlName: "right press",
				offsets: [0, 0],
				looping: false,
				fps: 24
			},
			{
				anim: "confirm",
				xmlName: "right confirm",
				offsets: [0, 0],
				looping: false,
				fps: 24
			}
		]
	];
	
	public static final DEFAULT_NOTESPLASH_ANIMATIONS:Array<Animation> = [
		{anim: "note0", xmlName: "note splash purple", offsets: [4, 15]},
		{anim: "note1", xmlName: "note splash blue", offsets: [13, 15]},
		{anim: "note2", xmlName: "note splash green", offsets: [16, 15]},
		{anim: "note3", xmlName: "note splash red", offsets: [22, 15]}
	];
	
	public static final DEFAULT_SUSTAIN_SPLASH_ANIMATIONS:Array<Array<Animation>> = [
		[
			{
				anim: "start",
				xmlName: "start",
				offsets: [0, 0],
				looping: false
			},
			{
				anim: "loop",
				xmlName: "loop",
				offsets: [45, 35],
				looping: true,
				fps: 12
			},
			{
				anim: "end",
				xmlName: "end",
				offsets: [50, 60],
				looping: false
			}
		],
		[
			{
				anim: "start",
				xmlName: "start",
				offsets: [0, 0],
				looping: false
			},
			{
				anim: "loop",
				xmlName: "loop",
				offsets: [45, 35],
				looping: true,
				fps: 12
			},
			{
				anim: "end",
				xmlName: "end",
				offsets: [50, 60],
				looping: false
			}
		],
		[
			{
				anim: "start",
				xmlName: "start",
				offsets: [0, 0],
				looping: false
			},
			{
				anim: "loop",
				xmlName: "loop",
				offsets: [45, 35],
				looping: true,
				fps: 12
			},
			{
				anim: "end",
				xmlName: "end",
				offsets: [50, 60],
				looping: false
			}
		],
		[
			{
				anim: "start",
				xmlName: "start",
				offsets: [0, 0],
				looping: false
			},
			{
				anim: "loop",
				xmlName: "loop",
				offsets: [45, 35],
				looping: true,
				fps: 12
			},
			{
				anim: "end",
				xmlName: "end",
				offsets: [50, 60],
				looping: false
			}
		]
	];
	
	public static final fallbackReceptorAnims:Array<Animation> = [
		{
			anim: 'static',
			xmlName: "placeholder",
			offsets: [0, 0]
		},
		{
			anim: "pressed",
			xmlName: "placeholder",
			offsets: [0, 0]
		},
		{
			anim: "confirm",
			xmlName: "placeholder",
			offsets: [0, 0]
		}
	];
	
	public static final fallbackNoteAnims:Array<Animation> = [
		{
			anim: "scroll",
			xmlName: "purple",
			offsets: [0, 0]
		},
		{
			anim: "hold",
			xmlName: "purple hold piece",
			offsets: [0, 0]
		},
		{
			anim: 'holdend',
			xmlName: 'pruple end hold',
			offsets: [0, 0]
		}
	];
	
	public static function fallbackNote(id:Int)
	{
		var anim:Array<Animation> = [
			{
				anim: "scroll",
				xmlName: "purple",
				offsets: [0, 0]
			},
			{
				anim: "hold",
				xmlName: "purple hold piece",
				offsets: [0, 0]
			},
			{
				anim: 'holdend',
				xmlName: 'pruple end hold',
				offsets: [0, 0]
			}
		];
		
		for (i in anim)
			i.anim = '${i.anim}${Std.string(id)}';
			
		return anim;
	}
	
	public static function fallbackSplash(id:Int)
	{
		var anim:Animation = {anim: "note", xmlName: "note splash purple", offsets: [0, 0]};
		anim.anim = '${anim.anim}${Std.string(id)}';
		return anim;
	}
	
	public static final defaultSingAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	
	public static var defaultColors:Array<ColorList> = [
		{r: 0xFFC24B99, g: 0xFFFFFFFF, b: 0xFF3C1F56},
		{r: 0xFF00FFFF, g: 0xFFFFFFFF, b: 0xFF1542B7},
		{r: 0xFF12FA05, g: 0xFFFFFFFF, b: 0xFF0A4447},
		{r: 0xFFF9393F, g: 0xFFFFFFFF, b: 0xFF651038}
	];
	
	public static var quantDefaultColors:Array<ColorList> = [
		{r: 0xFFF9393F, g: 0xFFFFFFFF, b: 0xFF651038}, // 4th
		{r: 0xFF00FFFF, g: 0xFFFFFFFF, b: 0xFF1542B7}, // 8th
		{r: 0xFFC24B99, g: 0xFFFFFFFF, b: 0xFF3C1F56}, // 12th
		{r: 0xFFF0E342, g: 0xFFFFFFFF, b: 0xFF554320}, // 16th
		{r: 0xFFED36AD, g: 0xFFFFFFFF, b: 0xFF5C185A}, // 20th
		{r: 0xFFE98F16, g: 0xFFFFFFFF, b: 0xFF3F2D12}, // 24th
		{r: 0xFF4769B8, g: 0xFFFFFFFF, b: 0xFF161B27}, // 32nd
		{r: 0xFF12FA05, g: 0xFFFFFFFF, b: 0xFF0A4447}, // 48th
		{r: 0xFF008080, g: 0xFFFFFFFF, b: 0xFF004D4D}, // 64th
		{r: 0xFF8a8a8a, g: 0xFFFFFFFF, b: 0xff3a3a3a}, // 96th
		{r: 0xFFbab86c, g: 0xFFFFFFFF, b: 0xff505a1f} // 192nd
	];
	
	public static function getCurColors(id:Int = 0, quant:Int = 0, player:Int = 0)
	{
		final skin = getSkinFromID(player);
		
		final idx = id > skin.keys ? 0 : id;
		
		var colors = skin.colors[idx];
		if (ClientPrefs.quants && quant != 0)
		{
			if (skin.quantColors != null)
				colors = skin.quantColors[quants.indexOf(quant)];
			else
				colors = quantDefaultColors[quants.indexOf(quant)];
		}
		
		return new RGBGraphics(colors.r, colors.g, colors.b);
	}
	
	public static function colorToArray(color:ColorList):Array<FlxColor>
	{
		final _color = color ?? defaultColors[0];
		
		var arr:Array<FlxColor> = [_color.r, _color.g, _color.b];
		return arr;
	}
}
