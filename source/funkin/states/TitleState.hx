package funkin.states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

import funkin.game.shaders.ColorSwap;
import funkin.data.WeekData;
import funkin.objects.Alphabet;
import funkin.scripts.Globals;

@:nullSafety
class TitleState extends MusicBeatState
{
	static var initialized:Bool = false;
	static var closedState:Bool = false;
	
	var skippedIntro:Bool = false;
	var transitioning:Bool = false;
	
	var introEndingText:Array<String> = ['FRIDAY', 'NIGHT', 'FUNKIN'];
	var randomIntroText:Array<String> = [];
	
	// objects
	var textGroup:Null<FlxGroup> = null;
	var ngSpr:Null<FlxSprite> = null;
	var logo:Null<FlxSprite> = null;
	var gfDance:Null<FlxSprite> = null;
	var titleText:Null<FlxSprite> = null;
	var swagShader:Null<ColorSwap> = null;
	
	var danceLeft:Bool = false;
	
	override public function create():Void
	{
		FunkinAssets.cache.clearStoredMemory();
		FunkinAssets.cache.clearUnusedMemory();
		
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();
		
		randomIntroText = FlxG.random.getObject(getIntroText());
		
		setUpScript();
		
		super.create();
		
		persistentUpdate = true;
		
		FlxG.mouse.visible = false;
		
		if (FlxG.save.data.flashing == null && !FlashingState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.switchState(FlashingState.new);
		}
		else
		{
			if (initialized)
			{
				startIntro();
			}
			else
			{
				FlxTimer.wait(1, startIntro);
			}
		}
	}
	
	function startIntro()
	{
		if (!initialized)
		{
			if (FlxG.sound.music == null)
			{
				@:nullSafety(Off)
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			}
		}
		
		Conductor.bpm = 102;
		
		if (isHardcodedState() && scriptGroup.call('onStartIntro') != Globals.Function_Stop)
		{
			swagShader = new ColorSwap();
			
			logo = new FlxSprite(-150, -100).loadAtlasFrames(Paths.getSparrowAtlas('logoBumpin'));
			logo.animation.addByPrefix('bump', 'logo bumpin', 24, false);
			logo.animation.play('bump');
			logo.updateHitbox();
			add(logo);
			logo.shader = swagShader.shader;
			
			gfDance = new FlxSprite(512, 40).loadAtlasFrames(Paths.getSparrowAtlas('gfDanceTitle'));
			gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
			gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
			add(gfDance);
			gfDance.shader = swagShader.shader;
			
			titleText = new FlxSprite(100, 576).loadAtlasFrames(Paths.getAtlasFrames('titleEnter'));
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
			titleText.animation.play('idle');
			titleText.updateHitbox();
			add(titleText);
			
			textGroup = new FlxGroup();
			add(textGroup);
			
			ngSpr = new FlxSprite(0, FlxG.height * 0.52, Paths.image('newgrounds_logo'));
			add(ngSpr);
			ngSpr.visible = false;
			ngSpr.scale.scale(0.8);
			ngSpr.updateHitbox();
			ngSpr.screenCenter(X);
			
			logo.alpha = 0.001;
			gfDance.alpha = 0.001;
			titleText.alpha = 0.001;
		}
		
		if (initialized)
		{
			skipIntro();
		}
		else
		{
			initialized = true;
		}
		
		scriptGroup.call('onCreatePost', []);
	}
	
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
		
		if (!isHardcodedState())
		{
			super.update(elapsed);
			return;
		}
		
		final pressedEnter:Bool = FlxG.gamepads.lastActive?.justPressed.START || FlxG.keys.justPressed.ENTER || controls.ACCEPT;
		
