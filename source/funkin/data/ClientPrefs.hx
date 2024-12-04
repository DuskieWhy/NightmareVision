package funkin.data;

import funkin.backend.PlayerSettings;
import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import funkin.data.*;
import funkin.data.Controls.KeyboardScheme;

class ClientPrefs
{
	//-----------------------------------------//
	public static var gpuCaching:Bool = true;

	// we need to rethink the loading cuz the current setup does not work the best
	public static var loadingThreads:Int = Math.floor(Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS")) / 2);
	public static var multicoreLoading:Bool = false;

	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var opponentStrums:Bool = true;
	public static var showFPS:Bool = true;
	public static var flashing:Bool = true;
	public static var globalAntialiasing:Bool = true;
	public static var noteSplashes:Bool = true;
	public static var lowQuality:Bool = false;
	public static var framerate:Int = 60;
	public static var camZooms:Bool = true;
	public static var hideHud:Bool = false;
	public static var camMovement:Bool = true;
	public static var noteOffset:Int = 0;
	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	public static var quantHSV:Array<Array<Int>> = [
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
	public static var quantStepmania:Array<Array<Int>> = [
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
	public static var ghostTapping:Bool = true;
	public static var timeBarType:String = 'Time Left';
	public static var scoreZoom:Bool = true;
	public static var noteSkin:String = 'Vanilla';
	public static var noReset:Bool = false;
	public static var healthBarAlpha:Float = 1;
	public static var controllerMode:Bool = false;
	public static var hitsoundVolume:Float = 0;
	public static var pauseMusic:String = 'Tea Time';
	public static var gameplaySettings:Map<String, Dynamic> = [
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

	public static var comboOffset:Array<Int> = [0, 0, 0, 0];
	public static var ratingOffset:Int = 0;
	public static var epicWindow:Float = 22.5;
	public static var sickWindow:Float = 45.0;
	public static var goodWindow:Float = 90.0;
	public static var badWindow:Float = 135.0;
	public static var safeFrames:Float = 10.0;

	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
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
	public static var editorUIColor:FlxColor = FlxColor.fromRGB(102, 163, 255);
	public static var editorGradColors:Array<FlxColor> = [FlxColor.fromRGB(83, 21, 78), FlxColor.fromRGB(21, 62, 83)];
	public static var editorBoxColors:Array<FlxColor> = [FlxColor.fromRGB(58, 112, 159), FlxColor.fromRGB(138, 173, 202)];
	public static var editorGradVis:Bool = true;

	public static var chartPresetList:Array<String> = ["Default"];
	public static var chartPresets:Map<String, Array<Dynamic>> = [
		"Default" => [
			[FlxColor.fromRGB(0, 0, 0), FlxColor.fromRGB(0, 0, 0)],
			false,
			[FlxColor.fromRGB(255, 255, 255), FlxColor.fromRGB(210, 210, 210)],
			FlxColor.fromRGB(250, 250, 250)
		]
	];

	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
		// trace(defaultKeys);
	}

	public static function saveSettings()
	{
		FlxG.save.data.gpuCaching = gpuCaching;
		FlxG.save.data.editorGradColors = editorGradColors;
		FlxG.save.data.editorBoxColors = editorBoxColors;
		FlxG.save.data.editorUIColor = editorUIColor;
		FlxG.save.data.editorGradVis = editorGradVis;

		FlxG.save.data.chartPresetList = chartPresetList;
		FlxG.save.data.chartPresets = chartPresets;

		FlxG.save.data.downScroll = downScroll;
		FlxG.save.data.middleScroll = middleScroll;
		FlxG.save.data.opponentStrums = opponentStrums;
		FlxG.save.data.showFPS = showFPS;
		FlxG.save.data.flashing = flashing;
		FlxG.save.data.globalAntialiasing = globalAntialiasing;
		FlxG.save.data.noteSplashes = noteSplashes;
		FlxG.save.data.lowQuality = lowQuality;
		FlxG.save.data.framerate = framerate;
		FlxG.save.data.camZooms = camZooms;
		FlxG.save.data.noteOffset = noteOffset;
		FlxG.save.data.hideHud = hideHud;
		FlxG.save.data.multicoreLoading = multicoreLoading;
		FlxG.save.data.camMovement = camMovement;
		FlxG.save.data.loadingThreads = loadingThreads;
		FlxG.save.data.arrowHSV = arrowHSV;
		FlxG.save.data.quantHSV = quantHSV;
		FlxG.save.data.ghostTapping = ghostTapping;
		FlxG.save.data.timeBarType = timeBarType;
		FlxG.save.data.scoreZoom = scoreZoom;
		FlxG.save.data.noteSkin = noteSkin;
		FlxG.save.data.noReset = noReset;
		FlxG.save.data.healthBarAlpha = healthBarAlpha;
		FlxG.save.data.comboOffset = comboOffset;
		FlxG.save.data.achievementsMap = Achievements.achievementsMap;
		FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;

		FlxG.save.data.ratingOffset = ratingOffset;
		FlxG.save.data.epicWindow = epicWindow;
		FlxG.save.data.sickWindow = sickWindow;
		FlxG.save.data.goodWindow = goodWindow;
		FlxG.save.data.badWindow = badWindow;
		FlxG.save.data.safeFrames = safeFrames;
		FlxG.save.data.gameplaySettings = gameplaySettings;
		FlxG.save.data.controllerMode = controllerMode;
		FlxG.save.data.hitsoundVolume = hitsoundVolume;
		FlxG.save.data.pauseMusic = pauseMusic;

		FlxG.save.flush();

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'ninjamuffin99'); // Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		save.data.customControls = keyBinds;
		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs()
	{
		if (FlxG.save.data.gpuCaching != null) FlxG.save.data.gpuCaching = gpuCaching;

		if (FlxG.save.data.editorGradColors != null)
		{
			editorGradColors = FlxG.save.data.editorGradColors;
		}
		if (FlxG.save.data.editorBoxColors != null)
		{
			editorBoxColors = FlxG.save.data.editorBoxColors;
		}
		if (FlxG.save.data.editorUIColor != null)
		{
			editorUIColor = FlxG.save.data.editorUIColor;
		}
		if (FlxG.save.data.editorGradVis != null)
		{
			editorGradVis = FlxG.save.data.editorGradVis;
		}
		if (FlxG.save.data.chartPresetList != null)
		{
			chartPresetList = FlxG.save.data.chartPresetList;
		}
		if (FlxG.save.data.chartPresets != null)
		{
			chartPresets = FlxG.save.data.chartPresets;
		}
		if (FlxG.save.data.downScroll != null)
		{
			downScroll = FlxG.save.data.downScroll;
		}
		if (FlxG.save.data.middleScroll != null)
		{
			middleScroll = FlxG.save.data.middleScroll;
		}
		if (FlxG.save.data.opponentStrums != null)
		{
			opponentStrums = FlxG.save.data.opponentStrums;
		}
		if (FlxG.save.data.showFPS != null)
		{
			showFPS = FlxG.save.data.showFPS;
			if (Main.fpsVar != null)
			{
				Main.fpsVar.visible = showFPS;
			}
		}
		if (FlxG.save.data.flashing != null)
		{
			flashing = FlxG.save.data.flashing;
		}
		if (FlxG.save.data.globalAntialiasing != null)
		{
			globalAntialiasing = FlxG.save.data.globalAntialiasing;
		}
		if (FlxG.save.data.noteSplashes != null)
		{
			noteSplashes = FlxG.save.data.noteSplashes;
		}
		if (FlxG.save.data.lowQuality != null)
		{
			lowQuality = FlxG.save.data.lowQuality;
		}
		if (FlxG.save.data.framerate == null)
		{
			framerate = Std.int(FlxMath.bound(FlxG.stage.application.window.displayMode.refreshRate, 60, 240));
		}
		if (FlxG.save.data.framerate != null)
		{
			framerate = FlxG.save.data.framerate;
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
		}

		if (FlxG.save.data.camZooms != null)
		{
			camZooms = FlxG.save.data.camZooms;
		}
		if (FlxG.save.data.hideHud != null)
		{
			hideHud = FlxG.save.data.hideHud;
		}
		if (FlxG.save.data.multicoreLoading != null)
		{
			multicoreLoading = FlxG.save.data.multicoreLoading;
		}
		if (FlxG.save.data.camMovement != null)
		{
			camMovement = FlxG.save.data.camMovement;
		}
		if (FlxG.save.data.loadingThreads != null)
		{
			loadingThreads = FlxG.save.data.loadingThreads;
			if (loadingThreads > Math.floor(Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS"))))
			{
				loadingThreads = Math.floor(Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS")));
				FlxG.save.data.loadingThreads = loadingThreads;
			}
		}
		if (FlxG.save.data.noteOffset != null)
		{
			noteOffset = FlxG.save.data.noteOffset;
		}
		if (FlxG.save.data.arrowHSV != null)
		{
			arrowHSV = FlxG.save.data.arrowHSV;
		}
		if (FlxG.save.data.quantHSV != null)
		{
			quantHSV = FlxG.save.data.quantHSV;
		}
		if (FlxG.save.data.noteSkin != null)
		{
			noteSkin = FlxG.save.data.noteSkin;
		}
		if (FlxG.save.data.ghostTapping != null)
		{
			ghostTapping = FlxG.save.data.ghostTapping;
		}
		if (FlxG.save.data.timeBarType != null)
		{
			timeBarType = FlxG.save.data.timeBarType;
		}
		if (FlxG.save.data.scoreZoom != null)
		{
			scoreZoom = FlxG.save.data.scoreZoom;
		}
		if (FlxG.save.data.noReset != null)
		{
			noReset = FlxG.save.data.noReset;
		}
		if (FlxG.save.data.healthBarAlpha != null)
		{
			healthBarAlpha = FlxG.save.data.healthBarAlpha;
		}
		if (FlxG.save.data.comboOffset != null)
		{
			comboOffset = FlxG.save.data.comboOffset;
		}

		if (FlxG.save.data.ratingOffset != null)
		{
			ratingOffset = FlxG.save.data.ratingOffset;
		}
		if (FlxG.save.data.epicWindow != null)
		{
			epicWindow = FlxG.save.data.epicWindow;
		}
		if (FlxG.save.data.sickWindow != null)
		{
			sickWindow = FlxG.save.data.sickWindow;
		}
		if (FlxG.save.data.goodWindow != null)
		{
			goodWindow = FlxG.save.data.goodWindow;
		}
		if (FlxG.save.data.badWindow != null)
		{
			badWindow = FlxG.save.data.badWindow;
		}
		if (FlxG.save.data.safeFrames != null)
		{
			safeFrames = FlxG.save.data.safeFrames;
		}
		if (FlxG.save.data.controllerMode != null)
		{
			controllerMode = FlxG.save.data.controllerMode;
		}
		if (FlxG.save.data.hitsoundVolume != null)
		{
			hitsoundVolume = FlxG.save.data.hitsoundVolume;
		}
		if (FlxG.save.data.pauseMusic != null)
		{
			pauseMusic = FlxG.save.data.pauseMusic;
		}
		if (FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
			{
				gameplaySettings.set(name, value);
			}
		}

		// flixel automatically saves your volume!
		if (FlxG.save.data.volume != null)
		{
			FlxG.sound.volume = FlxG.save.data.volume;
		}
		if (FlxG.save.data.mute != null)
		{
			FlxG.sound.muted = FlxG.save.data.mute;
		}

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'ninjamuffin99');
		if (save != null && save.data.customControls != null)
		{
			var loadedControls:Map<String, Array<FlxKey>> = save.data.customControls;
			for (control => keys in loadedControls)
			{
				keyBinds.set(control, keys);
			}
			reloadControls();
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic
	{
		return /*PlayState.isStoryMode ? defaultValue : */ (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
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
		// trace(copiedArray);
		return copiedArray;
	}
}
