package funkin.states.options;

import flixel.FlxG;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Gameplay Settings';
		rpcTitle = 'Gameplay Settings Menu'; // for Discord Rich Presence
		
		var option:Option = new Option('Controller Mode', 'Check this if you want to play with\na controller instead of using your Keyboard.', 'controllerMode', 'bool', false);
		addOption(option);
		
		var option:Option = new Option('Mechanics', 'Check this if you want to enable mechanics!', 'mechanics', 'bool', true);
		addOption(option);
		
		// I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Downscroll', // Name
			'If checked, notes go Down instead of Up, simple enough.', // Description
			'downScroll', // Save data variable name
			'bool', // Variable type
			false); // Default value
		addOption(option);
		
		var option:Option = new Option('Middlescroll', 'If checked, your notes get centered.', 'middleScroll', 'bool', false);
		addOption(option);
		
		var option:Option = new Option('Opponent Notes', 'If unchecked, opponent notes get hidden.', 'opponentStrums', 'bool', true);
		addOption(option);
		
		var option:Option = new Option('Ghost Tapping', "If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.", 'ghostTapping', 'bool', true);
		addOption(option);
		
		var option:Option = new Option('Disable Reset Button', "If checked, pressing Reset won't do anything.", 'noReset', 'bool', false);
		addOption(option);
		
		var option:Option = new Option('Hitsound Volume', 'Funny notes does \"Tick!\" when you hit them."', 'hitsoundVolume', 'percent', 0);
		addOption(option);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = onChangeHitsoundVolume;
		
		var option:Option = new Option('Rating Offset', 'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.', 'ratingOffset', 'int', 0);
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);
		
		var option:Option = new Option('Use Epic Ratings', // Name
			'If checked, adds Epic Ratings as a bonus judgement above sick (does not affect accuracy, only your score).', // Description
			'useEpicRankings', // Save data variable name
			'bool', // Variable type
			true); // Default value
		addOption(option);
		
		// Display Name, Variable (in ClientPrefs), Minimum Valeu, Maximum Value, Scroll Speed (when holding down Left/Right)
		addHitWindowOption("Epic!", "epicWindow", 15.0, 22.5, 15);
		addHitWindowOption("Sick!", "sickWindow", 15.0, 45.0, 30);
		addHitWindowOption("Good", "goodWindow", 15.0, 90.0, 60);
		addHitWindowOption("Bad", "badWindow", 15.0, 135.0, 90);
		
		// this is usually 166.67 - AKA: Shit Window
		// i won't change this to be an actual Shit window because it'd break too much to be worth it
		var option:Option = new Option('Safe Frames', 'Changes how many frames you have for\nhitting a note earlier or late.', 'safeFrames', 'float', 10);
		option.scrollSpeed = 5;
		option.minValue = 2.0;
		option.maxValue = 10.0;
		option.changeValue = 0.1;
		addOption(option);
		
		super();
	}
	
	function onChangeHitsoundVolume()
	{
		FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
	}
	
	function addHitWindowOption(dName:String, prefID:String, min:Float = 15.0, max:Float = 200.0, scrollSpeed:Float = 15)
	{
		var option:Option = new Option('$dName Hit Window', 'Changes the amount of time you have\nfor hitting a "$dName" in milliseconds.', prefID, 'float', max);
		option.displayFormat = '%vms';
		option.scrollSpeed = scrollSpeed;
		option.minValue = min;
		option.maxValue = max;
		option.changeValue = 0.1;
		addOption(option);
	}
}
