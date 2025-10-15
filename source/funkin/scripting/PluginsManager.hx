package funkin.scripting;

import funkin.scripts.ScriptGroup;
import funkin.scripts.FunkinScript;

/**
 * Class that handles plugin like scripts.
 * 
 * these scripts are always running in the background.
 */
class PluginsManager
{
	/**
	 * All scripts loaded by name
	 */
	public static final loadedScripts:ScriptGroup = new ScriptGroup();
	
	/**
	 * Populates scripts for use
	 */
	public static function populate()
	{
		clear();
		for (file in Paths.listAllFilesInDirectory('scripts/plugins/'))
		{
			if (FunkinScript.isHxFile(file))
			{
				final scriptName = file.withoutDirectory().withoutExtension();
				
				var script = FunkinScript.fromFile(file, scriptName);
				if (script.__garbage)
				{
					script = FlxDestroyUtil.destroy(script);
					continue;
				}
				
				loadedScripts.addScript(script, true);
				if (script.exists('onLoad')) script.call('onLoad');
			}
		}
	}
	
	/**
	 * sets some flxsignals for use on scripts
	 */
	public static function prepareSignals()
	{
		FlxG.signals.postStateSwitch.add(onStateSwitchPost);
		FlxG.signals.preStateSwitch.add(onStateSwitch);
	}
	
	/**
	 * Clears all scripts
	 */
	public static function clear()
	{
		loadedScripts.clear(true);
	}
	
	/**
	 * Calls a function on the global scripts.
	 */
	public static function callOnScripts(func:String, ?args:Array<Dynamic>)
	{
		loadedScripts.call(func, args);
	}
	
	static function onStateSwitchPost()
	{
		callOnScripts('onStateSwitchPost', [FlxG.state]);
	}
	
	static function onStateSwitch()
	{
		callOnScripts('onStateSwitch', [FlxG.state]);
	}
}
