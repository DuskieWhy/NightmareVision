package funkin.states.options;

import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Graphics';
		rpcTitle = 'Graphics Settings Menu'; // for Discord Rich Presence
		
		// I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', // Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', // Description
			'lowQuality', // Save data variable name
			'bool', // Variable type
			false); // Default value
		addOption(option);
		
		var option:Option = new Option('Shaders', 'If checked, shaders will be enabled across the mod', 'shaders', 'bool', true);
		addOption(option);
		
		var option:Option = new Option('Anti-Aliasing', 'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.', 'globalAntialiasing', 'bool', true);
		// option.showBoyfriend = true;
		option.onChange = onChangeAntiAliasing; // Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);
		
		var option:Option = new Option('Framerate', "Pretty self explanatory, isn't it?", 'framerate', 'int', 60);
		addOption(option);
		
		option.minValue = 60;
		option.maxValue = 240;
		option.displayFormat = '%v FPS';
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
		if (ClientPrefs.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.framerate;
			FlxG.drawFramerate = ClientPrefs.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.framerate;
			FlxG.updateFramerate = ClientPrefs.framerate;
		}
	}
}
