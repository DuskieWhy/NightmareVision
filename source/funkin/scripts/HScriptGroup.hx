package funkin.scripts;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

import funkin.scripts.Globals;

/**
 * Container of `FunkinIris` instances
 * 
 * NOT DONE
 * 
 * idea from friens static fyr thanks
 */
class HScriptGroup implements IFlxDestroyable
{
	/**
	 * Global interp parent applied to all scripts in the group
	 */
	public var parent(default, set):Dynamic;
	
	function set_parent(value:Dynamic)
	{
		parent = value;
		for (i in members)
		{
			i.interp.parent = parent;
		}
		
		return parent;
	}
	
	/**
	 * array of all `FunkinIris` instances
	 */
	public var members:Array<FunkinIris> = [];
	
	public function new()
	{
		@:bypassAccessor this.parent = FlxG.state;
	}
	
	/**
	 * Adds a new script to the group
	 * @param script 
	 */
	public function addScript(script:FunkinIris)
	{
		if (script == null) return;
		script.interp.parent = parent;
		members.push(script);
	}
	
	@:inheritDoc(funkin.scripts.FunkinScript.set)
	public function set(varName:String, arg:Dynamic)
	{
		for (i in members)
		{
			i.set(varName, arg);
		}
	}
	
	@:inheritDoc(funkin.scripts.FunkinScript.call)
	public function call(event:String, ?args:Array<Dynamic>, ignoreStops:Bool = false, ?exclusions:Array<String>)
	{
		exclusions ??= [];
		var returnVal:Dynamic = Globals.Function_Continue;
		for (i in members)
		{
			if (exclusions.contains(i.scriptName))
			{
				continue;
			}
			
			var ret:Dynamic = i.call(event, args);
			if (ret == Globals.Function_Halt)
			{
				ret = returnVal;
				if (!ignoreStops) return returnVal;
			};
			
			if (ret != null && ret != Globals.Function_Continue) returnVal = ret;
		}
		// returnVal ??= Globals.Function_Continue;
		
		return returnVal;
	}
	
	public function getScript(scriptName:String)
	{
		for (i in members)
		{
			if (scriptName == i.scriptName) return i;
		}
		
		return null;
	}
	
	/**
	 * Destroys all members
	 */
	public function destroy()
	{
		members = FlxDestroyUtil.destroyArray(members);
	}
}
