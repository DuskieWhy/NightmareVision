package meta.data.scripts;

import flixel.effects.FlxFlicker;
import flixel.system.FlxBGSprite;
import gameObjects.SpriteFromSheet;
import gameObjects.shader.FuckScorp;
import openfl.filters.ShaderFilter;
import flixel.util.FlxColor;
import flixel.ui.FlxBar;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.tweens.*;
import flixel.*;
import hscript.*;
import lime.utils.Assets;
import lime.app.Application;
import meta.data.scripts.Globals.*;
import flixel.addons.display.FlxRuntimeShader;
import openfl.display.BlendMode;
import meta.data.*;
import meta.states.*;
import meta.states.editors.*;
import gameObjects.*;
#if sys
import openfl.media.Sound;
import sys.FileSystem;
import sys.io.File;
#end
import windows.*;

using StringTools;

class FunkinHScript extends FunkinScript
{
	static var parser:Parser = new Parser();
	public static var defaultVars:Map<String,Dynamic> = new Map<String, Dynamic>();


	public static function init() // BRITISH
	{
		parser.allowMetadata = true;
		parser.allowJSON = true;
		parser.allowTypes = true;
	}

	public static function fromString(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>)
	{
		parser.line = 1;
		var expr:Expr;
		try
		{
			expr = parser.parseString(script, name);
		}
		catch (e:haxe.Exception)
		{
			var errMsg = 'Error parsing hscript! '#if hscriptPos + '$name:' + parser.line + ', ' #end + e.message;
			#if desktop
			Application.current.window.alert(errMsg, "Error on haxe script!");
			#end
			trace(errMsg);

			expr = parser.parseString("", name);
		}
		return new FunkinHScript(expr, name, additionalVars);
	}
	public static function parseString(script:String, ?name:String = "Script")
	{
		return parser.parseString(script, name);
	}

	public static function fromFile(file:String, ?name:String, ?additionalVars:Map<String, Any>)
	{
		if (name == null)
			name = file;
		return fromString(File.getContent(file), name, additionalVars);
	}
	
	public static function parseFile(file:String, ?name:String)
	{
		if (name == null)
			name = file;
		return parseString(File.getContent(file), name);
	}

	var interpreter:Interp = new Interp();

