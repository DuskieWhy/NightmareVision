package funkin.data;

import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;

import funkin.backend.PlayerSettings;
import funkin.data.Controls.KeyboardScheme;

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
	// graphics ------------------------------------------------------------------------//
	@saveVar public static var gpuCaching:Bool = true;
	
	@saveVar public static var globalAntialiasing:Bool = true;
	
	@saveVar public static var lowQuality:Bool = false;
	
	@saveVar public static var shaders:Bool = true;
	
	@saveVar public static var framerate:Int = 60;
	
	// visuals ------------------------------------------------------------------------//
	@saveVar public static var jumpGhosts:Bool = true;
	
	@saveVar public static var noteSplashes:Bool = true;
	
	@saveVar public static var hideHud:Bool = false;
	
	@saveVar public static var timeBarType:String = 'Time Left';
	
	@saveVar public static var flashing:Bool = true;
	
	@saveVar public static var camZooms:Bool = true;
	
	@saveVar public static var scoreZoom:Bool = true;
	
	@saveVar public static var healthBarAlpha:Float = 1;
	
	@saveVar public static var showFPS:Bool = true;
	
	@saveVar public static var pauseMusic:String = 'Tea Time';
	
	@saveVar public static var camFollowsCharacters:Bool = true;
	
	// gameplay ------------------------------------------------------------------------//
	@saveVar public static var controllerMode:Bool = false;
	
	@saveVar public static var mechanics:Bool = true;
	
	@saveVar public static var downScroll:Bool = false;
	
	@saveVar public static var middleScroll:Bool = false;
	
	@saveVar public static var opponentStrums:Bool = true;
	
	@saveVar public static var ghostTapping:Bool = true;
	
	@saveVar public static var noReset:Bool = false;
	
	@saveVar public static var hitsoundVolume:Float = 0;
	
	@saveVar public static var ratingOffset:Int = 0;
	
	@saveVar public static var useEpicRankings:Bool = true;
	
	@saveVar public static var epicWindow:Float = 22.5;
	
	@saveVar public static var sickWindow:Float = 45.0;
	
	@saveVar public static var goodWindow:Float = 90.0;
	
	@saveVar public static var badWindow:Float = 135.0;
	
	@saveVar public static var safeFrames:Float = 10.0;
	
	@saveVar public static var noteOffset:Int = 0;
	
	@saveVar public static var noteSkin:String = 'Vanilla';
	
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
	@saveVar(false, false) public static var keyBinds:Map<String, Array<FlxKey>> = [
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
	
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	
	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
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
	
	public static function flush()
	{
		// FlxG.save.data.achievementsMap = Achievements.achievementsMap;
		// FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
		
		FlxG.save.flush();
		
		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'ninjamuffin99'); // Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		save.data.customControls = keyBinds;
		save.close();
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
		
		if (Main.fpsVar != null) Main.fpsVar.visible = showFPS;
		
		if (FlxG.save.data.framerate == null) framerate = Std.int(FlxMath.bound(FlxG.stage.application.window.displayMode.refreshRate, 60, 240));
		
		if (framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = framerate;
			FlxG.drawFramerate = framerate;
		}
		else
		{
			FlxG.drawFramerate = framerate;
			FlxG.updateFramerate = framerate;
		}
		
		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'ninjamuffin99');
		if (save != null && save.data.customControls != null)
		{
			CoolUtil.copyMapValues(save.data.customControls, keyBinds);
			
			reloadControls();
		}
		save.destroy();
	}
	
	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic
	{
		return (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}
	
	public static function reloadControls()
	{
		PlayerSettings.player1.controls.setKeyboardScheme(KeyboardScheme.Solo);
		
		FlxG.sound.muteKeys = Init.muteKeys;
		FlxG.sound.volumeDownKeys = Init.volumeDownKeys;
		FlxG.sound.volumeUpKeys = Init.volumeUpKeys;
		Init.muteKeys = copyKey(keyBinds.get('volume_mute'));
		Init.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		Init.volumeUpKeys = copyKey(keyBinds.get('volume_up'));
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
