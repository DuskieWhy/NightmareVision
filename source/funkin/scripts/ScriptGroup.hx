package funkin.scripts;

import extensions.hscript.Sharables;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

/**
 * Container of `FunkinScript` instances
 */
@:nullSafety(Strict)
class ScriptGroup implements IFlxDestroyable
{
	public var scriptShareables:Sharables = new Sharables();
	
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
			i.parent = value;
			i.sharables = scriptShareables;
		}
		
		return parent;
	}
	
	/**
	 * array of all `FunkinScript` instances
	 */
	public var members:Array<FunkinScript> = [];
	
	public function new(?parent:Dynamic)
	{
		@:privateAccess
		if (FlxG.game != null)
		{
			parent ??= FlxG.state;
		}
		
		@:bypassAccessor this.parent = parent;
	}
	
	/**
	 * Adds a new script to the group
	 * @param script 
	 */
	public function addScript(script:Null<FunkinScript>, allowDupeNames:Bool = false):Bool
	{
		if (script == null || (!allowDupeNames && exists(script.name))) return false;
		@:privateAccess
		if (script.parent != this.parent) script.parent = this.parent;
		script.sharables = scriptShareables;
		members.push(script);
		return true;
	}
	
	public function set(varName:String, arg:Dynamic)
	{
		for (i in members)
		{
			i.set(varName, arg);
		}
	}
	
	public function call(event:String, ?args:Array<Dynamic>, ignoreStops:Bool = false, ?exclusions:Array<String>):Dynamic
	{
		exclusions ??= [];
		var returnVal:Dynamic = ScriptConstants.CONTINUE_FUNC;
		for (i in members)
		{
			// trace('calling $event for ${i.name}');
			if (i == null || !i.exists(event) || exclusions.contains(i.name))
			{
				continue;
			}
			
			var ret:Dynamic = i.call(event, args);
			if (ret != null)
			{
				if (ret == ScriptConstants.HALT_FUNC)
				{
					ret = returnVal;
					if (!ignoreStops) return returnVal;
				};
				
				if (ret != ScriptConstants.CONTINUE_FUNC) returnVal = ret;
			}
		}
		
		return returnVal;
	}
	
	/**
	 * returns a script by name. returns `null` if it cannot be found
	 */
	public function getScript(name:String):Null<FunkinScript>
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
		scriptShareables.clear();
		@:nullSafety(Off)
		scriptShareables = null;
		members = FlxDestroyUtil.destroyArray(members);
		@:bypassAccessor parent = null;
	}
	
	public function clear(callOnDestroy:Bool = true)
	{
		if (callOnDestroy) call('onDestroy', null, true);
		for (i in 0...members.length)
		{
			var script = members[0];
			members.remove(script);
			script.destroy();
		}
	}
}
