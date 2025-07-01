package funkin.states.substates;

import funkin.backend.Difficulty;
import funkin.utils.CameraUtil;
import funkin.states.options.OptionsState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.util.FlxStringUtil;

import funkin.backend.MusicBeatSubstate;
import funkin.data.*;
import funkin.states.*;
import funkin.objects.*;
import funkin.scripts.*;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	
	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit to menu'];
	var difficultyChoices = [];
	var curSelected:Int = 0;
	
	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);
	
	// var botplayText:FlxText;
	public static var songName:String = '';
	
	override function create()
	{
		var cam:FlxCamera = CameraUtil.lastCamera;
		
		setUpScript('PauseSubState');
		
		if (isHardcodedState())
		{
			if (Difficulty.difficulties.length < 2) menuItemsOG.remove('Change Difficulty'); // No need to change difficulty if there is only one!
			
			if (PlayState.chartingMode #if debug || true #end)
			{
				var shit:Int = 2;
				if (PlayState.chartingMode)
				{
					menuItemsOG.insert(shit, 'Leave Charting Mode');
					shit++;
				}
				
				var num:Int = 0;
				if (!PlayState.instance.startingSong)
				{
					num = 1;
					menuItemsOG.insert(shit, 'Skip Time');
				}
				menuItemsOG.insert(shit + num, 'End Song');
				menuItemsOG.insert(shit + num, 'Toggle Practice Mode');
				menuItemsOG.insert(shit + num, 'Toggle Botplay');
				// menuItemsOG.insert(shit + num, 'Hawk Tuah Respect Button -->');
			}
			menuItems = menuItemsOG;
			
			for (i in 0...Difficulty.difficulties.length)
			{
				var diff:String = '' + Difficulty.difficulties[i];
				difficultyChoices.push(diff);
			}
			difficultyChoices.push('BACK');
			
			pauseMusic = new FlxSound();
			try
			{
				if (songName != null)
				{
					pauseMusic.loadEmbedded(Paths.music(songName), true, true);
				}
				else if (songName != 'None')
				{
					pauseMusic.loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic)), true, true);
				}
				pauseMusic.volume = 0;
				pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
			}
			catch (e) {}
			FlxG.sound.list.add(pauseMusic);
			
			var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			bg.setGraphicSize(cam.width, cam.height);
			bg.updateHitbox();
			bg.scrollFactor.set();
			add(bg);
			bg.alpha = 0;
			
			var corners:Array<FlxText> = [];
			function createCornerText(text:String, addto:Bool = false)
			{
				var t = new FlxText(0, 15, cam.width - 15, text, 32);
				t.alignment = RIGHT;
				t.setFormat(Paths.font("vcr.ttf"), 32);
				t.scrollFactor.set();
				corners.push(t);
				if (addto) add(t);
				return t;
			}
			
			var levelInfo = createCornerText(PlayState.SONG.song);
			add(levelInfo);
			
			var levelDifficulty = createCornerText(Difficulty.getCurDifficulty());
			add(levelDifficulty);
			
			// temp just wanted to see this
			var meta:Metadata = PlayState.meta;
			if (meta != null)
			{
				if (meta.composers != null) createCornerText("Composers: " + meta.composers, true);
				if (meta.charters != null) createCornerText("Charters: " + meta.charters, true);
				if (meta.artists != null) createCornerText("Artists: " + meta.artists, true);
				if (meta.coders != null) createCornerText("Coders: " + meta.coders, true);
			}
			
			var blueballedTxt = createCornerText("Blueballed: " + PlayState.deathCounter);
			add(blueballedTxt);
			
			practiceText = createCornerText("PRACTICE MODE");
			practiceText.visible = PlayState.instance.practiceMode;
			add(practiceText);
			
			var chartingText = createCornerText("CHARTING MODE");
			add(chartingText);
			chartingText.visible = PlayState.chartingMode;
			
			FlxTween.tween(bg, {alpha: 0.6}, 0.4);
			
			var yt:Float = 15;
			for (k => i in corners)
			{
				i.y = yt - i.height;
				i.alpha = 0;
				FlxTween.tween(i, {alpha: 1, y: yt}, 0.2, {ease: FlxEase.circOut, startDelay: 0.1 * k});
				yt += i.height;
			}
			
			grpMenuShit = new FlxTypedGroup<Alphabet>();
			add(grpMenuShit);
			
			regenMenu();
			cameras = [cam];
		}
		
		super.create();
	}
	
	var holdTime:Float = 0;
	
	override function update(elapsed:Float)
	{
		if (isHardcodedState()) if (pauseMusic.volume < 0.5) pauseMusic.volume += 0.01 * elapsed;
		
		super.update(elapsed);
		
		if (isHardcodedState())
		{
			if (skipTimeText != null && skipTimeTracker != null) updateSkipTextStuff();
			
			if (controls.UI_UP_P)
			{
				changeSelection(-1);
			}
			if (controls.UI_DOWN_P)
			{
				changeSelection(1);
			}
			
			var daSelected:String = menuItems[curSelected];
			switch (daSelected)
			{
				case 'Skip Time':
					if (controls.UI_LEFT_P)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
						curTime -= 1000;
						holdTime = 0;
					}
					if (controls.UI_RIGHT_P)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
						curTime += 1000;
						holdTime = 0;
					}
					
					if (controls.UI_LEFT || controls.UI_RIGHT)
					{
						holdTime += elapsed;
						if (holdTime > 0.5)
						{
							curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
						}
						
						if (curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
						else if (curTime < 0) curTime += FlxG.sound.music.length;
						updateSkipTimeText();
					}
			}
			
			if (controls.ACCEPT)
			{
				if (menuItems == difficultyChoices)
				{
					if (menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected))
					{
						var name:String = PlayState.SONG.song;
						var poop = Highscore.formatSong(name, curSelected);
						PlayState.SONG = Song.loadFromJson(poop, name);
						PlayState.storyDifficulty = curSelected;
						FlxG.resetState();
						FlxG.sound.music.volume = 0;
						PlayState.changedDifficulty = true;
						PlayState.chartingMode = false;
						skipTimeTracker = null;
						
						if (skipTimeText != null)
						{
							skipTimeText.kill();
							remove(skipTimeText);
							skipTimeText.destroy();
						}
						skipTimeText = null;
						return;
					}
					
					menuItems = menuItemsOG;
					regenMenu();
				}
				
				switch (daSelected)
				{
					case 'Options':
						PlayState.instance.paused = true; // For lua
						PlayState.instance.vocals.volume = 0;
						FlxG.switchState(() -> new OptionsState());
						@:privateAccess
						{
							if (pauseMusic._sound != null)
							{
								FlxG.sound.playMusic(pauseMusic._sound, 0);
								FlxTween.tween(FlxG.sound.music, {volume: 0.5}, 0.7);
							}
						}
						
						OptionsState.onPlayState = true;
					case "Resume":
						close();
					case 'Change Difficulty':
						menuItems = difficultyChoices;
						regenMenu();
					case 'Toggle Practice Mode':
						PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
						PlayState.changedDifficulty = true;
						practiceText.visible = PlayState.instance.practiceMode;
					case "Restart Song":
						restartSong();
					case "Leave Charting Mode":
						restartSong();
						PlayState.chartingMode = false;
					case 'Skip Time':
						if (curTime < Conductor.songPosition)
						{
							PlayState.startOnTime = curTime;
							restartSong(true);
						}
						else
						{
							if (curTime != Conductor.songPosition)
							{
								PlayState.instance.clearNotesBefore(curTime);
								PlayState.instance.setSongTime(curTime);
							}
							close();
						}
					case "End Song":
						close();
						PlayState.instance.finishSong(true);
					case 'Toggle Botplay':
						PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
						PlayState.changedDifficulty = true;
						PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
						PlayState.instance.botplayTxt.alpha = 1;
						PlayState.instance.botplaySine = 0;
					case 'Hawk Tuah Respect Button -->':
						FlxG.sound.play(Paths.sound('untitled1'));
					case "Exit to menu":
						PlayState.deathCounter = 0;
						PlayState.seenCutscene = false;
						FlxG.switchState(() -> PlayState.isStoryMode ? new StoryMenuState() : new FreeplayState());
						CoolUtil.cancelMusicFadeTween();
						FlxG.sound.playMusic(Paths.music('freakyMenu'));
						PlayState.changedDifficulty = false;
						PlayState.chartingMode = false;
				}
			}
		}
	}
	
	public function restartSong(noTrans:Bool = false)
	{
		if (scriptGroup.call('onRestart', []) != Globals.Function_Stop)
		{
			PlayState.instance.paused = true; // For lua
			FlxG.sound.music.volume = 0;
			PlayState.instance.vocals.volume = 0;
			
			if (noTrans)
			{
				FlxTransitionableState.skipNextTransOut = true;
			}
			
			FlxG.resetState();
		}
	}
	
	override function destroy()
	{
		if (isHardcodedState()) pauseMusic.destroy();
		scriptGroup.call('onDestroy', []);
		
		super.destroy();
	}
	
	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);
		var ret = scriptGroup.call('onChangeSelection', [curSelected]);
		
		if (ret != Globals.Function_Stop)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			
			for (k => item in grpMenuShit.members)
			{
				item.targetY = k - curSelected;
				
				item.alpha = 0.6;
				if (item.targetY == 0)
				{
					item.alpha = 1;
					
					if (item == skipTimeTracker)
					{
						curTime = Math.max(0, Conductor.songPosition);
						updateSkipTimeText();
					}
				}
			}
		}
	}
	
	function regenMenu():Void
	{
		for (i in 0...grpMenuShit.members.length)
		{
			var obj = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}
		
		for (i in 0...menuItems.length)
		{
			var item = new Alphabet(0, 70 * i + 30, menuItems[i], true, false);
			item.isMenuItem = true;
			item.targetY = i;
			grpMenuShit.add(item);
			
			if (menuItems[i] == 'Skip Time')
			{
				skipTimeText = new FlxText(0, 0, 0, '', 64);
				skipTimeText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;
				skipTimeTracker = item;
				add(skipTimeText);
				
				updateSkipTextStuff();
				updateSkipTimeText();
			}
			if (menuItems[i] == 'Hawk Tuah Respect Button -->')
			{
				var textScale:Float = 0.5;
				item.scale.x = textScale;
				for (letter in item.lettersArray)
				{
					letter.x *= textScale;
					letter.offset.x *= textScale;
				}
				
				var eyes = new HealthIcon('hawk');
				eyes.sprTracker = item;
				eyes.animation.curAnim.curFrame = FlxG.random.bool(12.5) ? 1 : 0;
				add(eyes);
			}
		}
		curSelected = 0;
		changeSelection();
		scriptGroup.call('onRegenMenu', []);
	}
	
	function updateSkipTextStuff()
	{
		if (skipTimeText == null || skipTimeTracker == null) return;
		
		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha == 1);
	}
	
	function updateSkipTimeText()
	{
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false)
			+ ' / '
			+ FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}
	
	function deleteSkipTimeText()
	{
		if (skipTimeText != null)
		{
			skipTimeText.kill();
			remove(skipTimeText);
			skipTimeText.destroy();
		}
		skipTimeText = null;
		skipTimeTracker = null;
	}
}
