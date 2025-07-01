package funkin.scripting;

import funkin.scripts.FunkinIris;

/**
 * Class that handles plugin like scripts.
 * 
 * these scripts are always running in the background.
 */
class HScriptManager
{
	/**
	 * All scripts loaded by name
	 */
	public static final loadedScripts:Map<String, FunkinIris> = [];
	
	/**
	 * Populates scripts for use
	 */
	public static function build() {}
	
	/**
	 * sets some flxsignals for use on scripts
	 */
	static function prepare() {}
	
	/**
	 * Clears all scripts
	 */
	public static function clear() {}
	
	/**
	 * Calls a function on the global scripts.
	 */
	public static function dispatchOnScripts() {}
}
