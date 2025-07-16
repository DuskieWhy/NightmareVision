package funkin.scripts;

import extensions.InterpEx;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

import funkin.scripts.Globals;

/**
 * Container of `FunkinHScript` instances
 * 
 * idea from friens static fyr thanks
 */
@:nullSafety(Strict)
class HScriptGroup implements IFlxDestroyable
{
	/**
	 * Global interp parent applied to all scripts in the group
	 */
	public var parent(default, set):Dynamic;
	
	function set_parent(value:Dynamic)
	{
		parent = value;
		@:privateAccess
		for (i in members)
		{
			final interp:InterpEx = cast i.interp;
			if (interp.parent != parent)
			{
				interp.parent = parent;
			}
		}
		
		return parent;
	}
	
	/**
	 * array of all `FunkinHScript` instances
	 */
	public var members:Array<FunkinHScript> = [];
	
	public function new(?parent:Dynamic)
	{
		parent ??= FlxG.state;
		@:bypassAccessor this.parent = parent;
	}
	
	/**
	 * Adds a new script to the group
	 * @param script 
	 */
	public function addScript(script:FunkinHScript, allowDupeNames:Bool = false):Bool
	{
		if (script == null || (!allowDupeNames && exists(script.name))) return false;
		
		@:privateAccess
		final interp:InterpEx = cast script.interp;
		if (interp.parent != parent) interp.parent = parent;
		members.push(script);
		return true;
	}
	
	@:inheritDoc(funkin.scripts.FunkinHScript.set)
	public function set(varName:String, arg:Dynamic)
	{
		for (i in members)
		{
			i.set(varName, arg);
		}
	}
	
	@:inheritDoc(funkin.scripts.FunkinHScript.call)
	public function call(event:String, ?args:Array<Dynamic>, ignoreStops:Bool = false, ?exclusions:Array<String>):Dynamic
	{
		exclusions ??= [];
		var returnVal:Dynamic = Globals.Function_Continue;
		for (i in members)
		{
			if (i == null || !i.exists(event) || exclusions.contains(i.name))
			{
				continue;
			}
			
			var ret:Dynamic = i.call(event, args)?.returnValue;
			if (ret != null)
			{
				if (ret == Globals.Function_Halt)
				{
					ret = returnVal;
					if (!ignoreStops) return returnVal;
				};
				
				if (ret != Globals.Function_Continue) returnVal = ret;
			}
		}
		
		return returnVal;
	}
	
	/**
	 * returns a script by name. returns `null` if it cannot be found
	 */
	public function getScript(name:String):Null<FunkinHScript>
	{
		for (script in members)
			if (script.name == name) return script;
			
		return null;
	}
	
	/**
	 * Is true if a script with the given name exists
	 */
	public function exists(name:String):Bool
	{
		for (script in members)
			if (script.name == name) return true;
		return false;
	}
	
	/**
	 * Destroys all members
	 */
	public function destroy()
	{
		members = FlxDestroyUtil.destroyArray(members);
		@:bypassAccessor parent = null;
	}
}

// this might be better..?

class HScriptContainer extends HScriptGroup {}
