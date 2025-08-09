package hl;

// stupid fixes
#if hl
class HLMath
{
	public static final NEGATIVE_INFINITY:Float = Math.NEGATIVE_INFINITY;
	
	public static final NaN:Float = Math.NaN;
	
	public static final PI:Float = Math.PI;
	
	public static final POSITIVE_INFINITY:Float = Math.POSITIVE_INFINITY;
	
	public static function abs(v:Float):Float return Math.abs(v);
	
	public static function acos(v:Float):Float return Math.acos(v);
	
	public static function asin(v:Float):Float return Math.asin(v);
	
	public static function atan(v:Float):Float return Math.atan(v);
	
	public static function atan2(x:Float, y:Float):Float return Math.atan2(x, y);
	
	public static function ceil(v:Float):Int return Math.ceil(v);
	
	public static function cos(v:Float):Float return Math.cos(v);
	
	public static function exp(v:Float):Float return Math.exp(v);
	
	public static function fceil(v:Float):Float return Math.fceil(v);
	
	public static function ffloor(v:Float):Float return Math.ffloor(v);
	
	public static function floor(v:Float):Int return Math.floor(v);
	
	public static function fround(v:Float):Float return Math.fround(v);
	
	public static function isFinite(v:Float):Bool return Math.isFinite(v);
	
	public static function isNaN(v:Float):Bool return Math.isNaN(v);
	
	public static function max(a:Float, b:Float):Float return Math.max(a, b);
	
	public static function min(a:Float, b:Float):Float return Math.min(a, b);
	
	public static function pow(v:Float, exp:Float):Float return Math.pow(v, exp);
	
	public static function random():Float return Math.random();
	
	public static function round(v:Float):Int return Math.round(v);
	
	public static function sin(v:Float):Float return Math.sin(v);
	
	public static function sqrt(v:Float):Float return Math.sqrt(v);
	
	public static function tan(v:Float):Float return Math.tan(v);
}

class HLStd
{
	public static function int(x:Float):Int return Std.int(x);
	
	public static function isOfType(v:Dynamic, t:Dynamic):Bool return Std.isOfType(v, t);
	
	public static function parseFloat(x:String):Float return Std.parseFloat(x);
	
	public static function parseInt(x:String):Null<Int> return Std.parseInt(x);
	
	public static function random(x:Int):Int return Std.random(x);
	
	public static function string(s:Dynamic):String return Std.string(s);
}
#end
