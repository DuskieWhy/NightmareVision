package funkin.data;

import haxe.Json;

import funkin.game.shaders.*;
import funkin.game.shaders.RGBPalette.RGBShaderReference;

typedef Animation =
{
	?anim:String,
	?xmlName:String,
	?offsets:Array<Float>,
	?looping:Bool
}

typedef NoteSkinData =
{
	?globalSkin:String,
	?playerSkin:String,
	?opponentSkin:String,
	?extraSkin:String,
	?noteSplashSkin:String,
	
	// depricated but leaving so it doesnt crash
	?hasQuants:Bool,
	?isQuants:Bool,
	
	?isPixel:Bool,
	?pixelSize:Array<Int>,
	?antialiasing:Bool,
	?sustainSuffix:String,
	/*
		[
			{ anim: "idle", xmlName: "fuck", offsets: [x, y]},
			{ anim: "sustain", xmlName: "fuck", offsets: [x, y]},
			{ anim: "sustain end", xmlName: "fuck", offsets: [x, y]},
		]
	 */
	?noteAnimations:Array<Array<Animation>>,
	
	/*
		[
			{ anim: "idle", xmlName: "fuck", offsets: [x, y]},
			{ anim: "press", xmlName: "fuck", offsets: [x, y]},
			{ anim: "confirm", xmlName: "fuck", offsets: [x, y]},
		]
	 */
	?receptorAnimations:Array<Array<Animation>>,
	
	/*
		[

		]
	 */
	?noteSplashAnimations:Array<Animation>,
	
	?singAnimations:Array<String>,
	?scale:Float,
	?splashesEnabled:Bool,
	?inGameColoring:Bool
}

// should be rewritten ngl
// i agree its so ugly please
class NoteSkinHelper implements IFlxDestroyable
{
	public static var keys:Int = DEFAULT_KEYS;
	
	// to do do this instead
	public static var instance:Null<NoteSkinHelper> = null;
	
	public static function init():Void
	{
		if (instance == null) instance = new NoteSkinHelper(Paths.getPath('noteskins/default.json', TEXT));
	}
	
	public var data(default, null):NoteSkinData;
	
	public function new(path:String)
	{
		loadFromPath(path);
	}
	
	public function destroy()
	{
		data = null;
	}
	
	public function loadFromPath(path:String, keyCount:Int = -1)
	{
		if (FunkinAssets.exists(path))
		{
			data = cast FunkinAssets.parseJson(FunkinAssets.getContent(path)) ?? {};
		}
		else
		{
			data = {};
		}
		
		if (keyCount != -1) keys = keyCount;
		resolveData(data);
	}
	
	public static var arrowSkins:Array<String> = [];
	
