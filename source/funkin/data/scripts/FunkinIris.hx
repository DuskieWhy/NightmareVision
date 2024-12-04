package funkin.data.scripts;

import funkin.data.scripts.FunkinScript;
import funkin.utils.MacroUtil;
import crowplexus.iris.IrisConfig;
import crowplexus.iris.Iris;
import funkin.objects.*;

class InterpEX extends crowplexus.hscript.Interp 
{
	override function makeIterator(v: Dynamic): Iterator<Dynamic> 
	{
		#if ((flash && !flash9) || (php && !php7 && haxe_ver < '4.0.0'))
		if (v.iterator != null)
			v = v.iterator();
		#else
		//DATA CHANGE //does a null check because this crashes on debug build
		if (v.iterator != null) try v = v.iterator() catch (e:Dynamic) {};
		#end
		if (v.hasNext == null || v.next == null)
			error(EInvalidIterator(v));
		return v;
	}
}




// thank you crow,neeo
// wrapper for an iris script to keep the consistency of the whole funkyscript setup this engine got
@:access(crowplexus.iris.Iris)
@:access(funkin.states.PlayState)
class FunkinIris extends FunkinScript
{
	public static final exts:Array<String> = ['hx', 'hxs', 'hscript', 'hxc'];

	public static function getPath(path:String, ?global:Bool = true)
	{
		for (extension in exts)
		{
			if (path.endsWith(extension)) return path;


			final file = '$path.$extension';

			for (i in [Paths.modFolders(file, global), Paths.getSharedPath(file)])
			{
				if (!FileSystem.exists(i)) continue;
				return i;
			}
		}
		return path;
	}

	public static function fromString(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>)
	{
		return new FunkinIris(script, name, additionalVars);
	}

	public static function fromFile(file:String, ?name:String, ?additionalVars:Map<String, Any>)
	{
		if (name == null) name = file;

		return new FunkinIris(File.getContent(file), name, additionalVars);
	}

	public static function InitLogger()
	{
		Iris.warn = (x, ?pos) -> {
			final message:String = '[${pos.fileName}]: WARN: ${pos.lineNumber} -> $x';
			PlayState.instance?.addTextToDebug(message, FlxColor.YELLOW);

			FlxG.log.warn(message);
			// trace(message);

			Iris.logLevel(ERROR, x, pos);
		}

		Iris.error = (x, ?pos) -> {
			final message:String = '[${pos.fileName}]: ERROR: ${pos.lineNumber} -> $x';
			PlayState.instance?.addTextToDebug(message, FlxColor.RED);

			FlxG.log.error(message);
			// trace(message);

			Iris.logLevel(NONE, x, pos);
		}

		Iris.print = (x, ?pos) -> {
			final message:String = '[${pos.fileName}]: TRACE: ${pos.lineNumber} -> $x';
			PlayState.instance?.addTextToDebug(message);

			// FlxG.log.add(message);

			// trace(message);

			Iris.logLevel(NONE, x, pos);
		}
	}

	public static var defaultVars:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var _script:Iris;

	public var parsingException:Null<String> = null;

	public function new(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>)
	{
		scriptType = ScriptType.HSCRIPT;
		scriptName = name;

		_script = new Iris(script, {name: name, autoRun: false, autoPreset: false});
		_script.interp = new InterpEX();
		_script.interp.showPosOnLog = false;

		setDefaultVars();

		if (additionalVars != null)
		{
			for (key => obj in additionalVars)
				set(key, additionalVars.get(obj));
		}

		tryExecute();
	}

	inline function tryExecute()
	{
		var ret:Dynamic = null;
		try
		{
			ret = _script.execute();
		}
		catch (e)
		{
			parsingException = Std.string(e);

			PlayState.instance?.addTextToDebug('[${scriptName}]: PARSING ERROR: $e', FlxColor.RED);
			trace("fialed to exucutue my willy! " + e);
		}
		return ret;
	}

	override function stop()
	{
		if (_script == null) return;

		_script.destroy();
		_script = null;
	}

	override function set(variable:String, data:Dynamic):Void
	{
		_script.set(variable, data);
	}

	override function get(key:String):Dynamic
	{
		return _script.get(key);
	}

