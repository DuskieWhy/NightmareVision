package funkin.utils;

import funkin.scripts.Globals;

class ReflectUtils
{
	public static function getPropertyLoop(split:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool = true):Dynamic
	{
		var object:Dynamic = getObjectDirectly(split[0], checkForTextsToo);
		var end = split.length;
		if (getProperty) end = split.length - 1;
		
		for (i in 1...end)
		{
			object = getVarInArray(object, split[i]);
		}
		return object;
	}
	
	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic
	{
		var object:Dynamic = PlayState.instance.getLuaObject(objectName, checkForTextsToo);
		
		if (object == null) object = getVarInArray(Globals.getInstance(), objectName);
		
		return object;
	}
	
	public static function getVarInArray(instance:Dynamic, variable:String):Any
	{
		var props:Array<String> = variable.split('[');
		if (props.length > 1)
		{
			var blah:Dynamic = Reflect.getProperty(instance, props[0]);
			for (i in 1...props.length)
			{
				var leNum:Dynamic = props[i].substr(0, props[i].length - 1);
				blah = blah[leNum];
			}
			return blah;
		}
		if (instance.exists != null && instance.keyValueIterator != null) return instance.get(variable);
		else return Reflect.getProperty(instance, variable);
	}
}