	override public function scriptTrace(text:String) {
		var posInfo = interpreter.posInfos();
		haxe.Log.trace(text, posInfo);
	}
	public function new(parsed:Expr, ?name:String = "Script", ?additionalVars:Map<String, Any>)
	{
		scriptType = 'hscript';
		scriptName = name;

		setDefaultVars();
		set("Std", Std);
		set("Type", Type);
		set("Math", Math);
		set("script", this);
		set("StringTools", StringTools);
		set('Map', haxe.ds.StringMap);
		// set("scriptTrace", function(text:String){
		// 	scriptTrace(text);
		// });
		set("newMap", function(){ // maps aren't really a thing during runtime i think
			return new Map<Dynamic, Dynamic>();
		});

		set('SpriteFromSheet',SpriteFromSheet);
		set('ExUtils',ExUtils);

		set("MusicBeatState", meta.states.MusicBeatState);
		set("Assets", Assets);
		set("OpenFlAssets", openfl.utils.Assets);
		set("FlxG", flixel.FlxG);
		set("state", flixel.FlxG.state);
		set("FlxTypedGroup", flixel.group.FlxGroup.FlxTypedGroup);
		set("createTypedGroup", ()->{
			return new flixel.group.FlxGroup.FlxTypedGroup<Dynamic>();
		});
		set("FlxSprite", HScriptSprite);
		set("FlxAnimate", flxanimate.FlxAnimate);
		
		set("FlxCamera", flixel.FlxCamera);
		set("FlxCameraFollowStyle", {
			LOCKON: flixel.FlxCameraFollowStyle.LOCKON,
			PLATFORMER: flixel.FlxCameraFollowStyle.PLATFORMER,
			TOPDOWN: flixel.FlxCameraFollowStyle.TOPDOWN,
			TOPDOWN_TIGHT: flixel.FlxCameraFollowStyle.TOPDOWN_TIGHT,
			SCREEN_BY_SCREEN: flixel.FlxCameraFollowStyle.SCREEN_BY_SCREEN,
			NO_DEAD_ZONE: flixel.FlxCameraFollowStyle.NO_DEAD_ZONE,

		});
		set("FlxMath", flixel.math.FlxMath);
		set("FlxText", flixel.text.FlxText);
		set("FlxTextBorderStyle", {
			NONE: flixel.text.FlxText.FlxTextBorderStyle.NONE,
			SHADOW: flixel.text.FlxText.FlxTextBorderStyle.SHADOW,
			OUTLINE: flixel.text.FlxText.FlxTextBorderStyle.OUTLINE,
			OUTLINE_FAST: flixel.text.FlxText.FlxTextBorderStyle.OUTLINE_FAST
		});
		set("FlxTextAlign", {
			CENTER: flixel.text.FlxText.FlxTextAlign.CENTER,
			JUSTIFY: flixel.text.FlxText.FlxTextAlign.JUSTIFY,
			LEFT: flixel.text.FlxText.FlxTextAlign.LEFT,
			RIGHT: flixel.text.FlxText.FlxTextAlign.RIGHT
		});
		set("setTxtFormat", function(txt:flixel.text.FlxText, ?Font:String, Size:Int = 8, Color:FlxColor = FlxColor.WHITE, ?Alignment:flixel.text.FlxText.FlxTextAlign, ?BorderStyle:flixel.text.FlxText.FlxTextBorderStyle, BorderColor:FlxColor = FlxColor.TRANSPARENT, EmbeddedFont:Bool = true){
			txt.setFormat(Font, Size, Color, Alignment, BorderStyle, BorderColor, EmbeddedFont);
		});
		set("FlxSound", FlxSound);
		set("FlxTimer", flixel.util.FlxTimer);
		set('FlxColor',HScriptColor);

		// set("FlxColor", { // same case as maps?
		// 	toRGBArray: function(color:FlxColor){return [color.red, color.green, color.blue];}, 
		// 	setHue: function(color:FlxColor, hue){
		// 		color.hue = hue;
		// 		return color;
		// 	},
		// 	setBrightness: function(color:FlxColor, brightness){
		// 		color.brightness = brightness;
		// 		return color;
		// 	},
		// 	setLightness: function(color:FlxColor, lightness){
		// 		color.lightness = lightness;
		// 		return color;
		// 	},

		// 	fromCMYK: FlxColor.fromCMYK,
		// 	fromHSL: FlxColor.fromHSL,
		// 	fromHSB: FlxColor.fromHSB,
		// 	fromInt: FlxColor.fromInt,
		// 	fromRGBFloat: FlxColor.fromRGBFloat,
		// 	fromString: FlxColor.fromString,
		// 	fromRGB: FlxColor.fromRGB
		// });
		set("FlxTween", FlxTween);
		set("FlxEase", FlxEase);
		set("FlxSave", flixel.util.FlxSave); // should probably give it 1 save instead of giving it FlxSave
		set("FlxBar", flixel.ui.FlxBar);
		set("FlxFlicker", flixel.effects.FlxFlicker);

		set("LEFT_TO_RIGHT", LEFT_TO_RIGHT);
		set("RIGHT_TO_LEFT", RIGHT_TO_LEFT);
		set("TOP_TO_BOTTOM", TOP_TO_BOTTOM);
		set("BOTTOM_TO_TOP", BOTTOM_TO_TOP);
		set("HORIZONTAL_INSIDE_OUT", HORIZONTAL_INSIDE_OUT);
		set("HORIZONTAL_OUTSIDE_IN", HORIZONTAL_OUTSIDE_IN);
		set("VERTICAL_INSIDE_OUT", VERTICAL_INSIDE_OUT);
		set("VERTICAL_OUTSIDE_IN", VERTICAL_OUTSIDE_IN);
		set("Bar", gameObjects.Bar);

		set("PsychVideoSprite",gameObjects.PsychVideoSprite);
		set("CutsceneHandler", meta.data.CutsceneHandler);

		#if HIT_SINGLE
		set('SuperStructureConnector',SuperStructureConnector);
		set("ConanLevel", meta.states.ConanLevel);
		set("Yoshi", gameObjects.Yoshi);
		set("KUTValueHandler", meta.states.KUTValueHandler);
		#end

		set("ShaderFilter", openfl.filters.ShaderFilter);
		set("ColorMatrixFilter", openfl.filters.ColorMatrixFilter);
		set("newColorMatrixFilter", (matrix:Array<Float>)->{
			return new openfl.filters.ColorMatrixFilter(matrix);
		});

		//super temp but im lazy for now
		set('ApplyFunkDistortionShaderToGame', ()->{
			@:privateAccess {
				var filter = new ShaderFilter(new FuckScorp());
				FlxG.game.setFilters([filter]);
			}
		});

		set('ApplyFunkDistortionShader', (cam:FlxCamera)->{
			@:privateAccess {
				if (cam._filters == null) cam._filters = [];
				var filter = new ShaderFilter(new FuckScorp());
				cam._filters.push(filter);
			}
		});

		set("FlxAxes", {
			X: flixel.util.FlxAxes.X,
			Y: flixel.util.FlxAxes.Y,
			XY: flixel.util.FlxAxes.XY
		});

		set("Dynamic", Dynamic);

		set("getClass", function(className:String)
		{
			return Type.resolveClass(className);
		});
		set("getEnum", function(enumName:String)
		{
			return Type.resolveEnum(enumName);
		});
		set("importClass", function(className:String)
		{
			// importClass("flixel.util.FlxSort") should give you FlxSort.byValues, etc
			// whereas importClass("scripts.Globals.*") should give you Function_Stop, Function_Continue, etc
			// i would LIKE to do like.. flixel.util.* but idk if I can get everything in a namespace
			var classSplit:Array<String> = className.split(".");
			var daClassName = classSplit[classSplit.length-1]; // last one
			if (daClassName == '*'){
				var daClass = Type.resolveClass(className);
				while(classSplit.length > 0 && daClass==null){
					daClassName = classSplit.pop();
					daClass = Type.resolveClass(classSplit.join("."));
					if(daClass!=null)break;
				}
				if(daClass!=null){
					for(field in Reflect.fields(daClass)){
						set(field, Reflect.field(daClass, field));
					}
				}else{
					FlxG.log.error('Could not import class ${daClass}');
					scriptTrace('Could not import class ${daClass}');
				}
			}else{
				var daClass = Type.resolveClass(className);
				set(daClassName, daClass);	
			}
		});
		set("addHaxeLibrary", function(libName:String, ?libPackage:String = ''){
			try{
				var str:String = '';
				if (libPackage.length > 0)
					str = libPackage + '.';

				set(libName, Type.resolveClass(str + libName));
			}
			catch (e:Dynamic){
				
			}
		}); 

		set("importEnum", function(enumName:String)
		{
			// same as importClass, but for enums
			// and it cant have enum.*;
			var splitted:Array<String> = enumName.split(".");
			var daEnum = Type.resolveClass(enumName);
			if (daEnum!=null)
				set(splitted.pop(), daEnum);
			
		});

		set("importScript", function(){
			// unimplemented lol
			throw new haxe.exceptions.NotImplementedException();
		});

		for(variable => arg in defaultVars){
			set(variable, arg);
		}

		// Util
		set("makeSprite", function(?x:Float, ?y:Float, ?image:String)
		{
			var spr = new FlxSprite(x, y);
			spr.antialiasing = ClientPrefs.globalAntialiasing;

			return image == null ? spr : spr.loadGraphic(Paths.image(image));
		});
		set("makeAnimatedSprite", function(?x:Float, ?y:Float, ?image:String, ?spriteType:String){
			var spr = new FlxSprite(x, y);
			spr.antialiasing = ClientPrefs.globalAntialiasing;

			if(image != null && image.length > 0){
				/*
				switch(spriteType)
				{
					case "texture" | "textureatlas" | "tex":
						spr.frames = AtlasFrameMaker.construct(image);
					case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
						spr.frames = AtlasFrameMaker.construct(image, null, true);
					case "packer" | "packeratlas" | "pac":
						spr.frames = Paths.getPackerAtlas(image);
					default:*/
						spr.frames = Paths.getSparrowAtlas(image);
				//}
			}

			return spr;
		});

		set("Main", Main);
		set("Lib", openfl.Lib);

		set("FlxRuntimeShader", FlxRuntimeShader);
		set("newShader", function(fragFile:String = null, vertFile:String = null){ // returns a FlxRuntimeShader but with file names lol
			var runtime:FlxRuntimeShader = null;

			try{				
				runtime = new FlxRuntimeShader(
					fragFile==null ? null : Paths.getContent(Paths.modsShaderFragment(fragFile)), 
					vertFile==null ? null : Paths.getContent(Paths.modsShaderVertex(vertFile))
				);
			}catch(e:Dynamic){
				trace("Shader compilation error:" + e.message);
			}

			return runtime==null ? new FlxRuntimeShader() : runtime;
		});

		// set("Shaders", gameObjects.shader.Shaders);
		for(i in 0...gameObjects.shader.Shaders.AllShaders.effectNames.length){
			set(gameObjects.shader.Shaders.AllShaders.effectNames[i], gameObjects.shader.Shaders.AllShaders.nameToEffect[i]);
		}

		@:privateAccess
		{
			var state:Any = flixel.FlxG.state;
			set("state", flixel.FlxG.state);

			if((state is PlayState) && state == PlayState.instance)
			{
				var state:PlayState = PlayState.instance;

				set("game", state);
				set("global", state.variables);
				set("getInstance", getInstance);

			}
			else if ((state is ChartingState) && state == ChartingState.instance){
				var state:ChartingState = ChartingState.instance;
				set("game", state);
				set("global", state.variables);
				set("getInstance", function()
				{
					return flixel.FlxG.state;
				});
			}else{
				set("game", null);
				set("global", null);
				set("getInstance", function(){
					return flixel.FlxG.state;
				});
			}
		}

		// FNF-specific things
		set("Paths", Paths);
		set("AttachedSprite", AttachedSprite);
		set("AttachedText", AttachedText);
		set("Conductor", Conductor);
		set("Note", Note);
		set("Song", Song);
		set("StrumNote", StrumNote);
		set("NoteSplash", NoteSplash);
		set("ClientPrefs", ClientPrefs);
		set("Alphabet", Alphabet);
		set("BGSprite", BGSprite);
		set("CoolUtil", CoolUtil);
		set("Character", Character);
		set("Boyfriend", Boyfriend);
		set("GradientBumpSprite", GradientBump);
		set("BackgroundDancer", gameObjects.BackgroundDancer);
		set("BackgroundGirls", gameObjects.BackgroundGirls);
		set("TankmenBG", gameObjects.TankmenBG);
		set("FNFSprite", gameObjects.FNFSprite);
		set("SubModifier", modchart.SubModifier);
		set("NoteModifier", modchart.NoteModifier);
		set("EventTimeline", modchart.EventTimeline);
		set("ModManager", modchart.ModManager);
		set("Modifier", modchart.Modifier);
		set("StepCallbackEvent", modchart.events.StepCallbackEvent);
		set("CallbackEvent", modchart.events.CallbackEvent);
		set("ModEvent", modchart.events.ModEvent);
		set("EaseEvent", modchart.events.EaseEvent);
		set("SetEvent", modchart.events.SetEvent);
		
		set("StageData", StageData);
		set("PlayState", PlayState);
		set("FunkinLua", FunkinLua);
		set("FunkinHScript", FunkinHScript);
		set("HScriptSubstate", HScriptSubstate);
		set("GameOverSubstate", meta.states.substate.GameOverSubstate);
		set("HealthIcon", HealthIcon);


		set("ScriptState", HScriptState);
		set("newScriptedState", function(stateName:String){
			return new HScriptState(fromFile(Paths.modFolders('states/$stateName.hscript')));
		});
		
		set("add", FlxG.state.add);
		set("remove", FlxG.state.remove);
		set("insert",FlxG.state.insert);
		set("members",FlxG.state.members);
		set('FlxSpriteUtil',flixel.util.FlxSpriteUtil);
		
		set('BlendMode',{
			SUBTRACT: BlendMode.SUBTRACT,
			ADD: BlendMode.ADD,
			MULTIPLY: BlendMode.MULTIPLY,
			ALPHA: BlendMode.ALPHA,
			DARKEN: BlendMode.DARKEN,
			DIFFERENCE: BlendMode.DIFFERENCE,
			INVERT: BlendMode.INVERT,
			HARDLIGHT: BlendMode.HARDLIGHT,
			LIGHTEN: BlendMode.LIGHTEN,
			OVERLAY: BlendMode.OVERLAY,
			SHADER: BlendMode.SHADER,
			SCREEN: BlendMode.SCREEN
		});

		set("addObjectBlend", function(shit:Dynamic, shit2:String){
			shit.blend = FunkinLua.blendModeFromString(shit2);
		});
		// set("buildStage", PlayState.instance.buildStage);
		
		if (additionalVars != null){
			for (key in additionalVars.keys())
				set(key, additionalVars.get(key));
		}

		trace('Loaded script ${scriptName}');
		try{
			interpreter.execute(parsed);
		}catch(e:haxe.Exception){
			trace('${scriptName}: '+ e.details());
			FlxG.log.error("Error running hscript: " + e.message);
		}
	}
	
