package funkin.scripts;

import extensions.hscript.InsanityInterpEx;

import insanity.Config;
import insanity.backend.Interp;
import insanity.backend.Expr;

import haxe.Exception;

import insanity.Script;

import extensions.hscript.Sharables;

import funkin.backend.plugins.DebugTextPlugin;
import funkin.objects.*;
import funkin.objects.note.*;

@:access(crowplexus.iris.Iris)
@:access(funkin.states.PlayState)
class FunkinScript extends Script implements IFlxDestroyable
{
	/**
	 * List of all accepted hscript extensions
	 */
	public static final H_EXTS:Array<String> = ['hx', 'hxs', 'hscript'];
	
	/**
	 * wrapper for `Paths.getPath` but attempts to append a supported hx extension to its path
	 * @param path 
	 * @return String
	 */
	public static function getPath(path:String):String
	{
		for (extension in H_EXTS)
		{
			final file = '$path.$extension';
			
			final targetPath = Paths.getPath(file, null, true);
			if (FunkinAssets.exists(targetPath)) return targetPath;
			if (FunkinAssets.exists(file)) return file;
		}
		return path;
	}
	
	/**
	 * Helper to check if a path ends with a support hx extension
	 */
	public static function isHxFile(path:String):Bool
	{
		for (extension in H_EXTS)
			if (path.endsWith(extension)) return true;
			
		return false;
	}
	
	/**
	 * Initiates the debugging backend of Iris
	 */
	public static function init()
	{
		/*
			Iris.warn = (x, ?pos) -> {
				final output:String = '[${pos.fileName}:${pos.lineNumber}]: $x';
				
				DebugTextPlugin.addText(Std.string(output), Logger.getHexColourFromSeverity(WARN));
				
				Iris.logLevel(ERROR, x, pos);
			}

			Iris.error = (x, ?pos) -> {
				final output:String = '[${pos.fileName}:${pos.lineNumber}]: $x';
				
				DebugTextPlugin.addText(Std.string(output), Logger.getHexColourFromSeverity(ERROR));
				
				Iris.logLevel(NONE, x, pos);
			}

			Iris.print = (x, ?pos) -> {
				final output:String = '[${pos.fileName}:${pos.lineNumber}]: $x';
				
				DebugTextPlugin.addText(Std.string(output), Logger.getHexColourFromSeverity(PRINT));
				
				Iris.logLevel(NONE, x, pos);
			}
		 */
		
		Config.interpClass = InsanityInterpEx;
		Config.preprocessorValues; // idea: maybe implement some nmv specific preprocessors? ex: version, deprecation fields, etc.
	}
	
	/**
	 * Creates a new `FunkinScript` from a string
	 * @param script 
	 * @param name 
	 * @param additionalVars 
	 */
	public static function fromString(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>, ?shareables:Sharables)
	{
		return new FunkinScript(script, name, additionalVars, shareables);
	}
	
	/**
	 * Creates a new `FunkinScript` from a filepath
	 * 
	 * @param file 
	 * @param name 
	 * @param additionalVars 
	 */
	public static function fromFile(file:String, ?name:String, ?additionalVars:Map<String, Any>, ?shareables:Sharables)
	{
		name ??= file;
		
		return new FunkinScript(FunkinAssets.getContent(file), name, additionalVars, shareables);
	}
	
	/**
	 * is true if parsing failed
	 */
	@:noCompletion public var __garbage:Bool = false;
	
	// an attempt to redoing parent variables!
	@:isVar
	public var parent(get, set):Dynamic;
	
	@:isVar
	public var sharables(get, set):Sharables;
	
	public function new(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>, ?shareables:Sharables, ?autoStart:Bool = true)
	{
		super(script, name ?? 'unknown');
		
		if (additionalVars != null)
		{
			for (key => value in additionalVars)
			{
				set(key, additionalVars.get(value));
			}
		}
		
		this.parent = FlxG.state;
		
		if (autoStart)
		{
			start();
		}
	}
	
