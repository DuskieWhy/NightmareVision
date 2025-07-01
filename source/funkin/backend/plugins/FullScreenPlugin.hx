package funkin.backend.plugins;

import flixel.FlxBasic;

/**
 * Adds the bind of f11 to fullscreen.
 */
class FullScreenPlugin extends FlxBasic
{
	public static function init()
	{
		FlxG.plugins.addPlugin(new FullScreenPlugin());
	}
	
	public function new()
	{
		super();
		this.visible = false;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (FlxG.keys.justPressed.F11)
		{
			// i was gonna change the actual key to fullscreen but thats like
			// really deep
			// like
			// lime/_backend/native/NativeApplication
			// just to modify it
			// so idk ig u have 2 options now
			
			FlxG.fullscreen = !FlxG.fullscreen;
		}
		
		if (FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;
	}
}
