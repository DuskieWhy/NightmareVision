package funkin.data;

import flixel.input.gamepad.FlxGamepadInputID;

import funkin.backend.DebugDisplay;

import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;

import funkin.input.Controls.KeyboardScheme;
import funkin.input.Controls;

enum abstract UnderlayType(String) to String from String
{
	public var FIELD = 'Lane Underlay';
	public var SCREEN = 'Screen Dim';
	
	// @:to
	public static function toArray():Array<String> // dont want to jump to options states to update
	{
		// granted its a bit overkill to even do this for 2 options but i dunno remove it if u dont want it //or maybe i will another time
		return [FIELD, SCREEN];
	}
}

/**
 * to add new save options, make a static var with the `@saveVar` meta and itll be handled on its own
 * 
 * if you want to manually handle load and save add params to saveVar like `@saveVar(autoSave,autoLoad)`
 * 
 * for better reference on this look at keybinds
 */
@:build(funkin.backend.macro.SaveMacro.buildSaveVars('im gonna make this do smth later okay just not rn'))
class ClientPrefs
{
	// debug ------------------------------------------------------------------------//
	@saveVar public static var inDevMode:Bool = false;
	
	@saveVar public static var fpsDisplayType:String = 'Simple';
	
	@saveVar public static var streamedMusic:Bool = false;
	
	@saveVar public static var autoPause:Bool = true;
	
	// graphics ------------------------------------------------------------------------//
	@saveVar public static var gpuCaching:Bool = true;
	
	@saveVar public static var globalAntialiasing:Bool = true;
	
	@saveVar public static var lowQuality:Bool = false;
	
	@saveVar public static var shaders:Bool = true;
	
	@saveVar public static var unlockedFramerate:Bool = false;
	
	@saveVar public static var framerate:Int = 60;
	
	// visuals ------------------------------------------------------------------------//
	@saveVar public static var jumpGhosts:Bool = false;
	
	@saveVar public static var noteSplashes:Bool = true;
	
	@saveVar public static var hideHud:Bool = false;
	
	@saveVar public static var showRatings:Bool = true;
	
	@saveVar public static var timeBarType:String = 'Time Left';
	
	@saveVar public static var flashing:Bool = true;
	
	@saveVar public static var camZooms:Bool = true;
	
	@saveVar public static var scoreZoom:Bool = true;
	
	@saveVar public static var healthBarAlpha:Float = 1;
	
	@saveVar public static var pauseMusic:String = 'Tea Time';
	
	@saveVar public static var camFollowsCharacters:Bool = true;
	
	@saveVar public static var underlayType:String = 'Lane Underlay';
	
	@saveVar public static var underlayOpacity:Float = 0.0;
	
	// gameplay ------------------------------------------------------------------------//
	@saveVar public static var mechanics:Bool = true;
	
	@saveVar public static var modcharts:Bool = true;
	
	@saveVar public static var downScroll:Bool = false;
	
	@saveVar public static var middleScroll:Bool = false;
	
	@saveVar public static var opponentStrums:Bool = true;
	
	@saveVar public static var ghostTapping:Bool = true;
	
	@saveVar public static var noReset:Bool = false;
	
	@saveVar public static var hitsoundVolume:Float = 0;
	
	@saveVar public static var ratingOffset:Int = 0;
	
	@saveVar public static var useEpicRankings:Bool = true;
	
	@saveVar public static var toggleSplashScreen:Bool = true;
	
	@saveVar public static var epicWindow:Float = 22.5;
	
	@saveVar public static var sickWindow:Float = 45.0;
	
	@saveVar public static var goodWindow:Float = 90.0;
	
	@saveVar public static var badWindow:Float = 135.0;
	
	@saveVar public static var safeFrames:Float = 10.0;
	
	@saveVar public static var noteOffset:Int = 0;
	
	@saveVar public static var quants:Bool = false;
	
	// @saveVar public static var noteSkin:String = 'Vanilla';
	@saveVar public static var comboOffset:Array<Int> = [0, 0, 0, 0];
	
