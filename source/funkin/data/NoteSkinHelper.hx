package funkin.data;

import haxe.Json;

import flixel.math.FlxPoint;

import funkin.objects.*;

// havent implemented this
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
	?splashesEnabled:Bool
}

class NoteSkinHelper
{
	static final defaultTexture:String = 'NOTE_assets';
	static final defaultSplashTexture:String = 'noteSplashes';
	
	static final defaultNoteAnimations:Array<Array<Animation>> = [
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
	static final defaultReceptorAnimations:Array<Array<Animation>> = [
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
	static final defaultNoteSplashAnimations:Array<Animation> = [
		{anim: "note0", xmlName: "note splash purple", offsets: [0, 0]},
		{anim: "note1", xmlName: "note splash blue", offsets: [0, 0]},
		{anim: "note2", xmlName: "note splash green", offsets: [0, 0]},
		{anim: "note3", xmlName: "note splash red", offsets: [0, 0]}
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
	
	public var data:NoteSkinData;
	
	public function new(path:String)
	{
		var rawJson = null;
		
		try
		{
			rawJson = File.getContent(path).trim();
			data = parseJSON(rawJson);
		}
		catch (e:Dynamic)
		{
			data = {};
			trace(e);
		}
		resolveData(data);
	}
	
	public static function resolveData(data:NoteSkinData)
	{
		data.globalSkin ??= defaultTexture;
		data.playerSkin ??= data.globalSkin;
		data.opponentSkin ??= data.globalSkin;
		data.extraSkin ??= data.globalSkin;
		data.noteSplashSkin ??= defaultSplashTexture;
		data.hasQuants ??= false;
		data.isQuants ??= false;
		
		data.isPixel ??= false;
		data.pixelSize ??= [4, 5];
		data.antialiasing ??= true;
		data.sustainSuffix ??= 'ENDS';
		
		data.noteAnimations ??= defaultNoteAnimations;
		data.receptorAnimations ??= defaultReceptorAnimations;
		data.noteSplashAnimations ??= defaultNoteSplashAnimations;
		for (j in [data.noteAnimations, data.receptorAnimations])
			for (i in j)
				for (k in i)
					if (k.looping == null) k.looping = false;

		data.singAnimations ??= defaultSingAnimations;
		data.scale ??= 0.7;
		data.splashesEnabled ??= true;
	}
	
	public static function parseJSON(rawJson:String):NoteSkinData
	{
		var data:NoteSkinData = cast Json.parse(rawJson);
		return data;
	}
	
	public static var arrowSkins:Array<String> = [];
	
	public static function setNoteHelpers(helper:NoteSkinHelper, keys:Int = 4)
	{
		// trace('set helpers!');
		
		Note.handler = helper;
		StrumNote.handler = helper;
		NoteSplash.handler = helper;
		
		Note.keys = keys;
		StrumNote.keys = keys;
		NoteSplash.keys = keys;
	}
	// public static function getTempNoteAnim(handler:NoteSkinHelper)
	// {
	// 	var anim = fallbackNoteAnims.copy();
	// 	var temp = 0;
	// 	for (i in handler.data.noteAnimations)
	// 		if (i[0].color.contains('temp')) temp += 1;
	// 	trace(temp);
	// 	for (i in 0...anim.length)
	// 		anim[i].color = 'temp ' + temp;
	// 	trace(anim);
	// 	return anim;
	// }
}
