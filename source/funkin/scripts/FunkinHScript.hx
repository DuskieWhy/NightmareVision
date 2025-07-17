package funkin.scripts;

import crowplexus.iris.Iris;

import extensions.InterpEx;

import funkin.backend.plugins.DebugTextPlugin;
import funkin.objects.*;

// wrapper for an iris script to keep the consistency of the whole funkyscript setup this engine got
// will be replaced later when im not lazy
@:access(crowplexus.iris.Iris)
@:access(funkin.states.PlayState)
class FunkinHScript extends Iris implements IFlxDestroyable
{
	/**
	 * List of all accepted hscript extensions
	 */
	public static final H_EXTS:Array<String> = ['hx', 'hxs', 'hscript'];
	
	public static function getPath(path:String)
	{
		for (extension in H_EXTS)
		{
			if (path.endsWith(extension)) return path;
			
			final file = '$path.$extension';
			
			final targetPath = Paths.getPath(file, TEXT, null, true);
			if (FunkinAssets.exists(targetPath)) return targetPath;
		}
		return path;
	}
	
	/**
	 * Initiates the debugging backend of Iris
	 */
	public static function init()
	{
		Iris.warn = (x, ?pos) -> {
			final output:String = '[${pos.fileName}]: WARN: ${pos.lineNumber} -> $x';
			
			DebugTextPlugin.addText(Std.string(output), Logger.getHexColourFromSeverity(WARN));
			
			Iris.logLevel(ERROR, x, pos);
		}
		
		Iris.error = (x, ?pos) -> {
			final output:String = '[${pos.fileName}]: ERROR: ${pos.lineNumber} -> $x';
			
			DebugTextPlugin.addText(Std.string(output), Logger.getHexColourFromSeverity(ERROR));
			
			Iris.logLevel(NONE, x, pos);
		}
		
		Iris.print = (x, ?pos) -> {
			final output:String = '[${pos.fileName}]: TRACE: ${pos.lineNumber} -> $x';
			
			DebugTextPlugin.addText(Std.string(output), Logger.getHexColourFromSeverity(PRINT));
			
			Iris.logLevel(NONE, x, pos);
		}
	}
	
	/**
	 * Creates a new `FunkinHScript` from a string
	 * @param script 
	 * @param name 
	 * @param additionalVars 
	 */
	public static function fromString(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>)
	{
		return new FunkinHScript(script, name, additionalVars);
	}
	
	/**
	 * Creates a new `FunkinHScript` from a filepath
	 * 
	 * @param file 
	 * @param name 
	 * @param additionalVars 
	 */
	public static function fromFile(file:String, ?name:String, ?additionalVars:Map<String, Any>)
	{
		name ??= file;
		
		return new FunkinHScript(FunkinAssets.getContent(file), name, additionalVars);
	}
	
	/**
	 * is true if parsing failed
	 */
	@:noCompletion public var __garbage:Bool = false;
	
	public function new(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>)
	{
		super(script, {name: name, autoRun: false, autoPreset: false});
		
		interp = new InterpEx(FlxG.state);
		
		preset();
		
		if (additionalVars != null)
		{
			for (key => obj in additionalVars)
				set(key, additionalVars.get(obj));
		}
		
		tryExecute();
	}
	
