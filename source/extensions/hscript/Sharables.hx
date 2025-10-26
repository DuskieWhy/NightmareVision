package extensions.hscript;

// typedef Sharables = Map<String, Dynamic>;

/**
 * Optional class to be used with `IrisEx`.
 * 
 * Scripts that share a `Sharables` instance are able to natively access eachothers public variables
 * 
 * Inspired by Rulescripts `Context`
 */
class Sharables
{
	public function new() {}
	
	public inline function exists(id:String)
	{
		return fields.exists(id);
	}
	
	public inline function get(id:String)
	{
		return fields.get(id);
	}
	
	public inline function set(id:String, value:Dynamic)
	{
		return fields.set(id, value);
	}
	
	public inline function remove(id:String)
	{
		return fields.remove(id);
	}
	
	public inline function clear()
	{
		fields.clear();
	}
	
	public var fields:Map<String, Dynamic> = [];
}
