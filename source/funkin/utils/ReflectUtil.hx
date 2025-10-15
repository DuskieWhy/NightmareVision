package funkin.utils;

class ReflectUtil
{
	public static function getPropertyLoop(split:Array<String>, getProperty:Bool = true):Dynamic
	{
		var object:Dynamic = getObjectDirectly(split[0]);
		var end = split.length;
		if (getProperty) end = split.length - 1;
		
		for (i in 1...end)
		{
			object = getVarInArray(object, split[i]);
		}
		return object;
	}
	
	public static function getObjectDirectly(objectName:String):Dynamic
	{
		var object:Dynamic = PlayState.instance?.getModchartObject(objectName);
		
		if (object == null) object = getVarInArray(ScriptConstants.getInstance(), objectName);
		
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
	
	/**
	 * Identical to `Reflect.getProperty` but allows for nested fields
	 */
	@:inheritDoc(Reflect.getProperty)
	public static function getProperty(obj:Dynamic, field:String):Null<Dynamic>
	{
		if (!field.contains('.')) return Reflect.getProperty(obj, field);
		
		final splitFields = field.split('.');
		
		var property:Dynamic = Reflect.getProperty(obj, splitFields.shift());
		
		while (splitFields.length > 0)
		{
			property = Reflect.getProperty(property, splitFields.shift());
		}
		
		return property;
	}
	
	/**
	 * Identical to `Reflect.setProperty` but allows for nested fields
	 */
	@:inheritDoc(Reflect.setProperty)
	public static function setProperty(obj:Dynamic, field:String, value:Dynamic):Void
	{
		if (!field.contains('.'))
		{
			Reflect.setProperty(obj, field, value);
			return;
		}
		
		final splitFields = field.split('.');
		
		var property:Dynamic = Reflect.getProperty(obj, splitFields.shift());
		
		while (splitFields.length > 1)
		{
			property = Reflect.getProperty(property, splitFields.shift());
		}
		
		Reflect.setProperty(property, splitFields[0], value);
	}
}