	public function getInterp():InsanityInterpEx
	{
		if (interp != null) return cast(interp, InsanityInterpEx);
		return null;
	}
	
	override function parse(string:String):Expr
	{
		try
		{
			parser.resumeErrors = true;
			program = parser.parseScript(string, name);
		}
		catch (e:haxe.Exception)
		{
			onParsingError(e);
			program = null;
		}
		
		return program;
	}
	
	override function start(?expr:Expr):Any
	{
		try
		{
			if (program == null) throw 'Program is uninitialized';
			
			failed = false;
			
			setDefaults();
			
			if (interp.environment != null)
			{
				for (k => v in interp.environment.variables)
					if (!variables.exists(k)) variables.set(k, v);
			}
			
			return interp.execute(program);
		}
		catch (e:haxe.Exception)
		{
			onProgramError(e);
			failed = true;
			__garbage = true; // this is here entirely for compat reasons. this may also fix a thing or two?
		}
		
		return null;
	}
	
	override function onProgramError(e:Exception)
	{
		Logger.log('An error has occurred in script ${this.name}\n${e.details()}', ERROR, true);
	}
	
	override function onParsingError(e:Exception)
	{
		Logger.log('A parsing error has occurred in script ${this.name}\n${e.details()}', ERROR, true);
	}
	
	public function set(variable:String, value:Dynamic)
	{
		getInterp().variables?.set(variable, value);
	}
	
	public function get(variable:String)
	{
		return getInterp().variables?.get(variable) ?? null;
	}
	
	public function exists(variable:String)
	{
		return getInterp().variables?.exists(variable) ?? false;
	}
	
	override function call(variable:String, ?args:Array<Dynamic>):Any
	{
		if (interp == null) throw 'Interpreter is uninitialized';
		
		var fun = (getInterp().variables.exists(variable) ? getInterp().variables.get(variable) : getInterp().getGlobal(variable, true));
		
		if (!Reflect.isFunction(fun))
		{
			Logger.log('$variable isn\'t a function', WARN);
			return null;
		}
		
		return Reflect.callMethod(interp, fun, args ?? []);
	}
	
	// kept for notescript stuff
	// I did not put jackshit effort into reimplementing this function - TG
	public function executeFunc(func:String, ?parameters:Array<Dynamic>, ?theObject:Any, ?extraVars:Map<String, Dynamic>):Dynamic
	{
		extraVars ??= [];
		
		if (!exists(func))
		{
			Logger.log('Function $func doesn\'t exist in ${this.name}!', WARN);
			return null;
		}
		
		return call(func, parameters ?? []);
	}
	