	/**
	 * safer parsing
	 */
	inline function tryExecute()
	{
		var ret:Dynamic = null;
		try
		{
			ret = execute();
		}
		catch (e)
		{
			__garbage = true;
			Logger.log('[${name}]: PARSING ERROR: $e', ERROR, true);
		}
		return ret;
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
	
	@:inheritDoc
	override function preset()
	{
		super.preset();
		
		var currentState = flixel.FlxG.state;
		if ((currentState is PlayState))
		{
			set("inPlaystate", true);
			set('bpm', PlayState.SONG.bpm);
			set('scrollSpeed', PlayState.SONG.speed);
			set('songName', PlayState.SONG.song);
			set('isStoryMode', PlayState.isStoryMode);
			set('difficulty', PlayState.storyDifficulty);
			set('weekRaw', PlayState.storyWeek);
			set('seenCutscene', PlayState.seenCutscene);
			set('week', funkin.data.WeekData.weeksList[PlayState.storyWeek]);
			set('difficultyName', funkin.backend.Difficulty.difficulties[PlayState.storyDifficulty]);
			set('songLength', flixel.FlxG.sound.music.length);
			set('healthGainMult', PlayState.instance.healthGain);
			set('healthLossMult', PlayState.instance.healthLoss);
			set('instakillOnMiss', PlayState.instance.instakillOnMiss);
			set('botPlay', PlayState.instance.cpuControlled);
			set('practice', PlayState.instance.practiceMode);
			set('startedCountdown', false);
		}
		else
		{
			set("inPlaystate", false);
		}
		
		set('inGameOver', false);
		set('downscroll', ClientPrefs.downScroll);
		set('middlescroll', ClientPrefs.middleScroll);
		set('framerate', ClientPrefs.framerate);
		set('ghostTapping', ClientPrefs.ghostTapping);
		set('hideHud', ClientPrefs.hideHud);
		set('timeBarType', ClientPrefs.timeBarType);
		set('scoreZoom', ClientPrefs.scoreZoom);
		set('cameraZoomOnBeat', ClientPrefs.camZooms);
		set('flashingLights', ClientPrefs.flashing);
		set('noteOffset', ClientPrefs.noteOffset);
		set('healthBarAlpha', ClientPrefs.healthBarAlpha);
		set('noResetButton', ClientPrefs.noReset);
		set('lowQuality', ClientPrefs.lowQuality);
		set("scriptName", name);
		
		set('curBpm', Conductor.bpm);
		set('crotchet', Conductor.crotchet);
		set('stepCrotchet', Conductor.stepCrotchet);
		set('Function_Halt', Globals.Function_Halt);
		set('Function_Stop', Globals.Function_Stop);
		set('Function_Continue', Globals.Function_Continue);
		set('curBeat', 0);
		set('curStep', 0);
		set('curSection', 0);
		set('curDecBeat', 0);
		set('curDecStep', 0);
		set('version', Main.NMV_VERSION.trim());
		
		set("StringTools", StringTools);
		
		set("Type", Type);
		set("script", this);
		set("Dynamic", Dynamic);
		
		set('StringMap', haxe.ds.StringMap);
		set('IntMap', haxe.ds.IntMap);
		set('ObjectMap', haxe.ds.ObjectMap);
		
		set("Main", Main);
		set("Lib", openfl.Lib);
		set("Assets", lime.utils.Assets);
		set("OpenFlAssets", openfl.utils.Assets);
		
		// set flixel related stuff
		set("FlxG", flixel.FlxG);
		set("FlxSprite", flixel.FlxSprite);
		set("FlxTypedGroup", flixel.group.FlxGroup.FlxTypedGroup);
		set("FlxSpriteGroup", flixel.group.FlxSpriteGroup);
		set("FlxCamera", flixel.FlxCamera);
		set("FlxMath", flixel.math.FlxMath);
		set("FlxTimer", flixel.util.FlxTimer);
		set("FlxTween", flixel.tweens.FlxTween);
		set("FlxEase", flixel.tweens.FlxEase);
		set("FlxSound", flixel.sound.FlxSound);
		set('FlxColor', funkin.scripts.ScriptClasses.HScriptColor);
		set("FlxRuntimeShader", funkin.backend.FunkinShader.FunkinRuntimeShader);
		set("FlxFlicker", flixel.effects.FlxFlicker);
		set('FlxSpriteUtil', flixel.util.FlxSpriteUtil);
		set('AnimateSprite', flxanimate.AnimateSprite);
		set("FlxBackdrop", flixel.addons.display.FlxBackdrop);
		set("FlxTiledSprite", flixel.addons.display.FlxTiledSprite);
		set('FlxPoint', flixel.math.FlxPoint.FlxBasePoint);
		
		set('FlxCameraFollowStyle', flixel.FlxCamera.FlxCameraFollowStyle);
		set("FlxTextBorderStyle", flixel.text.FlxText.FlxTextBorderStyle);
		set("FlxBarFillDirection", flixel.ui.FlxBar.FlxBarFillDirection);
		
		// abstracts
		set("FlxTextAlign", funkin.utils.MacroUtil.buildAbstract(flixel.text.FlxText.FlxTextAlign));
		set('FlxAxes', funkin.utils.MacroUtil.buildAbstract(flixel.util.FlxAxes));
		set("FlxKey", funkin.utils.MacroUtil.buildAbstract(flixel.input.keyboard.FlxKey));
		set('BlendMode', funkin.utils.MacroUtil.buildAbstract(openfl.display.BlendMode));
		
		// modchart related
		set("ModManager", funkin.game.modchart.ModManager);
		set("SubModifier", funkin.game.modchart.SubModifier);
		set("NoteModifier", funkin.game.modchart.NoteModifier);
		set("EventTimeline", funkin.game.modchart.EventTimeline);
		set("Modifier", funkin.game.modchart.Modifier);
		set("StepCallbackEvent", funkin.game.modchart.events.StepCallbackEvent);
		set("CallbackEvent", funkin.game.modchart.events.CallbackEvent);
		set("ModEvent", funkin.game.modchart.events.ModEvent);
		set("EaseEvent", funkin.game.modchart.events.EaseEvent);
		set("SetEvent", funkin.game.modchart.events.SetEvent);
		
		// FNF-specific things
		set("MusicBeatState", funkin.backend.MusicBeatState);
		set("Paths", Paths);
		set("Conductor", funkin.data.Conductor);
		set("Song", funkin.data.Song);
		set("ClientPrefs", funkin.data.ClientPrefs);
		set("CoolUtil", funkin.utils.CoolUtil);
		set("StageData", funkin.data.StageData);
		set("PlayState", PlayState);
		set("FunkinHScript", FunkinHScript);
		set('WindowUtil', funkin.utils.WindowUtil); // temp till i fix some shit
		set('Globals', funkin.scripts.Globals);
		
		set('HScriptState', funkin.scripting.HScriptState);
		set('HScriptSubstate', funkin.scripting.HScriptSubstate);
		
		// objects
		set("Note", funkin.objects.Note);
		set("Bar", funkin.objects.Bar);
		#if VIDEOS_ALLOWED
		set("FunkinVideoSprite", funkin.video.FunkinVideoSprite);
		#end
		set("BackgroundDancer", funkin.objects.stageobjects.BackgroundDancer);
		set("BackgroundGirls", funkin.objects.stageobjects.BackgroundGirls);
		set("TankmenBG", funkin.objects.stageobjects.TankmenBG);
		set("FNFSprite", funkin.objects.FNFSprite);
		set("HealthIcon", HealthIcon);
		set("Character", funkin.objects.character.Character);
		set("NoteSplash", NoteSplash);
		set("BGSprite", BGSprite);
		set("StrumNote", StrumNote);
		set("Alphabet", Alphabet);
		set("AttachedSprite", AttachedSprite);
		set("AttachedAlphabet", AttachedAlphabet);
		
		set("CutsceneHandler", funkin.objects.CutsceneHandler);
		set('DialogueBox', funkin.objects.DialogueBox);
		
		// modchart related
		set("ModManager", funkin.game.modchart.ModManager);
		set("SubModifier", funkin.game.modchart.SubModifier);
		set("NoteModifier", funkin.game.modchart.NoteModifier);
		set("EventTimeline", funkin.game.modchart.EventTimeline);
		set("Modifier", funkin.game.modchart.Modifier);
		set("StepCallbackEvent", funkin.game.modchart.events.StepCallbackEvent);
		set("CallbackEvent", funkin.game.modchart.events.CallbackEvent);
		set("ModEvent", funkin.game.modchart.events.ModEvent);
		set("EaseEvent", funkin.game.modchart.events.EaseEvent);
		set("SetEvent", funkin.game.modchart.events.SetEvent);
		
		set("GameOverSubstate", funkin.states.substates.GameOverSubstate);
		
		if ((FlxG.state is PlayState) && PlayState.instance != null)
		{
			final state:PlayState = PlayState.instance;
			
			set("game", state);
			set("global", state.variables);
			set("getInstance", funkin.scripts.Globals.getInstance);
			
			set('setVar', (varName:String, val:Dynamic) -> state.variables.set(varName, val));
			set('getVar', (varName:String) -> state.variables.get(varName));
		}
		
		set("newShader", (?fragFile:String, ?vertFile:String) -> {
			var fragPath = fragFile != null ? Paths.shaderFrag(fragFile) : null;
			var vertPath = vertFile != null ? Paths.shaderVert(vertFile) : null;
			
			if (fragPath != null)
			{
				if (FunkinAssets.exists(fragPath)) fragPath = FunkinAssets.getContent(fragPath);
			}
			
			if (vertPath != null)
			{
				if (FunkinAssets.exists(vertPath)) vertPath = FunkinAssets.getContent(vertPath);
			}
			
			return new funkin.backend.FunkinShader.FunkinRuntimeShader(fragPath, vertPath);
		});
	}
}