	@saveVar public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];
	
	// note colours ------------------------------------------------------------------------//
	@saveVar public static var arrowRGBdef:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]];
		
	@saveVar public static var arrowRGBquant:Array<Array<FlxColor>> = [
		[0xFFE51919, 0xFFFFFF, 0xFF5B0A30], // 4th
		[0xFF193BE5, 0xFFFFFF, 0xFF0A3B5B], // 8th
		[0xFFA119E5, 0xFFFFFF, 0xFF1D0A5B], // 12th
		[0xFF26D93E, 0xFFFFFF, 0xFF24560F], // 16th
		[0xFF0000B2, 0xFFFFFF, 0xFF002247], // 20th
		[0xFFA119E5, 0xFFFFFF, 0xFF1D0A5B], // 24th
		[0xFFE5C319, 0xFFFFFF, 0xFF5B2A0A], // 32nd
		[0xFFA119E5, 0xFFFFFF, 0xFF1D0A5B], // 48th
		[0xFF13ECA4, 0xFFFFFF, 0xFF085D18], // 64th
		[0xFF3A3A6C, 0xFFFFFF, 0xFF17202B], // 96th
		[0xFF3A3A6C, 0xFFFFFF, 0xFF17202B] // 192nd
	];
	
	@saveVar public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	@saveVar public static var quantHSV:Array<Array<Int>> = [
		[0, -20, 0], // 4th
		[-130, -20, 0], // 8th
		[-80, -20, 0], // 12th
		[128, -30, 0], // 16th
		[-120, -70, -35], // 20th
		[-80, -20, 0], // 24th
		[50, -20, 0], // 32nd
		[-80, -20, 0], // 48th
		[160, -15, 0], // 64th
		[-120, -70, -35], // 96th
		[-120, -70, -35] // 192nd
	];
	@saveVar public static var quantStepmania:Array<Array<Int>> = [
		[10, -20, 0], // 4th
		[-110, -40, 0], // 8th
		[140, -20, 0], // 12th
		[50, 25, 0], // 16th
		[0, -100, -50], // 20th
		[-80, -40, 0], // 24th
		[-180, 10, -10], // 32nd
		[-35, 50, 30], // 48th
		[160, -15, 0], // 64th
		[-120, -70, -35], // 96th
		[-120, -70, -35] // 192nd
	];
	
	// keybinds ------------------------------------------------------------------------//
	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	@saveVar(false, false) public static var keyBinds:Map<Action, Array<FlxKey>> = [
		// Key Bind, Name for ControlsSubState
		'note_left' => [A, LEFT],
		'note_down' => [S, DOWN],
		'note_up' => [W, UP],
		'note_right' => [D, RIGHT],
		'dodge' => [SPACE, NONE],
		'ui_left' => [A, LEFT],
		'ui_down' => [S, DOWN],
		'ui_up' => [W, UP],
		'ui_right' => [D, RIGHT],
		'accept' => [SPACE, ENTER],
		'back' => [BACKSPACE, ESCAPE],
		'pause' => [ENTER, ESCAPE],
		'reset' => [R, NONE],
		'volume_mute' => [ZERO, NONE],
		'volume_up' => [NUMPADPLUS, PLUS],
		'volume_down' => [NUMPADMINUS, MINUS],
		'debug_1' => [SEVEN, NONE],
		'debug_2' => [EIGHT, NONE]
	];
	
	public static var defaultKeys:Map<Action, Array<FlxKey>> = null;
	
	public static var gamepadBinds:Map<Action, Array<FlxGamepadInputID>> = [
		'note_up' => [DPAD_UP, Y],
		'note_down' => [DPAD_DOWN, A],
		'note_left' => [DPAD_LEFT, X],
		'note_right' => [DPAD_RIGHT, B],
	];
	
	public static var defaultGamepadBinds:Map<Action, Array<FlxGamepadInputID>> = null;
	
	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
		defaultGamepadBinds = gamepadBinds.copy();
	}
	
	// Editor Colours ------------------------------------------------------------------------//
	@saveVar public static var editorUIColor:FlxColor = FlxColor.fromRGB(102, 163, 255);
	@saveVar public static var editorGradColors:Array<FlxColor> = [FlxColor.fromRGB(83, 21, 78), FlxColor.fromRGB(21, 62, 83)];
	@saveVar public static var editorBoxColors:Array<FlxColor> = [FlxColor.fromRGB(58, 112, 159), FlxColor.fromRGB(138, 173, 202)];
	@saveVar public static var editorGradVis:Bool = true;
	
	@saveVar public static var chartPresetList:Array<String> = ["Default"];
	
	@saveVar public static var chartPresets:Map<String, Array<Dynamic>> = [
		"Default" => [
			[FlxColor.fromRGB(0, 0, 0), FlxColor.fromRGB(0, 0, 0)],
			false,
			[FlxColor.fromRGB(255, 255, 255), FlxColor.fromRGB(210, 210, 210)],
			FlxColor.fromRGB(250, 250, 250)
		]
	];
	
	/**
	 * Contains keys that mute the game volume
	 * 
	 * default is `0`
	 */
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	
	/**
	 * Contains keys that turn down the game volume
	 * 
	 * default is `-`
	 */
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	
	/**
	 * Contains keys that turn up the game volume
	 * 
	 * default is `+`
	 */
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	
	public static function flush()
	{
		FlxG.save.flush();
		
		var save:FlxSave = new FlxSave();
		save.bind('controls_v2');
		save.data.customControls = keyBinds;
		save.data.customGamepadControls = gamepadBinds;
		save.close();
	}
	
	public static function tryBindingSave(name:String = 'funkin')
	{
		if (FlxG.save.bind(name, CoolUtil.getSavePath()) == false) // coudlnt bind the save so just fallback
		{
			@:privateAccess
			{
				final file = FlxSave.validate(FlxG.stage.application.meta.get('file'));
				final path = SaveUtil.getPath('', '$file/$name');
				
				if (FileSystem.exists(path))
				{
					final corruptedPath = path.withoutExtension() + ' (corrupted) ${Date.now().toString().replace(':', '_')}.sol';
					FileSystem.rename(path, corruptedPath);
					
					trace('Save was corrupted. corrupted save was placed at $corruptedPath');
				}
			}
			
			FlxG.save.bind(name, CoolUtil.getSavePath());
		}
	}
	
	/**
	 * You can add your own functionality here if needed beyond what `@saveVar` does. 
	 * 
	 * that being just loading the values from the flixel save
	 */
	public static function load()
	{
		if (FlxG.save.data.volume != null) FlxG.sound.volume = FlxG.save.data.volume;
		
		if (FlxG.save.data.mute != null) FlxG.sound.muted = FlxG.save.data.mute;
		
		if (FlxG.save.data.framerate == null) framerate = Std.int(FlxMath.bound(FlxG.stage.application.window.displayMode.refreshRate, 60, 400));
		
		changeFps(framerate);
		
		var save:FlxSave = new FlxSave();
		save.bind('controls_v2');
		if (save != null && save.data.customControls != null) CoolUtil.copyMapValues(save.data.customControls, keyBinds);
		if (save != null && save.data.customGamepadControls != null) CoolUtil.copyMapValues(save.data.customGamepadControls, gamepadBinds);
		reloadControls();
		
		save = FlxDestroyUtil.destroy(save);
	}
	
	public static function changeFps(fps:Int = 60)
	{
		fps = unlockedFramerate ? 0 : Std.int(FlxMath.bound(fps, 60, 400));
		
		if (fps > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = fps;
			FlxG.drawFramerate = fps;
		}
		else
		{
			FlxG.drawFramerate = fps;
			FlxG.updateFramerate = fps;
		}
	}
	
	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic
	{
		return (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}
	
	public static function reloadControls()
	{
		Controls.instance.setKeyboardScheme(KeyboardScheme.Solo);
		final gamepads = Controls.instance.gamepadsAdded.copy();
		Controls.instance.removeGamepad();
		for (id in gamepads)
			Controls.instance.addDefaultGamepad(id);
			
		ClientPrefs.muteKeys = copyKey(keyBinds.get('volume_mute'));
		ClientPrefs.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		ClientPrefs.volumeUpKeys = copyKey(keyBinds.get('volume_up'));
		
		FlxG.sound.muteKeys = ClientPrefs.muteKeys;
		FlxG.sound.volumeDownKeys = ClientPrefs.volumeDownKeys;
		FlxG.sound.volumeUpKeys = ClientPrefs.volumeUpKeys;
	}
	
	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;
		
		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		
		return copiedArray;
	}
}

@:access(flixel.util.FlxSave)
private class SaveUtil
{
	static function getPath(localPath:String, name:String):String
	{
		// Avoid ever putting .sol files directly in AppData
		if (localPath == "") localPath = getDefaultLocalPath();
		
		var directory = lime.system.System.applicationStorageDirectory;
		var path = haxe.io.Path.normalize('$directory/../../../$localPath') + "/";
		
		name = StringTools.replace(name, "//", "/");
		name = StringTools.replace(name, "//", "/");
		
		if (StringTools.startsWith(name, "/"))
		{
			name = name.substr(1);
		}
		
		if (StringTools.endsWith(name, "/"))
		{
			name = name.substring(0, name.length - 1);
		}
		
		if (name.indexOf("/") > -1)
		{
			var split = name.split("/");
			name = "";
			
			for (i in 0...(split.length - 1))
			{
				name += split[i] + "/";
			}
			
			name += split[split.length - 1];
		}
		
		return path + name + ".sol";
	}
	
	static function getDefaultLocalPath()
	{
		var meta = openfl.Lib.current.stage.application.meta;
		var path = meta["company"];
		if (path == null || path == "") path = "HaxeFlixel";
		else path = FlxSave.validate(path);
		
		return path;
	}
}