	override function setDefaults()
	{
		super.setDefaults();
		
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
		
		set('curBpm', Conductor.bpm);
		set('crotchet', Conductor.crotchet);
		set('stepCrotchet', Conductor.stepCrotchet);
		set('Function_Halt', funkin.scripting.ScriptConstants.HALT_FUNC);
		set('Function_Stop', funkin.scripting.ScriptConstants.STOP_FUNC);
		set('Function_Continue', funkin.scripting.ScriptConstants.CONTINUE_FUNC);
		set('curBeat', 0);
		set('curStep', 0);
		set('curSection', 0);
		set('curDecBeat', 0);
		set('curDecStep', 0);
		set('version', Main.NMV_VERSION.trim());
		set('Defines', funkin.data.Defines);
		
		// set flixel related stuff
		set("FlxG", flixel.FlxG);
		set("FlxSprite", flixel.FlxSprite);
		set("FlxCamera", extensions.flixel.FlxCameraEx);
		set("FlxMath", flixel.math.FlxMath);
		set("FlxTimer", flixel.util.FlxTimer);
		set("FlxTween", flixel.tweens.FlxTween);
		set("FlxEase", flixel.tweens.FlxEase);
		set("FlxSound", flixel.sound.FlxSound);
		set('FlxText', flixel.text.FlxText);
		set("FlxRuntimeShader", funkin.backend.FunkinShader.FunkinRuntimeShader);
		set("FlxFlicker", flixel.effects.FlxFlicker);
		set('FlxSpriteUtil', flixel.util.FlxSpriteUtil);
		set("FlxBackdrop", flixel.addons.display.FlxBackdrop);
		set("FlxTiledSprite", flixel.addons.display.FlxTiledSprite);
		set('FlxPoint', flixel.math.FlxPoint.FlxBasePoint);
		
		set("FlxTypedGroup", flixel.group.FlxGroup);
		set("FlxSpriteGroup", flixel.group.FlxSpriteGroup);
		set("FlxEmitter", flixel.effects.particles.FlxEmitter);
		
		set('FlxCameraFollowStyle', flixel.FlxCamera.FlxCameraFollowStyle);
		set("FlxTextBorderStyle", flixel.text.FlxText.FlxTextBorderStyle);
		set("FlxBarFillDirection", flixel.ui.FlxBar.FlxBarFillDirection);
		
		set("FlxAnimate", animate.FlxAnimate);
		set("FlxAnimateFrames", animate.FlxAnimateFrames);
		set("FlxSpriteElement", animate.internal.elements.FlxSpriteElement);
		
		set('Controls', funkin.backend.Controls);
		
		// abstracts
		set("FlxTextAlign", funkin.utils.MacroUtil.buildAbstract(flixel.text.FlxText.FlxTextAlign));
		set('FlxAxes', funkin.utils.MacroUtil.buildAbstract(flixel.util.FlxAxes));
		set("FlxKey", funkin.utils.MacroUtil.buildAbstract(flixel.input.keyboard.FlxKey));
		set('BlendMode', funkin.utils.MacroUtil.buildAbstract(openfl.display.BlendMode));
		
		set("keyToString", (key:Int) -> {
			return flixel.input.keyboard.FlxKey.toStringMap.get(key);
		});
		set("keyFromString", (str:String) -> {
			return flixel.input.keyboard.FlxKey.fromStringMap.get(str);
		});
		
		// modchart related
		set("ModManager", funkin.game.modchart.ModManager);
		set("SubModifier", funkin.game.modchart.SubModifier);
		set("NoteModifier", funkin.game.modchart.NoteModifier);
		set("ScriptedModifier", funkin.game.modchart.ScriptedModifier);
		set("EventTimeline", funkin.game.modchart.EventTimeline);
		set("Modifier", funkin.game.modchart.Modifier);
		set("StepCallbackEvent", funkin.game.modchart.events.StepCallbackEvent);
		set("CallbackEvent", funkin.game.modchart.events.CallbackEvent);
		set("ModEvent", funkin.game.modchart.events.ModEvent);
		set("EaseEvent", funkin.game.modchart.events.EaseEvent);
		set("SetEvent", funkin.game.modchart.events.SetEvent);
		
		// FNF-specific things
		set("Paths", Paths);
		set("MusicBeatState", funkin.backend.MusicBeatState);
		set("Conductor", funkin.backend.Conductor);
		set("ClientPrefs", funkin.data.ClientPrefs);
		set("CoolUtil", funkin.utils.CoolUtil);
		set('WindowUtil', funkin.utils.WindowUtil);
		
		set("StageData", funkin.data.StageData);
		set("PlayState", PlayState);
		set('FunkinSound', funkin.audio.FunkinSound);
		
		// custom
		set('FlxColor', funkin.scripts.ScriptClasses.ScriptedFlxColor);
		set('Random', funkin.scripts.ScriptClasses.ScriptedFlxRandom);
		
		// script
		set("FunkinScript", FunkinScript);
		set('ScriptConstants', funkin.scripting.ScriptConstants);
		
		// for compat
		set('HScriptState', funkin.scripting.ScriptedState);
		set('HScriptSubstate', funkin.scripting.ScriptedSubstate);
		
		set('ScriptedState', funkin.scripting.ScriptedState);
		set('ScriptedSubstate', funkin.scripting.ScriptedSubstate);
		
		set("GameOverSubstate", funkin.states.substates.GameOverSubstate);
		
		// objects
		set("Note", funkin.objects.note.Note);
		set("Bar", funkin.objects.Bar);
		#if VIDEOS_ALLOWED
		set("FunkinVideoSprite", funkin.video.FunkinVideoSprite);
		#end
		set("BackgroundDancer", funkin.objects.stageobjects.BackgroundDancer);
		set("BackgroundGirls", funkin.objects.stageobjects.BackgroundGirls);
		set("HealthIcon", HealthIcon);
		set("Character", funkin.objects.Character);
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
		
		set('inGameOver', false);
		
		set("game", FlxG.state);
		
		if ((FlxG.state is PlayState))
		{
			set("inPlaystate", true);
			set('bpm', PlayState.SONG.bpm);
			set('scrollSpeed', PlayState.SONG.speed);
			set('songName', PlayState.SONG.song);
			set('isStoryMode', PlayState.isStoryMode);
			set('difficulty', PlayState.storyMeta.difficulty);
			set('weekRaw', PlayState.storyMeta.curWeek);
			set('seenCutscene', PlayState.seenCutscene);
			set('week', funkin.data.WeekData.weeksList[PlayState.storyMeta.curWeek]);
			set('difficultyName', funkin.backend.Difficulty.difficulties[PlayState.storyMeta.difficulty]);
			set('songLength', FlxG.sound.music.length);
			set('healthGainMult', PlayState.instance.healthGain);
			set('healthLossMult', PlayState.instance.healthLoss);
			set('instakillOnMiss', PlayState.instance.instakillOnMiss);
			set('botPlay', PlayState.instance.cpuControlled);
			set('practice', PlayState.instance.practiceMode);
			set('startedCountdown', false);
			set('mustHitSection', PlayState.SONG?.notes[0]?.mustHitSection ?? false);
			
			set("global", PlayState.instance.variables);
			set("getInstance", funkin.scripting.ScriptConstants.getInstance);
			
			set('setVar', (varName:String, val:Dynamic) -> PlayState.instance.variables.set(varName, val));
			set('getVar', (varName:String) -> PlayState.instance.variables.get(varName));
			
			set('initScript', (path:String) -> {
				path = FunkinScript.getPath(path);
				if (!PlayState.instance.scripts.exists(path)) PlayState.instance.initFunkinScript(path);
			});
		}
		else
		{
			set("inPlaystate", false);
		}
		
		set("newShader", (?fragFile:String, ?vertFile:String) -> {
			var fragPath = fragFile != null ? Paths.fragment(fragFile) : null;
			var vertPath = vertFile != null ? Paths.vertex(vertFile) : null;
			
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
	
	public function destroy() {}
	
	public function set_parent(value:Dynamic)
	{
		if (parent == value || value == null || this.interp == null) return parent;
		
		if (this.interp != null && this.interp is InsanityInterpEx)
		{
			var i:InsanityInterpEx = getInterp();
			
			i.scriptParent = value;
		}
		
		return parent = value;
	}
	
	public function get_parent():Dynamic
	{
		if (this.interp == null) return null;
		
		if (this.interp is InsanityInterpEx)
		{
			var i:InsanityInterpEx = getInterp();
			return i.scriptParent;
		}
		
		return null;
	}
	
	function set_sharables(value:Sharables):Sharables
	{
		if (this.interp == null) return new Sharables();
		
		if (this.interp is InsanityInterpEx)
		{
			var i:InsanityInterpEx = getInterp();
			i.sharedFields = value ?? i.sharedFields; // ensure nothing stupid happens!
		}
		
		return new Sharables();
	}
	
	function get_sharables():Sharables
	{
		if (this.interp == null) return new Sharables();
		
		if (this.interp is InsanityInterpEx)
		{
			var i:InsanityInterpEx = getInterp();
			
			return i.sharedFields;
		}
		
		return new Sharables();
	}
}