	override public function stop(){
		// idk if there's really a stop function or anythin for hscript so
		if (interpreter != null && interpreter.variables != null)
			interpreter.variables.clear();
	
		interpreter = null;
	}

	override public function get(varName:String): Dynamic
	{
		return interpreter.variables.get(varName);
	}

	override public function set(varName:String, value:Dynamic):Void
	{
		interpreter.variables.set(varName, value);
	}

	public function exists(varName:String)
	{
		return interpreter.variables.exists(varName);
	}
	
	override public function call(func:String, ?parameters:Array<Dynamic>):Dynamic
	{
		var returnValue:Dynamic = executeFunc(func, parameters, this);
		if (returnValue == null)
			return Function_Continue;
		return returnValue;
	}

	public function executeFunc(func:String, ?parameters:Array<Dynamic>, ?theObject:Any, ?extraVars:Map<String,Dynamic>):Dynamic
	{
		if (extraVars == null)
			extraVars=[];
		if (exists(func))
		{
			var daFunc = get(func);
			if (Reflect.isFunction(daFunc))
			{
				var returnVal:Any = null;
				var defaultShit:Map<String,Dynamic>=[];
				if (theObject!=null)
					extraVars.set("this", theObject);
				
				for (key in extraVars.keys()){
					defaultShit.set(key, get(key));
					set(key, extraVars.get(key));
				}
				try
				{
					returnVal = Reflect.callMethod(theObject, daFunc, parameters);
				}
				catch (e:haxe.Exception)
				{
					#if sys
					Sys.println(e.message);
					#end
				}
				for (key in defaultShit.keys())
				{
					set(key, defaultShit.get(key));
				}
				return returnVal;
			}
		}
		return null;
	}
}

