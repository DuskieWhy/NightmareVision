package funkin.states;

import funkin.backend.macro.GitMacro;

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

// todo add null safety later
class MainMenuState extends MusicBeatState
{
	public static var curSelected:Int = 0;
	
	final debugKeys:Array<FlxKey> = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
	
	var optionShit:Array<String> = ['story_mode', 'freeplay', 'credits', 'options'];
	
	var canInteract:Bool = false;
	
	var menuItems:Null<FlxTypedGroup<FlxSprite>> = null;
	
	var magenta:Null<FlxSprite> = null;
	var camFollow:Null<FlxObject> = null;
	
	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		FlxG.cameras.reset();
		
		persistentUpdate = persistentDraw = true;
		
		camFollow = new FlxObject(FlxG.width / 2, 0, 1, 1);
		add(camFollow);
		
		FlxG.camera.follow(camFollow, null, 0.075);
		
		initStateScript();
		
		if (isHardcodedState())
		{
			final yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
			
			var bg:FlxSprite = new FlxSprite(-80, 0, Paths.image('menuBG'));
			bg.scrollFactor.set(0, yScroll);
			bg.scale.scale(1.175);
			bg.updateHitbox();
			bg.screenCenter();
			add(bg);
			
			magenta = new FlxSprite(-80, 0, Paths.image('menuDesat'));
			magenta.scrollFactor.copyFrom(bg.scrollFactor);
			magenta.scale.copyFrom(bg.scale);
			magenta.updateHitbox();
			magenta.screenCenter();
			magenta.visible = false;
			magenta.color = 0xFFfd719b;
			add(magenta);
			
			menuItems = new FlxTypedGroup<FlxSprite>();
			add(menuItems);
			
			for (i in 0...optionShit.length)
			{
				var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
				
				final menuItem:FlxSprite = new FlxSprite(0, (i * 140) + offset);
				menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
				menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
				menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
				menuItem.animation.play('idle');
				menuItem.ID = i;
				menuItem.screenCenter(X);
				menuItems.add(menuItem);
				
				final scr:Float = optionShit.length < 6 ? 0 : (optionShit.length - 4) * 0.135;
				
				menuItem.scrollFactor.set(0, scr);
				menuItem.updateHitbox();
			}
			
			var gitHash = GitMacro.getGitCommitHash();
			if (gitHash.length != 0) gitHash = ' - dev($gitHash)';
			
			final ver = "Nightmare Vision Engine v" + Main.NMV_VERSION + gitHash + '\nPsych Engine v' + Main.PSYCH_VERSION + "\nFriday Night Funkin' v" + Main.FUNKIN_VERSION;
			
			final verionDesc:FlxText = new FlxText(12, 0, 0, ver, 16);
			verionDesc.setFormat(Paths.font('vcr'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			verionDesc.borderSize = 1.5;
			verionDesc.y = FlxG.height - verionDesc.height - 12;
			verionDesc.scrollFactor.set();
			add(verionDesc);
			
			changeItem();
		}
		super.create();
		
		scriptGroup.call('onCreatePost', []);
	}
	
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}
		
		if (isHardcodedState())
		{
			if (!canInteract)
			{
				if (controls.UI_UP_P || controls.UI_DOWN_P)
				{
					FunkinSound.play(Paths.sound('scrollMenu'));
					changeItem(controls.UI_UP_P ? -1 : 1);
				}
				
				if (controls.BACK)
				{
					canInteract = true;
					FunkinSound.play(Paths.sound('cancelMenu'));
					FlxG.switchState(TitleState.new);
				}
				
				scriptGroup.set('curSelected', curSelected);
				
				if (controls.ACCEPT)
				{
					if (scriptGroup.call('onSelect', [optionShit[curSelected]]) != ScriptConstants.Function_Stop)
					{
						canInteract = true;
						FunkinSound.play(Paths.sound('confirmMenu'));
						
						if (ClientPrefs.flashing && magenta != null) FlxFlicker.flicker(magenta, 1.1, 0.15, false);
						
						final selectedObj = menuItems.members[curSelected];
						
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
						
						menuItems.forEachAlive(s -> if (s != selectedObj) FlxTween.tween(s, {alpha: 0}, 0.4, {ease: FlxEase.quadOut}));
					}
				}
				else if (FlxG.keys.anyJustPressed(debugKeys))
				{
					canInteract = true;
					FlxG.switchState(MasterEditorMenu.new);
				}
			}
		}
		
		super.update(elapsed);
		
		scriptGroup.call('onUpdatePost', [elapsed]);
	}
	
	function changeItem(huh:Int = 0)
	{
		final prevObj = menuItems.members[curSelected];
		prevObj.animation.play('idle');
		prevObj.updateHitbox();
		
		curSelected = FlxMath.wrap(curSelected + huh, 0, menuItems.length - 1);
		
		var newObj = menuItems.members[curSelected];
		newObj.animation.play('selected');
		newObj.centerOffsets();
		
		final add:Float = menuItems.length > 4 ? menuItems.length * 8 : 0;
		camFollow.y = newObj.getGraphicMidpoint().y - add;
		
		scriptGroup.call('onChangeItem', [curSelected]);
	}
}
