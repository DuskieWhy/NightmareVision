package funkin.data;

#if macro
import haxe.macro.Context;
#end

// this will actually have relevance when i do hl support
class Defines
{
	public static var defines(get, never):Map<String, Dynamic>;
	
	static function get_defines():Map<String, Dynamic>
	{
		return _getDefines();
	}
	
	static macro function _getDefines()
	{
		return macro $v{Context.getDefines()};
	}
}