class HScriptSubstate extends meta.states.substate.MusicBeatSubstate
{
	public var script:FunkinHScript;

	public function new(ScriptName:String, ?additionalVars:Map<String, Any>)
	{
		super();

		var fileName = 'substates/$ScriptName.hx';


		for (filePath in [#if MODS_ALLOWED Paths.modFolders(fileName), Paths.mods(fileName), #end Paths.getPreloadPath(fileName)])
		{
			if (!FileSystem.exists(filePath)) continue;

			// some shortcuts
			var variables = new Map<String, Dynamic>();
			variables.set("this", this);
			variables.set("add", this.add);
			variables.set("remove", this.remove);
			variables.set("getControls", function(){ return controls;}); // i get it now
			variables.set("close", this.close);
			variables.set('members',this.members);
			variables.set('cameras',this.cameras);
			variables.set('insert',this.insert);


			if (additionalVars != null){
				for (key in additionalVars.keys())
					variables.set(key, additionalVars.get(key));
			}

			script = FunkinHScript.fromFile(filePath, variables);
			script.scriptName = ScriptName;
			break;
		}

		if (script == null){
			trace('Script file "$ScriptName" not found!');
			return close();
		}

		script.call("onLoad");
	}

	override function update(e:Float)
	{
		if (script.call("update", [e]) == Globals.Function_Stop)
			return; 
		
		super.update(e);
		script.call("updatePost", [e]);
	}

	override function close(){
		if (script != null)
			script.call("onClose");
		
		return super.close();
	}

	override function destroy()
	{
		if (script != null){
			script.call("onDestroy");
			script.stop();
		}
		script = null;

		return super.destroy();
	}
}

//flxsprite with some helpers for convenience
class HScriptSprite extends FlxSprite
{
	public function loadImage(path:String,?lib:String,anim:Bool = false,w:Int = 0,h:Int = 0,unique:Bool = false,?key:String) {
		this.loadGraphic(Paths.image(path,lib),anim,w,h,unique,key);
		return this;
	}

	public function loadFrames(path:String,?lib:String) {
		this.frames = Paths.getSparrowAtlas(path,lib);
		return this;
	}

	public function setScale(scaleX:Float,?scaleY:Float,updateHB:Bool = true) {
		scaleY = scaleY == null ? scaleX : scaleY;
		this.scale.set(scaleX,scaleY);
		if (updateHB) this.updateHitbox();
	}

	//why does old flixel only accept int for setGraphicSize
	public function updateGraphicSize(w:Float = 0,h:Float = 0,updateHB:Bool = true) 
	{
		if (w <= 0 && h <= 0)
			return this;

		var newScaleX:Float = w / this.frameWidth;
		var newScaleY:Float = h / this.frameHeight;
		this.scale.set(newScaleX, newScaleY);

		if (w <= 0)
			this.scale.x = newScaleY;
		else if (h <= 0)
			this.scale.y = newScaleX;

		if (updateHB) this.updateHitbox();
		return this;
	}

	public function centerOnSprite(spr:FlxSprite, axes:flixel.util.FlxAxes = XY)
	{
		if (axes.x)
			this.x = spr.x + (spr.width - this.width) / 2;

		if (axes.y)
			this.y = spr.y + (spr.height - this.height) / 2;
	}

	public function makeScaledGraphic(w:Float = 0,h:Float = 0,color:Int = FlxColor.WHITE,unique:Bool = false,?key:String = null) 
	{
		this.makeGraphic(1,1,color,unique,key);
		this.scale.set(w,h);
		this.updateHitbox();
		return this;
	}

	public function hide() 
	{
		this.alpha = 0.0000000001;
	}

	public function addAndPlay(name:String,prefix:String,fps:Int = 24,looped:Bool = true)
	{
		this.animation.addByPrefix(name,prefix,fps,looped);
		this.animation.play(name);
	}
		
}


//flxcolor but not a uhhh abstract so hscript can use it
class HScriptColor {
	public static var BLACK:Int = FlxColor.BLACK;
	public static var BLUE:Int = FlxColor.BLUE;
	public static var CYAN:Int = FlxColor.CYAN;
	public static var GRAY:Int = FlxColor.GRAY;
	public static var GREEN:Int = FlxColor.GREEN;
	public static var LIME:Int = FlxColor.LIME;
	public static var MAGENTA:Int = FlxColor.MAGENTA;
	public static var ORANGE:Int = FlxColor.ORANGE;
	public static var PINK:Int = FlxColor.PINK;
	public static var PURPLE:Int = FlxColor.PURPLE;
	public static var RED:Int = FlxColor.RED;
	public static var TRANSPARENT:Int = FlxColor.TRANSPARENT;
	public static var WHITE:Int = FlxColor.WHITE;
	public static var YELLOW:Int = FlxColor.YELLOW;

	public static function fromCMYK(c:Float,m:Float,y:Float,b:Float,a:Float = 1):Int return cast FlxColor.fromCMYK(c,m,y,b,a);
	public static function fromHSB(h:Float,s:Float,b:Float,a:Float = 1):Int return cast FlxColor.fromHSB(h,s,b,a);
	public static function fromInt(num:Int):Int return cast FlxColor.fromInt(num);
	public static function fromRGBFloat(r:Float,g:Float,b:Float,a:Float = 1):Int return cast FlxColor.fromRGBFloat(r,g,b,a);
	public static function fromRGB(r:Int,g:Int,b:Int,a:Int = 255):Int return cast FlxColor.fromRGB(r,g,b,a);
	public static function getHSBColorWheel(a:Int = 255):Array<Int> return cast FlxColor.getHSBColorWheel(a);
	public static function gradient(color1:FlxColor, color2:FlxColor, steps:Int, ?ease:Float->Float):Array<Int> return cast FlxColor.gradient(color1,color2,steps,ease);
	public static function interpolate(color1:FlxColor, color2:FlxColor, factor:Float = 0.5):Int return cast FlxColor.interpolate(color1,color2,factor);
	public static function fromString(string:String):Int return cast FlxColor.fromString(string);
}