	override function call(func:String, ?args:Array<Dynamic>):Dynamic
	{
		var ret:Dynamic = funkin.data.scripts.Globals.Function_Continue;
		if (exists(func)) ret = _script.call(func, args)?.returnValue ?? funkin.data.scripts.Globals.Function_Continue;

		return ret;
	}

	public function exists(varName:String)
	{
		return _script.exists(varName);
	}

	// kept for notescript stuff
	public function executeFunc(func:String, ?parameters:Array<Dynamic>, ?theObject:Any, ?extraVars:Map<String, Dynamic>):Dynamic
	{
		extraVars ??= [];

		if (exists(func))
		{
			var daFunc = get(func);
			if (Reflect.isFunction(daFunc))
			{
				var returnVal:Any = null;
				var defaultShit:Map<String, Dynamic> = [];

				if (theObject != null) extraVars.set("this", theObject);

				for (key in extraVars.keys())
				{
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

	override function setDefaultVars()
	{
		_script.preset();
		super.setDefaultVars();

		set("StringTools", StringTools);

		set("Type", Type);
		set("script", this);
		set("Dynamic", Dynamic);
		// set('Map',  MacroUtil.buildAbstract(Map));
		set('StringMap', haxe.ds.StringMap);
		set('IntMap', haxe.ds.IntMap);
		set('ObjectMap', haxe.ds.ObjectMap);

		set("Main", Main);
		set("Lib", openfl.Lib);
		set("Assets", lime.utils.Assets);
		set("OpenFlAssets", openfl.utils.Assets);

		set('Globals', funkin.data.scripts.Globals);

		set("FlxG", flixel.FlxG);
		set("FlxSprite", funkin.data.scripts.ScriptClasses.HScriptSprite);
		set("FlxTypedGroup", flixel.group.FlxGroup.FlxTypedGroup);
		set("FlxSpriteGroup", flixel.group.FlxSpriteGroup);
		set("FlxCamera", flixel.FlxCamera);
		set("FlxMath", flixel.math.FlxMath);
		set("FlxTimer", flixel.util.FlxTimer);
		set("FlxTween", flixel.tweens.FlxTween);
		set("FlxEase", flixel.tweens.FlxEase);
		set("FlxSound", flixel.sound.FlxSound);
		set('FlxColor', funkin.data.scripts.ScriptClasses.HScriptColor);
		set("FlxRuntimeShader", flixel.addons.display.FlxRuntimeShader);
		set("FlxFlicker", flixel.effects.FlxFlicker);
		set('FlxSpriteUtil', flixel.util.FlxSpriteUtil);
		set('AnimateSprite', flxanimate.AnimateSprite);
		set("FlxBackdrop", flixel.addons.display.FlxBackdrop);
		set("FlxTiledSprite", flixel.addons.display.FlxTiledSprite);

		set("add", FlxG.state.add);
		set("remove", FlxG.state.remove);
		set("insert", FlxG.state.insert);
		set("members", FlxG.state.members);

		set('FlxCameraFollowStyle', flixel.FlxCamera.FlxCameraFollowStyle);
		set("FlxTextBorderStyle", flixel.text.FlxText.FlxTextBorderStyle);
		set("FlxBarFillDirection", flixel.ui.FlxBar.FlxBarFillDirection);

		// abstracts
		set("FlxTextAlign", MacroUtil.buildAbstract(flixel.text.FlxText.FlxTextAlign));
		set('FlxAxes', MacroUtil.buildAbstract(flixel.util.FlxAxes));
		set('BlendMode', MacroUtil.buildAbstract(openfl.display.BlendMode));
		set("FlxKey", MacroUtil.buildAbstract(flixel.input.keyboard.FlxKey));

		set('FlxPoint', flixel.math.FlxPoint.FlxBasePoint); // redirects to flxbasepoint because thats all flxpoints are
		set("FlxBasePoint", flixel.math.FlxPoint.FlxBasePoint);

		// modchart related
		set("ModManager", funkin.modchart.ModManager);
		set("SubModifier", funkin.modchart.SubModifier);
		set("NoteModifier", funkin.modchart.NoteModifier);
		set("EventTimeline", funkin.modchart.EventTimeline);
		set("Modifier", funkin.modchart.Modifier);
		set("StepCallbackEvent", funkin.modchart.events.StepCallbackEvent);
		set("CallbackEvent", funkin.modchart.events.CallbackEvent);
		set("ModEvent", funkin.modchart.events.ModEvent);
		set("EaseEvent", funkin.modchart.events.EaseEvent);
		set("SetEvent", funkin.modchart.events.SetEvent);

		// FNF-specific things
		set("MusicBeatState", funkin.backend.MusicBeatState);
		set("Paths", Paths);
		set("Conductor", Conductor);
		set("Song", Song);
		set("ClientPrefs", ClientPrefs);
		set("CoolUtil", CoolUtil);
		set("StageData", StageData);
		set("PlayState", PlayState);
		set("FunkinLua", FunkinLua);
		set("FunkinIris", FunkinIris);

		set('WindowUtil', funkin.utils.WindowUtil); // temp till i fix some shit

		// FNF-specific things
		set("MusicBeatState", funkin.backend.MusicBeatState);
		set("Paths", Paths);
		set("Conductor", Conductor);
		set("Song", Song);
		set("ClientPrefs", ClientPrefs);
		set("CoolUtil", CoolUtil);
		set("StageData", StageData);
		set("PlayState", PlayState);
		set("FunkinLua", FunkinLua);

		// objects
		set("Note", Note);
		set("Bar", funkin.objects.Bar);
		set("FunkinVideoSprite", funkin.objects.video.FunkinVideoSprite);
		set("BackgroundDancer", funkin.objects.stageobjects.BackgroundDancer);
		set("BackgroundGirls", funkin.objects.stageobjects.BackgroundGirls);
		set("TankmenBG", funkin.objects.stageobjects.TankmenBG);
		set("FNFSprite", funkin.objects.FNFSprite);
		set("HealthIcon", HealthIcon);
		set("Character", Character);
		set("NoteSplash", NoteSplash);
		set("BGSprite", BGSprite);
		set('SpriteFromSheet', SpriteFromSheet);
		set("StrumNote", StrumNote);
		set("Alphabet", Alphabet);
		set("AttachedSprite", AttachedSprite);
		set("AttachedText", AttachedText);

		set("CutsceneHandler", funkin.backend.CutsceneHandler);

		// modchart related
		set("ModManager", funkin.modchart.ModManager);
		set("SubModifier", funkin.modchart.SubModifier);
		set("NoteModifier", funkin.modchart.NoteModifier);
		set("EventTimeline", funkin.modchart.EventTimeline);
		set("Modifier", funkin.modchart.Modifier);
		set("StepCallbackEvent", funkin.modchart.events.StepCallbackEvent);
		set("CallbackEvent", funkin.modchart.events.CallbackEvent);
		set("ModEvent", funkin.modchart.events.ModEvent);
		set("EaseEvent", funkin.modchart.events.EaseEvent);
		set("SetEvent", funkin.modchart.events.SetEvent);

		set("GameOverSubstate", funkin.states.substates.GameOverSubstate);
		set("GameOverVideoSubstate", funkin.states.substates.GameOverVideoSubstate);

		if ((FlxG.state is PlayState) && PlayState.instance != null)
		{
			final state:PlayState = PlayState.instance;

			set("game", state);
			set("global", state.variables);
			set("getInstance", funkin.data.scripts.Globals.getInstance);

			// why is ther hscriptglobals and variables when they achieve the same thign maybe kill off one or smth
			set('setGlobalFunc', (name:String, func:Dynamic) -> state.variables.set(name, func));
			set('callGlobalFunc', (name:String, ?args:Dynamic) -> {
				if (state.variables.exists(name)) return state.variables.get(name)(args);
				else return null;
			});
		}

		// todo rework this
		set("newShader", function(fragFile:String = null, vertFile:String = null) { // returns a FlxRuntimeShader but with file names lol
			var runtime:flixel.addons.display.FlxRuntimeShader = null;

			try
			{
				runtime = new flixel.addons.display.FlxRuntimeShader(fragFile == null ? null : Paths.getContent(Paths.modsShaderFragment(fragFile)),
					vertFile == null ? null : Paths.getContent(Paths.modsShaderVertex(vertFile)));
			}
			catch (e:Dynamic)
			{
				trace("Shader compilation error:" + e.message);
			}

			return runtime ?? new flixel.addons.display.FlxRuntimeShader();
		});
	}
}
