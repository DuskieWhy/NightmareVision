package funkin.states.editors;

import funkin.objects.Character;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import funkin.data.*;
import funkin.objects.*;

class MasterEditorMenu extends MusicBeatState
{
	var options:Array<String> = [
		'Week Editor',
		'Menu Character Editor',
		'Dialogue Editor',
		'Dialogue Portrait Editor',
		'Character Editor',
		'Chart Editor',
		'Note Skin Editor',
		'Chart Converter'
	];
	private var grpTexts:FlxTypedGroup<Alphabet>;
	private var directories:Array<String> = [null];
	
	private var curSelected = 0;
	private var curDirectory = 0;
	private var directoryTxt:FlxText;
	
	override function create()
	{
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Editors Main Menu");
		
		persistentUpdate = true;
		
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);
		
		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);
		
		for (i in 0...options.length)
		{
			var leText:Alphabet = new Alphabet(0, (70 * i) + 30, options[i], true, false);
			leText.isMenuItem = true;
			leText.targetY = i;
			grpTexts.add(leText);
		}
		
		#if MODS_ALLOWED
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42).makeGraphic(FlxG.width, 42, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);
		
		directoryTxt = new FlxText(textBG.x, textBG.y + 4, FlxG.width, '', 32);
		directoryTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		directoryTxt.scrollFactor.set();
		add(directoryTxt);
		
		for (folder in Mods.getModDirectories())
		{
			directories.push(folder);
		}
		
		var found:Int = directories.indexOf(Mods.currentModDirectory);
		if (found > -1) curDirectory = found;
		changeDirectory();
		#end
		changeSelection();
		
		FlxG.mouse.visible = false;
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}
		#if MODS_ALLOWED
		if (controls.UI_LEFT_P)
		{
			changeDirectory(-1);
		}
		if (controls.UI_RIGHT_P)
		{
			changeDirectory(1);
		}
		#end
		
		if (controls.BACK)
		{
			FlxG.switchState(() -> new MainMenuState());
		}
		
		if (controls.ACCEPT)
		{
			switch (options[curSelected])
			{
				case 'Character Editor':
					FlxG.switchState(() -> new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
				case 'Week Editor':
					FlxG.switchState(() -> new WeekEditorState());
				case 'Menu Character Editor':
					FlxG.switchState(() -> new MenuCharacterEditorState());
				case 'Dialogue Portrait Editor':
					FlxG.switchState(DialogueCharacterEditorState.new);
				case 'Dialogue Editor':
					FlxG.switchState(DialogueEditorState.new);
				case 'Chart Editor': // felt it would be cool maybe
					FlxG.switchState(ChartEditorState.new);
				case 'Note Skin Editor':
					FlxG.switchState(() -> new NoteSkinEditor('default'));
				case 'Chart Converter':
					FlxG.switchState(() -> new ChartConverterState());
			}
			if (FlxG.sound.music != null) FlxG.sound.music.volume = 0;
			FreeplayState.destroyFreeplayVocals();
		}
		
		var bullShit:Int = 0;
		for (item in grpTexts.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;
			
			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));
			
			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		super.update(elapsed);
	}
	
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		curSelected += change;
		
		if (curSelected < 0) curSelected = options.length - 1;
		if (curSelected >= options.length) curSelected = 0;
	}
	
	#if MODS_ALLOWED
	function changeDirectory(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		curDirectory += change;
		
		if (curDirectory < 0) curDirectory = directories.length - 1;
		if (curDirectory >= directories.length) curDirectory = 0;
		
		WeekData.setDirectoryFromWeek();
		if (directories[curDirectory] == null || directories[curDirectory].length < 1) directoryTxt.text = '< No Mod Directory Loaded >';
		else
		{
			Mods.currentModDirectory = directories[curDirectory];
			directoryTxt.text = '< Loaded Mod Directory: ' + Mods.currentModDirectory + ' >';
		}
		directoryTxt.text = directoryTxt.text.toUpperCase();
	}
	#end
}