		if (!transitioning && skippedIntro)
		{
			if (pressedEnter && scriptGroup.call('onEnter', []) != Globals.Function_Stop)
			{
				FlxG.camera.flash(ClientPrefs.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				transitioning = true;
				
				if (titleText != null)
				{
					titleText.animation.play('press');
				}
				
				@:nullSafety(Off)
				{
					FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				}
				
				FlxTimer.wait(1, () -> {
					FlxG.switchState(MainMenuState.new);
					closedState = true;
				});
			}
		}
		
		if (pressedEnter && !skippedIntro)
		{
			skipIntro();
		}
		
		if (swagShader != null)
		{
			if (controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if (controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}
		
		super.update(elapsed);
	}
	
	function createCoolText(textArray:Array<String>, offset:Float = 0)
	{
		if (textGroup == null) return;
		
		for (i in 0...textArray.length)
		{
			final text:Alphabet = new Alphabet(0, 0, textArray[i], true);
			text.screenCenter(X);
			text.y += (i * 60) + 200 + offset;
			
			textGroup.add(text);
		}
	}
	
	function addMoreText(text:String, offset:Float = 0)
	{
		if (textGroup == null) return;
		
		final coolText:Alphabet = new Alphabet(0, 0, text, true);
		coolText.screenCenter(X);
		coolText.y += (textGroup.length * 60) + 200 + offset;
		textGroup.add(coolText);
	}
	
	function deleteCoolText()
	{
		if (textGroup != null && textGroup.members[0] != null)
		{
			for (i in 0...textGroup.length)
			{
				var txt = textGroup.members[0];
				textGroup.remove(txt, true);
				
				txt = FlxDestroyUtil.destroy(txt);
			}
		}
	}
	
	function getIntroText():Array<Array<String>>
	{
		if (!FunkinAssets.exists(Paths.txt('introText'))) return [];
		
		final fullText:String = FunkinAssets.getContent(Paths.txt('introText'));
		
		return [for (i in fullText.split('\n')) i.split('--')];
	}
	
	var sickBeats:Int = 0; // Basically curBeat but won't be skipped if you hold the tab or resize the screen
	
	override function beatHit()
	{
		super.beatHit();
		
		if (!closedState)
		{
			sickBeats++;
			scriptGroup.set('curBeat', sickBeats);
		}
		
		if (!isHardcodedState() || scriptGroup.call('onBeatHit', []) == Globals.Function_Stop) return;
		
		// just in case
		if (isHardcodedState())
		{
			if (logo != null)
			{
				logo.animation.play('bump', true);
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
						@:nullSafety(Off)
						{
							FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						}
						FlxG.sound.music.fadeIn(4, 0, 0.7);
					case 2:
						createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
					case 4:
						addMoreText('present');
					case 5:
						deleteCoolText();
					case 6:
						createCoolText(['In association', 'with'], -40);
					case 8:
						addMoreText('newgrounds', -40);
						if (ngSpr != null) ngSpr.visible = true;
					case 9:
						deleteCoolText();
						if (ngSpr != null) ngSpr.visible = false;
					case 10:
						if (randomIntroText[0] != null) createCoolText([randomIntroText[0]]);
					case 12:
						if (randomIntroText[1] != null) addMoreText(randomIntroText[1]);
					case 13:
						deleteCoolText();
					case 14:
						if (introEndingText[0] != null) addMoreText(introEndingText[0]);
					case 15:
						if (introEndingText[1] != null) addMoreText(introEndingText[1]);
					case 16:
						if (introEndingText[2] != null) addMoreText(introEndingText[2]);
					case 17:
						skipIntro();
				}
			}
		}
	}
	
	public function skipIntro():Void
	{
		if (scriptGroup.call('onSkipIntro', []) != Globals.Function_Stop && !skippedIntro)
		{
			ngSpr?.kill();
			textGroup?.kill();
			
			if (logo != null) logo.alpha = 1;
			if (gfDance != null) gfDance.alpha = 1;
			if (titleText != null) titleText.alpha = 1;
			
			FlxG.camera.flash(FlxColor.WHITE, 4);
			
			skippedIntro = true;
		}
	}
}
