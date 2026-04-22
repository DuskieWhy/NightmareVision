package funkin.states.substates;

import funkin.data.SongMetaData;

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

import funkin.backend.Difficulty;
import funkin.utils.CameraUtil;
import funkin.states.options.OptionsState;
import funkin.backend.MusicBeatSubstate;
import funkin.data.*;
import funkin.states.*;
import funkin.objects.*;
import funkin.scripts.*;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var cornerTexts:Array<FlxText> = [];
	
	public static var instance:PauseSubState;
	
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
	
	var debugBG:FlxSprite;
	var debugTxt:FlxText;
	
	override function create()
	{
		var cam:FlxCamera = CameraUtil.lastCamera;
		
		instance = this;
		initStateScript();
		
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
		
		if (songName != null) pauseMusic.loadEmbedded(Paths.music(songName), true, true);
		else if (songName != 'None') pauseMusic.loadEmbedded(Paths.music(Paths.sanitize('breakfast')), true, true);
		
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		
		FlxG.sound.list.add(pauseMusic);
		
		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.setGraphicSize(cam.width, cam.height);
		bg.updateHitbox();
		bg.scrollFactor.set();
		add(bg);
		bg.alpha = 0;
		
		function createCornerText(text:String, addtoo:Bool = false)
		{
			var t = new FlxText(0, 15, cam.width - 15, text, 32);
			t.alignment = RIGHT;
			t.setFormat(Paths.DEFAULT_FONT, 32);
			t.scrollFactor.set();
			cornerTexts.push(t);
			if (addtoo) add(t);
			return t;
		}
		
		var levelInfo = createCornerText(PlayState.SONG.song);
		add(levelInfo);
		
		var levelDifficulty = createCornerText(Difficulty.getCurrentDifficultyString());
		add(levelDifficulty);
		
		// temp just wanted to see this
		var meta:SongMetaData = PlayState.meta;
		if (meta != null)
		{
			if (meta.composers != null) createCornerText("Composers: " + meta.composers.join(', '), true);
			if (meta.charters != null) createCornerText("Charters: " + meta.charters.join(', '), true);
			if (meta.artists != null) createCornerText("Artists: " + meta.artists.join(', '), true);
			if (meta.coders != null) createCornerText("Coders: " + meta.coders.join(', '), true);
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
		for (k => i in cornerTexts)
		{
			i.y = yt - i.height;
			i.alpha = 0;
			FlxTween.tween(i, {alpha: 1, y: yt}, 0.2, {ease: FlxEase.circOut, startDelay: 0.1 * k});
			yt += i.height;
		}
		
		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);
		
		debugBG = new FlxSprite().makeScaledGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		debugBG.alpha = 0;
		add(debugBG);
		
		debugTxt = new FlxText(25, 0, FlxG.width - 50, '', 32);
		debugTxt.setFormat(Paths.DEFAULT_FONT, 32, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		debugTxt.borderSize = 2;
		debugTxt.screenCenter(Y);
		add(debugTxt);
		
		regenMenu();
		cameras = [cam];
		
		super.create();
		
		scriptGroup.call('onCreatePost', []);
	}
	
	var holdTime:Float = 0;
	
	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5) pauseMusic.volume += 0.01 * elapsed;
		
		super.update(elapsed);
		
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
					var maxLength = PlayState.instance?.audio.inst?.length ?? 0.0;
					
					if (curTime >= maxLength) curTime -= maxLength;
					else if (curTime < 0) curTime += maxLength;
					updateSkipTimeText();
				}
		}
		
		if (controls.ACCEPT)
		{
			if (menuItems == difficultyChoices)
			{
				if (menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected))
				{
					debugBG.alpha = 0;
					debugTxt.text = "";
					
					try
					{
						PlayState.SONG = Chart.fromSong(PlayState.SONG.song, curSelected);
					}
					catch (e)
					{
						FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
						debugBG.alpha = 0.7;
						debugTxt.text = Std.string(e);
						return;
					}
					
					PlayState.storyMeta.difficulty = curSelected;
					FlxG.resetState();
					FlxG.sound.music.volume = 0;
					PlayState.changedDifficulty = true;
					PlayState.chartingMode = false;
					skipTimeTracker = null;
					
					deleteSkipTimeText();
					
					return;
				}
				
				menuItems = menuItemsOG;
				regenMenu();
			}
			
			switch (daSelected)
			{
				case 'Options':
					toOptions();
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
				case 'Hawk Tuah Respect Button -->':
					FlxG.sound.play(Paths.sound('untitled1'));
				case "Exit to menu":
					returnToMain();
			}
		}
	}
	
	public function returnToMain()
	{
		if (scriptGroup.call('onExit', []) != ScriptConstants.STOP_FUNC)
		{
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			FlxG.switchState(() -> PlayState.isStoryMode ? new StoryMenuState() : new FreeplayState());
			CoolUtil.cancelMusicFadeTween();
			FunkinSound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
		}
	}
	
	public function toOptions()
	{
		if (scriptGroup.call('onOptions', []) != ScriptConstants.STOP_FUNC)
		{
			PlayState.instance.paused = true;
			PlayState.instance.audio.volume = 0;
			FlxG.switchState(() -> new OptionsState());
			@:privateAccess
			{
				if (pauseMusic._sound != null)
				{
					FunkinSound.playMusic(pauseMusic._sound, 0);
					FlxTween.tween(FlxG.sound.music, {volume: 0.5}, 0.7);
				}
			}
			
			OptionsState.onPlayState = true;
		}
	}
	
	public function restartSong(noTrans:Bool = false)
	{
		if (scriptGroup.call('onRestart', []) != ScriptConstants.STOP_FUNC)
		{
			PlayState.instance.paused = true;
			FlxG.sound.music.volume = 0;
			PlayState.instance.audio.volume = 0;
			
			if (noTrans)
			{
				FlxTransitionableState.skipNextTransOut = true;
			}
			
			FlxG.resetState();
		}
	}
	
	override function destroy()
	{
		pauseMusic.destroy();
		scriptGroup.call('onDestroy', []);
		
		super.destroy();
	}
	
	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);
		
		var ret = scriptGroup.call('onChangeSelection', [curSelected]);
		
		if (ret != ScriptConstants.STOP_FUNC)
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
		
		debugBG.alpha = 0;
		debugTxt.text = "";
	}
	
	function regenMenu():Void
	{
		for (i in 0...grpMenuShit.members.length)
		{
			var obj = grpMenuShit.members[0];
			grpMenuShit.remove(obj, true);
			
			obj = FlxDestroyUtil.destroy(obj);
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
				skipTimeText.setFormat(Paths.DEFAULT_FONT, 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
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
		
		skipTimeText.x = skipTimeTracker.x + (skipTimeTracker?.width ?? 0) + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha == 1);
	}
	
	function updateSkipTimeText()
	{
		final audioLength = PlayState.instance?.audio.inst?.length ?? 0.0;
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false)
			+ ' / '
			+ FlxStringUtil.formatTime(Math.max(0, Math.floor(audioLength / 1000)), false);
	}
	
	function deleteSkipTimeText()
	{
		skipTimeText = FlxDestroyUtil.destroy(skipTimeText);
		
		skipTimeTracker = null;
	}
}
