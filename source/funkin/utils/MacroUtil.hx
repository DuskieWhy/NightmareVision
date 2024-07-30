package funkin.utils;

import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.Tools;
class MacroUtil
{
    public static macro function getDate() 
    {
        return macro $v{Date.now().toString()};
    }


	public static macro function include(path:String) 
    {
		haxe.macro.Compiler.include(path);
		return macro $v{0};
	}
}
