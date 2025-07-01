package funkin.states;

import lime.app.Application;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

import funkin.data.*;
import funkin.states.options.*;
import funkin.states.*;
import funkin.states.editors.MasterEditorMenu;

class MainMenuState extends MusicBeatState
{
	public static var curSelected:Int = 0;
	
	var menuItems:FlxTypedGroup<FlxSprite>;
	var camAchievement:FlxCamera;
	
	var optionShit:Array<String> = ['story_mode', 'freeplay', 'credits', 'options'];
	
	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var debugKeys:Array<FlxKey>;
	
	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		
		camAchievement = new FlxCamera();
		camAchievement.bgColor = 0x0;
		
		FlxG.cameras.reset();
		FlxG.cameras.add(camAchievement, false);
		
		persistentUpdate = persistentDraw = true;
		
		camFollow = new FlxObject(FlxG.width / 2, 0, 1, 1);
		add(camFollow);
		
		setUpScript();
		
		if (isHardcodedState())
		{
			var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
			var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
			bg.scrollFactor.set(0, yScroll);
			bg.setGraphicSize(Std.int(bg.width * 1.175));
			bg.updateHitbox();
			bg.screenCenter();
			bg.antialiasing = ClientPrefs.globalAntialiasing;
			add(bg);
			
			magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
			magenta.scrollFactor.copyFrom(bg.scrollFactor);
			magenta.setGraphicSize(Std.int(magenta.width * 1.175));
			magenta.updateHitbox();
			magenta.screenCenter();
			magenta.visible = false;
			magenta.antialiasing = ClientPrefs.globalAntialiasing;
			magenta.color = 0xFFfd719b;
			add(magenta);
			
			menuItems = new FlxTypedGroup<FlxSprite>();
			add(menuItems);
			
			for (i in 0...optionShit.length)
			{
				var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
				var menuItem:FlxSprite = new FlxSprite(0, (i * 140) + offset);
				menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
				menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
				menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
				menuItem.animation.play('idle');
				menuItem.ID = i;
				menuItem.screenCenter(X);
				menuItems.add(menuItem);
				var scr:Float = (optionShit.length - 4) * 0.135;
				if (optionShit.length < 6) scr = 0;
				menuItem.scrollFactor.set(0, scr);
				menuItem.antialiasing = ClientPrefs.globalAntialiasing;
				menuItem.updateHitbox();
			}
			
			FlxG.camera.follow(camFollow, null, 0.15);
			
			var ver = "Nightmare Vision Engine\n" + 'Psych Engine v' + Main.PSYCH_VERSION + "\nFriday Night Funkin' v" + Main.FUNKIN_VERSION;
			var verionDesc:FlxText = new FlxText(12, FlxG.height - 44, 0, ver, 16);
			verionDesc.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			verionDesc.y = FlxG.height - verionDesc.height - 12;
			verionDesc.scrollFactor.set();
			add(verionDesc);
			
			changeItem();
			
			#if ACHIEVEMENTS_ALLOWED
			Achievements.loadAchievements();
			var leDate = Date.now();
			if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			{
				var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
				if (!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2]))
				{
					Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
					giveAchievement();
					ClientPrefs.flush();
				}
			}
			#end
		}
		super.create();
		
		script.call('onCreatePost', []);
	}
	
	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement()
	{
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end
	
	var selectedSomethin:Bool = false;
	
	override function update(elapsed:Float)
	{
		@:privateAccess
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}
		
		if (isHardcodedState())
		{
			if (!selectedSomethin)
			{ 
				if (controls.UI_UP_P || controls.UI_DOWN_P) {
				       FlxG.sound.play(Paths.sound('scrollMenu'));
				       changeItem(controls.UI_UP_P ? -1 : 1);		
				}
				
				if (controls.BACK)
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('cancelMenu'));
					FlxG.switchState(TitleState.new);
				}
				
				script.set('curSelected', curSelected);
				
				if (controls.ACCEPT)
				{
					script.call('onSelect', [optionShit[curSelected]]);
					
					if (optionShit[curSelected] == 'donate')
					{
						CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
						return;
					}
					
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));
					
					if (ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);
					
					var selectedObj = menuItems.members[curSelected];
					
					FlxFlicker.flicker(selectedObj, 1, 0.06, false, false, (s) -> {
						switch (optionShit[curSelected])
						{
							case 'story_mode':
								FlxG.switchState(StoryMenuState.new);
							case 'freeplay':
								FlxG.switchState(FreeplayState.new);
							case 'credits':
								FlxG.switchState(CreditsState.new);
							case 'options':
								FlxG.switchState(funkin.states.options.OptionsState.new);
								OptionsState.onPlayState = false;
						}
					});
					
					script.set('onSelectPost', [optionShit[curSelected]]);
					
					menuItems.forEachAlive(s -> if (s != selectedObj) FlxTween.tween(s, {alpha: 0}, 0.4, {ease: FlxEase.quadOut}));
				}
				
				#if desktop
				else if (FlxG.keys.anyJustPressed(debugKeys))
				{
					selectedSomethin = true;
					FlxG.switchState(MasterEditorMenu.new);
				}
				#end
			}
		}
		
		super.update(elapsed);
		
		script.call('onUpdatePost', [elapsed]);
	}
	
	function changeItem(huh:Int = 0)
	{
		var prevObj = menuItems.members[curSelected];
		prevObj.animation.play('idle');
		prevObj.updateHitbox();
		
		curSelected = FlxMath.wrap(curSelected + huh, 0, menuItems.length - 1);
		
		var newObj = menuItems.members[curSelected];
		newObj.animation.play('selected');
		newObj.centerOffsets();
		
		final add:Float = menuItems.length > 4 ? menuItems.length * 8 : 0;
		camFollow.y = newObj.getGraphicMidpoint().y - add;
		
		script.call('onItemChange', [curSelected]);
	}
}
