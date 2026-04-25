package funkin.states.options;

import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;

import funkin.backend.DebugDisplay;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Graphics';
		rpcTitle = 'Graphics Settings Menu'; // for Discord Rich Presence
		
		var option:Option = new Option('GPU Caching', 'If checked, GPU caching will be enabled.', 'gpuCaching', BOOL, false);
		addOption(option);
		
		// I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', // Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', // Description
			'lowQuality', // Save data variable name
			'bool', // Variable type
			false); // Default value
		addOption(option);
		
		var option:Option = new Option('Shaders', 'If checked, shaders will be enabled across the mod', 'shaders', BOOL, true);
		addOption(option);
		
		var option:Option = new Option('Anti-Aliasing', 'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.', 'globalAntialiasing', BOOL, true);
		option.onChange = onChangeAntiAliasing; // Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);
		
		var option:Option = new Option('Time Bar:', "What should the Time Bar display?", 'timeBarType', STRING, 'Time Left', ['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		addOption(option);
		
		var option:Option = new Option('Debug Display Type',
			'Handles what type of information to display in the top left of your screen.\nSimple displays FPS & Memory, and advanced displays the same alongside debug information.\nDisabled disables the counter entirely.',
			'fpsDisplayType', STRING, 'Simple', ['Simple', 'Advanced', 'Disabled']);
		addOption(option);
		
		var option:Option = new Option('Framerate', "Pretty self explanatory, isn't it?", 'framerate', INT, 60);
		addOption(option);
		
		option.minValue = 60;
		option.maxValue = 400;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		
		var option:Option = new Option('Unlocked Framerate', "Pretty self explanatory, isn't it?", 'unlockedFramerate', 'bool', false);
		addOption(option);
		
		option.onChange = onChangeFramerate;
		
		super();
	}
	
	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			if (sprite != null && (sprite is FlxSprite) && !(sprite is FlxText))
			{
				(cast sprite : FlxSprite).antialiasing = ClientPrefs.globalAntialiasing;
			}
		}
		
		FlxSprite.defaultAntialiasing = ClientPrefs.globalAntialiasing;
	}
	
	function onChangeFramerate()
	{
		ClientPrefs.changeFps(ClientPrefs.framerate);
	}
}
