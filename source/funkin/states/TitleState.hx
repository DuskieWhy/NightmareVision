package funkin.states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import haxe.Json;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.Assets;
import funkin.data.*;
import funkin.data.scripts.*;
import funkin.states.*;
import funkin.objects.*;
import funkin.objects.shader.*;

typedef TitleData =
{
	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	bpm:Int
}

class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;
	public static var instance:TitleState;

	public var blackScreen:FlxSprite;
	public var credGroup:FlxGroup;
	public var credTextShit:Alphabet;
	public var textGroup:FlxGroup;
	public var ngSpr:FlxSprite;

	public var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	public var titleTextAlphas:Array<Float> = [1, .64];

	public var curWacky:Array<String> = [];

	public var wackyImage:FlxSprite;

	public var mustUpdate:Bool = false;

	public var titleJSON:TitleData;

	public static var updateVersion:String = '';

	override public function create():Void
	{
		instance = this;
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if LUA_ALLOWED
		Paths.pushGlobalMods();
		#end
		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();

		// trace(path, FileSystem.exists(path));

		curWacky = FlxG.random.getObject(getIntroTextShit());

		// DEBUG BULLSHIT

		swagShader = new ColorSwap();

		setUpScript('TitleState');

		super.create();

		#if CHECK_FOR_UPDATES
		if (ClientPrefs.checkForUpdates && !closedState)
		{
			trace('checking for update');
			var http = new haxe.Http("https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/main/gitVersion.txt");

			http.onData = function(data:String) {
				updateVersion = data.split('\n')[0].trim();
				var curVersion:String = Main.PSYCH_VERSION.trim();
				trace('version online: ' + updateVersion + ', your version: ' + curVersion);
				if (updateVersion != curVersion)
				{
					trace('versions arent matching!');
					// mustUpdate = true;
					// for now we dont have a nightmare vision ver indicator so we are just gonna disable this
				}
			}

			http.onError = function(error) {
				trace('error: $error');
			}

			http.request();
		}
		#end

		setOnScript('game', instance);

		// IGNORE THIS!!!
		titleJSON = Json.parse(Paths.getTextFromFile('images/gfDanceTitle.json'));
		setOnScript('titleJSON', titleJSON);

		if (!initialized)
		{
			if (FlxG.save.data != null && FlxG.save.data.fullscreen)
			{
				FlxG.fullscreen = FlxG.save.data.fullscreen;
				// trace('LOADED FULLSCREEN SETTING!!');
			}
			persistentUpdate = true;
			persistentDraw = true;
		}

		FlxG.mouse.visible = false;
		#if FREEPLAY
		FlxG.switchState(new FreeplayState());
		#elseif CHARTING
		FlxG.switchState(new ChartingState());
		#else
		if (FlxG.save.data.flashing == null && !FlashingState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.switchState(new FlashingState());
		}
		else
		{
			if (initialized) startIntro();
			else
			{
				new FlxTimer().start(1, function(tmr:FlxTimer) {
					startIntro();
				});
			}
		}
		#end
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;

	public function startIntro()
	{
		if (!initialized)
		{
			if (FlxG.sound.music == null)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			}
		}

		Conductor.bpm = titleJSON.bpm;
		persistentUpdate = true;

		if (isHardcodedState() && callOnScript('onStartIntro', []) != Globals.Function_Stop)
		{
			var bg:FlxSprite = new FlxSprite();

			if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none")
			{
				bg.loadGraphic(Paths.image(titleJSON.backgroundSprite));
			}
			else
			{
				bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			}

			// bg.antialiasing = ClientPrefs.globalAntialiasing;
			// bg.setGraphicSize(Std.int(bg.width * 0.6));
			// bg.updateHitbox();
			add(bg);

			logoBl = new FlxSprite(titleJSON.titlex, titleJSON.titley);
			logoBl.frames = Paths.getSparrowAtlas('logoBumpin');

			logoBl.antialiasing = ClientPrefs.globalAntialiasing;
			logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
			logoBl.animation.play('bump');
			logoBl.updateHitbox();

			swagShader = new ColorSwap();
			gfDance = new FlxSprite(titleJSON.gfx, titleJSON.gfy);

			var easterEgg:String = FlxG.save.data.psychDevsEasterEgg;
			if (easterEgg == null) easterEgg = ''; // html5 fix

			gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
			gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
			gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);

			gfDance.antialiasing = ClientPrefs.globalAntialiasing;

			add(gfDance);
			gfDance.shader = swagShader.shader;
			add(logoBl);
			logoBl.shader = swagShader.shader;

			titleText = new FlxSprite(titleJSON.startx, titleJSON.starty).loadSparrowFrames('titleEnter');

			var animFrames:Array<FlxFrame> = [];
			@:privateAccess {
				titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
				titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
			}

			if (animFrames.length > 0)
			{
				newTitle = true;

				titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
				titleText.animation.addByPrefix('press', ClientPrefs.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
			}
			else
			{
				newTitle = false;

				titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
				titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
			}

			titleText.antialiasing = ClientPrefs.globalAntialiasing;
			titleText.animation.play('idle');
			titleText.updateHitbox();
			add(titleText);

			credGroup = new FlxGroup();
			add(credGroup);
			textGroup = new FlxGroup();

			blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			credGroup.add(blackScreen);

			credTextShit = new Alphabet(0, 0, "", true);
			credTextShit.screenCenter();

			credTextShit.visible = false;

			ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
			add(ngSpr);
			ngSpr.visible = false;
			ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
			ngSpr.updateHitbox();
			ngSpr.screenCenter(X);
			ngSpr.antialiasing = ClientPrefs.globalAntialiasing;

			FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

			if (initialized) skipIntro();
			else initialized = true;
		}

		callOnScript('onCreatePost', []);
	}

	public function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;

	private static var playJingle:Bool = false;

	var newTitle:Bool = false;
	var titleTimer:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		if (isHardcodedState())
		{
			#if mobile
			for (touch in FlxG.touches.list)
			{
				if (touch.justPressed)
				{
					pressedEnter = true;
				}
			}
			#end

			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

			if (gamepad != null)
			{
				if (gamepad.justPressed.START) pressedEnter = true;

				#if switch
				if (gamepad.justPressed.B) pressedEnter = true;
				#end
			}

			if (newTitle)
			{
				titleTimer += FlxMath.bound(elapsed, 0, 1);
				if (titleTimer > 2) titleTimer -= 2;
			}

			// EASTER EGG

			if (initialized && !transitioning && skippedIntro)
			{
				if (newTitle && !pressedEnter)
				{
					var timer:Float = titleTimer;
					if (timer >= 1) timer = (-timer) + 2;

					timer = FlxEase.quadInOut(timer);

					titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
					titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
				}

				if (pressedEnter && callOnScript('onEnter', []) != Globals.Function_Stop)
				{
					titleText.color = FlxColor.WHITE;
					titleText.alpha = 1;

					if (titleText != null) titleText.animation.play('press');

					FlxG.camera.flash(ClientPrefs.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
					FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

					transitioning = true;
					// FlxG.sound.music.stop();

					new FlxTimer().start(1, function(tmr:FlxTimer) {
						if (mustUpdate)
						{
							FlxG.switchState(new OutdatedState());
						}
						else
						{
							FlxG.switchState(new MainMenuState());
						}
						closedState = true;
					});
					// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
				}
			}

			if (initialized && pressedEnter && !skippedIntro)
			{
				skipIntro();
			}

			if (swagShader != null)
			{
				if (controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
				if (controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
			}
		}

		super.update(elapsed);
	}

	public function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if (credGroup != null && textGroup != null)
			{
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	public function addMoreText(text:String, ?offset:Float = 0)
	{
		if (textGroup != null && credGroup != null)
		{
			var coolText:Alphabet = new Alphabet(0, 0, text, true);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	public function deleteCoolText()
	{
		if (textGroup.members[0] != null)
		{
			while (textGroup.members.length > 0)
			{
				credGroup.remove(textGroup.members[0], true);
				textGroup.remove(textGroup.members[0], true);
			}
		}
	}

	private var sickBeats:Int = 0; // Basically curBeat but won't be skipped if you hold the tab or resize the screen

	public static var closedState:Bool = false;

	override function beatHit()
	{
		super.beatHit();

		if (!closedState)
		{
			sickBeats++;
			setOnScript('curBeat', sickBeats);
		}

		if (!isHardcodedState() && callOnScript('onBeatHit', []) == Globals.Function_Stop) return;

		if (logoBl != null)
		{
			logoBl.animation.play('bump', true);
		}

		if (gfDance != null)
		{
			danceLeft = !danceLeft;
			gfDance.animation.play(danceLeft ? 'danceRight' : 'danceLeft');
		}

		if (!closedState)
		{
			switch (sickBeats)
			{
				case 1:
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				case 2:
					#if PSYCH_WATERMARKS
					createCoolText(['Psych Engine by'], 15);
					#else
					createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
					#end
				case 4:
					#if PSYCH_WATERMARKS
					addMoreText('Shadow Mario', 15);
					addMoreText('RiverOaken', 15);
					addMoreText('shubs', 15);
					#else
					addMoreText('present');
					#end

				case 5:
					deleteCoolText();

				case 6:
					#if PSYCH_WATERMARKS
					createCoolText(['Not associated', 'with'], -40);
					#else
					createCoolText(['In association', 'with'], -40);
					#end
				case 8:
					addMoreText('newgrounds', -40);
					ngSpr.visible = true;
				case 9:
					deleteCoolText();
					ngSpr.visible = false;
				case 10:
					createCoolText([curWacky[0]]);
				case 12:
					addMoreText(curWacky[1]);
				case 13:
					deleteCoolText();
				case 14:
					addMoreText('Friday');
				case 15:
					addMoreText('Night');
				case 16:
					addMoreText('Funkin');

				case 17:
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;

	public function skipIntro():Void
	{
		if (callOnScript('onSkipIntro', []) != Globals.Function_Stop && !skippedIntro)
		{
			remove(ngSpr);
			remove(credGroup);
			FlxG.camera.flash(FlxColor.WHITE, 4);

			skippedIntro = true;
		}
	}
}
