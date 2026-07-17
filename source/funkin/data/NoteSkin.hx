package funkin.data;

import haxe.ds.Vector;

import flixel.math.FlxPoint;

import funkin.data.NoteSkin.Animation;
import funkin.data.NoteSkin.ColorList;

class NoteSkin implements IFlxDestroyable
{
	public var data:NoteSkinData;
	
	public var name:String = '';
	// public var helper:NoteSkinHelper;
	public var keys:Int = 4;
	public var ID:Int = 0;
	
	// textures
	public var noteTexture:String = '';
	public var splashTexture:String = '';
	public var sustainSplashTexture:String = '';
	
	// anims
	public var noteAnims:Array<Array<Animation>> = [];
	public var receptorAnims:Array<Array<Animation>> = [];
	public var splashAnims:Array<Animation> = [];
	public var susSplashAnims:Array<Array<Animation>> = [];
	
	// offsets
	public var noteOffsets:Vector<FlxPoint>;
	public var sustainOffsets:Vector<FlxPoint>;
	public var susEndOffsets:Vector<FlxPoint>;
	public var splashOffsets:Vector<FlxPoint>;
	
	// these arent set by noteskin jsons, but can be manually set via scripts in case u need to offset some specific stuff
	public var sustainSplashOffsets:Vector<FlxPoint>;
	public var receptorOffsets:Vector<FlxPoint>;
	
	// settings
	public var quantsEnabled:Bool = true;
	public var splashesEnabled:Bool = true;
	public var sustainSplashes:Bool = true;
	public var antialiasing:Bool = true;
	
	// alpha
	// not functional yet cuz i wanna make hotswapping shit functional first
	public var receptorAlpha:Float = 1.0;
	public var sustainAlpha:Float = 1.0;
	public var splashAlpha:Float = 1.0;
	public var susSplashAlpha:Float = 1.0;
	
	// scale
	public var receptorScale:Float = 0.7;
	public var noteScale:Float = 0.7;
	public var splashScale:Float = 1;
	public var susSplashScale:Float = 1;
	
	// coloring
	public var inEngineColoring:Bool = true;
	public var colors:Array<ColorList> = [];
	
	// sing anims
	public var singAnimations = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	
	public function new(path:String, _keys:Int = -1, id:Int = 0)
	{
		data = loadFromPath(Paths.noteskin(path));
		
		keys = _keys;
		name = path;
		this.ID = id;
		
		noteOffsets = new Vector<FlxPoint>(keys);
		sustainOffsets = new Vector<FlxPoint>(keys);
		susEndOffsets = new Vector<FlxPoint>(keys);
		receptorOffsets = new Vector<FlxPoint>(keys);
		splashOffsets = new Vector<FlxPoint>(keys);
		sustainSplashOffsets = new Vector<FlxPoint>(keys);
		
		for (i in 0...keys)
		{
			noteOffsets[i] = new FlxPoint();
			receptorOffsets[i] = new FlxPoint();
			sustainOffsets[i] = new FlxPoint();
			susEndOffsets[i] = new FlxPoint();
			splashOffsets[i] = new FlxPoint();
			sustainSplashOffsets[i] = new FlxPoint();
		}
		
		noteAnims = data.noteAnimations;
		receptorAnims = data.receptorAnimations;
		splashAnims = data.noteSplashAnimations;
		susSplashAnims = data.susSplashAnimations;
		
		noteTexture = data.noteTexture;
		splashTexture = data.splashTexture;
		sustainSplashTexture = data.sustainSplashTexture;
		
		singAnimations = data.singAnimations;
		splashesEnabled = data.splashesEnabled;
		sustainSplashes = data.susSplashesEnabled;
		antialiasing = data.antialiasing;
		
		receptorScale = data.receptorScale;
		noteScale = data.noteScale;
		splashScale = data.splashScale;
		susSplashScale = data.susSplashScale;
		
		inEngineColoring = data.inGameColoring;
		colors = data.arrowRGB;
	}
	
	public function destroy()
	{
		// ill do this later
	}
	
	public function loadFromPath(path:String):NoteSkinData
	{
		var _data:NoteSkinData;
		
		if (FunkinAssets.exists(path)) _data = cast FunkinAssets.parseJson(FunkinAssets.getContent(path)) ?? {};
		else _data = {};
		
		resolveData(_data);
		
		return _data;
	}
	
	public static function resolveData(data:NoteSkinData)
	{
		inline function correctAnims(input:Array<Animation>)
		{
			for (i in input)
			{
				i.offsets ??= [0, 0];
				i.looping ??= false;
				i.fps ??= 24;
			}
		}
		
		data.noteTexture ??= NoteUtil.DEFAULT_TEXTURE;
		data.splashTexture ??= NoteUtil.DEFAULT_SPLASH_TEXTURE;
		data.sustainSplashTexture ??= NoteUtil.DEFAULT_SUSTAIN_SPLASH_TEXTURE;
		
		data.antialiasing ??= true;
		
		data.noteAnimations ??= NoteUtil.DEFAULT_NOTE_ANIMATIONS;
		data.receptorAnimations ??= NoteUtil.DEFAULT_RECEPTOR_ANIMATIONS;
		data.noteSplashAnimations ??= NoteUtil.DEFAULT_NOTESPLASH_ANIMATIONS;
		data.susSplashAnimations ??= NoteUtil.DEFAULT_SUSTAIN_SPLASH_ANIMATIONS;
		
		// correcting note animation data that might have missing fields
		for (j in [data.noteAnimations, data.receptorAnimations, data.susSplashAnimations])
		{
			for (i in j)
				correctAnims(i);
		}
		correctAnims(data.noteSplashAnimations);
		
		data.singAnimations ??= NoteUtil.defaultSingAnimations;
		data.splashesEnabled ??= true;
		data.susSplashesEnabled ??= true;
		
		data.receptorAlpha ??= 1.0;
		data.sustainAlpha ??= 1.0;
		data.splashAlpha ??= 1.0;
		data.susSplashAlpha ??= 1.0;
		
		data.receptorScale ??= 0.7;
		data.noteScale ??= 0.7;
		data.splashScale ??= 1;
		data.susSplashScale ??= 1;
		
		data.arrowRGB ??= NoteUtil.defaultColors.copy();
		data.inGameColoring ??= true;
	}
}

typedef NoteSkinData =
{
	?noteTexture:String,
	?splashTexture:String,
	?sustainSplashTexture:String,
	
	?antialiasing:Bool,
	?singAnimations:Array<String>,
	
	?noteAnimations:Array<Array<Animation>>,
	?receptorAnimations:Array<Array<Animation>>,
	?noteSplashAnimations:Array<Animation>,
	?susSplashAnimations:Array<Array<Animation>>,
	
	?splashesEnabled:Bool,
	?susSplashesEnabled:Bool,
	
	?receptorAlpha:Float,
	?sustainAlpha:Float,
	?splashAlpha:Float,
	?susSplashAlpha:Float,
	
	?receptorScale:Float,
	?noteScale:Float,
	?splashScale:Float,
	?susSplashScale:Float,
	
	?inGameColoring:Bool,
	?arrowRGB:Array<ColorList>
}

typedef Animation =
{
	?anim:String,
	?xmlName:String,
	?offsets:Array<Float>,
	?looping:Bool,
	?fps:Int
}

typedef ColorList =
{
	?r:FlxColor,
	?g:FlxColor,
	?b:FlxColor
}