	// quant stuff
	public static final quants:Array<Int> = [4, // quarter note
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
	
	static final DEFAULT_TEXTURE:String = 'NOTE_assets';
	
	static final DEFAULT_SPLASH_TEXTURE:String = 'noteSplashes';
	
	static final DEFAULT_NOTE_ANIMATIONS:Array<Array<Animation>> = [
		[
			{
				anim: "scroll",
				xmlName: "purple",
				offsets: [0, 0],
				looping: true
			},
			{
				anim: "hold",
				xmlName: "purple hold piece",
				offsets: [0, 0],
				looping: true
			},
			{
				anim: 'holdend',
				xmlName: 'pruple end hold',
				offsets: [0, 0],
				looping: true
			}
		],
		[
			{
				anim: "scroll",
				xmlName: "blue",
				offsets: [0, 0],
				looping: true
			},
			{
				anim: "hold",
				xmlName: "blue hold piece",
				offsets: [0, 0],
				looping: true
			},
			{
				anim: "holdend",
				xmlName: "blue hold end",
				offsets: [0, 0],
				looping: true
			}
		],
		[
			{
				anim: "scroll",
				xmlName: "green",
				offsets: [0, 0],
				looping: true
			},
			{
				anim: "hold",
				xmlName: "green hold piece",
				offsets: [0, 0],
				looping: true
			},
			{
				anim: "holdend",
				xmlName: "green hold end",
				offsets: [0, 0],
				looping: true
			}
		],
		[
			{
				anim: "scroll",
				xmlName: "red",
				offsets: [0, 0],
				looping: true
			},
			{
				anim: "hold",
				xmlName: "red hold piece",
				offsets: [0, 0],
				looping: true
			},
			{
				anim: "holdend",
				xmlName: "red hold end",
				offsets: [0, 0],
				looping: true
			}
		]
	];
	static final DEFAULT_RECEPTOR_ANIMATIONS:Array<Array<Animation>> = [
		[
			{
				anim: 'static',
				xmlName: "arrowLEFT",
				offsets: [0, 0],
				looping: false
			},
			{
				anim: "pressed",
				xmlName: "left press",
				offsets: [0, 0],
				looping: false
			},
			{
				anim: "confirm",
				xmlName: "left confirm",
				offsets: [0, 0],
				looping: false
			}
		],
		[
			{
				anim: "static",
				xmlName: "arrowDOWN",
				offsets: [0, 0],
				looping: false
			},
			{
				anim: "pressed",
				xmlName: "down press",
				offsets: [0, 0],
				looping: false
			},
			{
				anim: "confirm",
				xmlName: "down confirm",
				offsets: [0, 0],
				looping: false
			}
		],
		[
			{
				anim: "static",
				xmlName: "arrowUP",
				offsets: [0, 0],
				looping: false
			},
			{
				anim: "pressed",
				xmlName: "up press",
				offsets: [0, 0],
				looping: false
			},
			{
				anim: "confirm",
				xmlName: "up confirm",
				offsets: [0, 0],
				looping: false
			}
		],
		[
			{
				anim: "static",
				xmlName: "arrowRIGHT",
				offsets: [0, 0],
				looping: false
			},
			{
				anim: "pressed",
				xmlName: "right press",
				offsets: [0, 0],
				looping: false
			},
			{
				anim: "confirm",
				xmlName: "right confirm",
				offsets: [0, 0],
				looping: false
			}
		]
	];
	public static final DEFAULT_NOTESPLASH_ANIMATIONS:Array<Animation> = [
		{anim: "note0", xmlName: "note splash purple", offsets: [4, 15]},
		{anim: "note1", xmlName: "note splash blue", offsets: [13, 15]},
		{anim: "note2", xmlName: "note splash green", offsets: [16, 15]},
		{anim: "note3", xmlName: "note splash red", offsets: [22, 15]}
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
	
	static final defaultSingAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	
	public static function resolveData(data:NoteSkinData)
	{
		data.globalSkin ??= DEFAULT_TEXTURE;
		data.playerSkin ??= data.globalSkin;
		data.opponentSkin ??= data.globalSkin;
		data.extraSkin ??= data.globalSkin;
		data.noteSplashSkin ??= DEFAULT_SPLASH_TEXTURE;
		
		data.isPixel ??= false;
		data.pixelSize ??= [4, 5];
		data.antialiasing ??= true;
		data.sustainSuffix ??= 'ENDS';
		
		data.noteAnimations ??= DEFAULT_NOTE_ANIMATIONS;
		data.receptorAnimations ??= DEFAULT_RECEPTOR_ANIMATIONS;
		data.noteSplashAnimations ??= DEFAULT_NOTESPLASH_ANIMATIONS;
		for (j in [data.noteAnimations, data.receptorAnimations])
			for (i in j)
				for (k in i)
					k.looping ??= false;
					
		data.singAnimations ??= defaultSingAnimations;
		data.scale ??= 0.7;
		data.splashesEnabled ??= true;
		
		data.inGameColoring ??= true;
	}
	
	public static var shaderEnabled(get, default):Bool;
	
	static function get_shaderEnabled()
	{
		var en = instance?.data?.inGameColoring ?? false;
		
		return en;
	}
	
	/**
		* Basic setup for a note object's RGB palette. Sets the colors according to the current colors from `getCurColors()`

		* @param id Note Object's ID (or noteData)
		 
		* @param quant If the note style is Quantized, it uses the quant variable to set the palette accordingly.
	 */
	public static function initRGBPalete(id:Int = 0, quant:Int = 4)
	{
		// custom noteskin colors soon i promise
		var newRGB = new RGBPalette();
		var arr = getCurColors(id, quant);
		
		if (shaderEnabled && arr != null && id > -1 && id <= arr.length) newRGB.setColors(arr);
		else newRGB.setColors([0xFFFF0000, 0xFF00FF00, 0xFF0000FF]);
		
		return newRGB;
	}
	
	public static function initRGBShader(object:FlxSprite, id:Int = 0, ?quant:Int = 0)
	{
		var rgbShader = new RGBShaderReference(object, initRGBPalete(id, quant));
		object.shader = rgbShader.shader;
		
		return rgbShader;
	}
	
	public static function getCurColors(id:Int = 0, quant:Int = 4)
	{
		var arr = ClientPrefs.arrowRGBdef[id];
		if (ClientPrefs.noteSkin.contains('Quant')) arr = ClientPrefs.arrowRGBquant[quants.indexOf(quant)];
		
		return arr;
	}
}
