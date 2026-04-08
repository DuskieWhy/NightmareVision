package funkin.states.options;

import funkin.states.options.Option;

import flixel.FlxG;

class VisualsUISubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu'; // for Discord Rich Presence
		
		var option:Option = new Option('Hide HUD', 'If checked, hides most HUD elements.', 'hideHud', 'bool', false);
		addOption(option);
		
		var option:Option = new Option('HUD Style:', "What style should the HUD use?", 'hudStyle', 'string', 'NightmareVision', ['NightmareVision', 'Psych', 'Kade', 'Classic']);
		addOption(option);
		
		var option:Option = new Option('Show Ratings', 'If checked, rating graphics will appear on your HUD.', 'showRatings', 'bool', true);
		addOption(option);
		
		var option:Option = new Option('Health Bar Transparency', 'How much transparent should the health bar and icons be.', 'healthBarAlpha', 'percent', 1);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);
		
		var option:Option = new Option('Time Bar:', "What should the Time Bar display?", 'timeBarType', 'string', 'Time Left', ['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		addOption(option);
		
		var option:Option = new Option('Score Text Zoom on Hit', "If unchecked, disables the Score text zooming\neverytime you hit a note.", 'scoreZoom', 'bool', true);
		addOption(option);
		
		var option:Option = new Option('Camera Zooms', "If unchecked, the camera won't zoom in on a beat hit.", 'camZooms', 'bool', true);
		addOption(option);
		
		var option:Option = new Option('Flashing Lights', "Uncheck this if you're sensitive to flashing lights!", 'flashing', 'bool', true);
		addOption(option);
		
		var option:Option = new Option('Jump Ghosts', "If unchecked, disables characters playing a 'ghost' animation on jumps.", 'jumpGhosts', 'bool', false);
		addOption(option);
		
		// var option:Option = new Option('Darnell mode.', "darnell.", 'darnell', 'bool', false);
		// addOption(option);
		
		var option:Option = new Option('Camera Note Follow', "If unchecked, hitting notes will no longer have the camera follow in its direction.", 'camFollowsCharacters', 'bool', true);
		addOption(option);
		
		super();
	}
}
