package funkin.states.options;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxSprite;

import funkin.data.*;
import funkin.states.*;
import funkin.objects.*;

class OptionsState extends MusicBeatState
{
	public static var onPlayState:Bool = false;
	
	var options:Array<String> = [
		'Notes',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals and UI',
		'Gameplay',
		"Loading"
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	
	public function openSelectedSubstate(label:String)
	{
		switch (label)
		{
			case 'Notes':
				openSubState(new funkin.states.options.NoteSettingsSubState());
			case 'Controls':
				openSubState(new funkin.states.options.ControlsSubState());
			case 'Graphics':
				openSubState(new funkin.states.options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new funkin.states.options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new funkin.states.options.GameplaySettingsSubState());
			case 'Loading':
				openSubState(new funkin.states.options.MiscSubState());
			case 'Adjust Delay and Combo':
				CoolUtil.loadAndSwitchState(funkin.states.options.NoteOffsetState.new);
		}
	}
	
	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;
	
	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		
		setUpScript('OptionsState');
		script.set('this', this);
		
		if (isHardcodedState())
		{
			var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
			bg.color = 0xFFea71fd;
			bg.updateHitbox();
			
			bg.screenCenter();
			bg.antialiasing = ClientPrefs.globalAntialiasing;
			add(bg);
			
			grpOptions = new FlxTypedGroup<Alphabet>();
			add(grpOptions);
			
			for (i in 0...options.length)
			{
				var optionText:Alphabet = new Alphabet(0, 0, options[i], true, false);
				optionText.screenCenter();
				optionText.y += (100 * (i - (options.length / 2))) + 50;
				grpOptions.add(optionText);
			}
			
			selectorLeft = new Alphabet(0, 0, '>', true, false);
			add(selectorLeft);
			selectorRight = new Alphabet(0, 0, '<', true, false);
			add(selectorRight);
			
			changeSelection();
		}
		ClientPrefs.flush();
		
		super.create();
	}
	
	override function closeSubState()
	{
		script.call('onCloseSubState', []);
		super.closeSubState();
		ClientPrefs.flush();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (isHardcodedState())
		{
			if (controls.UI_UP_P)
			{
				changeSelection(-1);
			}
			if (controls.UI_DOWN_P)
			{
				changeSelection(1);
			}
			
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				if (onPlayState)
				{
					StageData.loadDirectory(PlayState.SONG);
					CoolUtil.loadAndSwitchState(PlayState.new);
					FlxG.sound.music.volume = 0;
				}
				else FlxG.switchState(MainMenuState.new);
			}
			
			if (controls.ACCEPT)
			{
				openSelectedSubstate(options[curSelected]);
			}
		}
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0) curSelected = options.length - 1;
		if (curSelected >= options.length) curSelected = 0;
		
		var bullShit:Int = 0;
		
		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;
			
			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}
