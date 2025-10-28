package funkin.scripting;

import funkin.scripts.ScriptGroup;
import funkin.scripts.FunkinScript;

/**
 * Class that handles plugin like scripts.
 * 
 * these scripts are always running in the background.
 */
@:nullSafety
class PluginsManager
{
	/**
	 * All scripts loaded by name
	 */
	public static final loadedScripts:ScriptGroup = new ScriptGroup();
	
	/**
	 * Populates scripts for use
	 */
	public static function populate():Void
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
	public static function prepareSignals():Void
	{
		FlxG.signals.postStateSwitch.add(onStateSwitchPost);
		FlxG.signals.preStateSwitch.add(onStateSwitch);
	}
	
	/**
	 * Clears all loaded plugins
	 */
	public static function clear():Void
	{
		loadedScripts.clear(true);
	}
	
	/**
	 * Calls a function on the global scripts.
	 */
	public static function callOnScripts(func:String, ?args:Array<Dynamic>):Void
	{
		loadedScripts.call(func, args);
	}
	
	public static function getPlugin(plugin:String):Null<FunkinScript>
	{
		return loadedScripts.getScript(plugin);
	}
	
	public static function callPluginFunc(plugin:String, func:String, ?args:Array<Dynamic>):Null<Dynamic>
	{
		final script = getPlugin(plugin);
		
		if (script == null) return null;
		
		return script.call(func, args).returnValue;
	}
	
	static function onStateSwitchPost():Void
	{
		callOnScripts('onStateSwitchPost', [FlxG.state]);
	}
	
	static function onStateSwitch():Void
	{
		callOnScripts('onStateSwitch', [FlxG.state]);
	}
}
