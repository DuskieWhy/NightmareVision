package funkin.utils;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.Tools;

using Lambda;
#end

class MacroUtil
{
	/**
	 * enforces the use of haxe 4.3.4
	 */
	public static macro function haxeVersionEnforcement()
	{
		#if (haxe_ver < "4.3.4")
		Context.fatalError('use haxe 4.3.4 or newer thx', (macro null).pos);
		#end
		
		return macro $v{0};
	}
	
	// might rewrite this one
	
	/**
	 * ONLY USE FOR ABSTRACTED CLASSES THAT ARE JUST VARS does nothing for anything else 
	 * Builds a anon strcture from static uppercase inline variables in an abstract type.
	 * ripped from FlxMacroUtil but modified to fit my needs
	 * https://code.haxe.org/category/macros/combine-objects.html
	 * https://github.com/HaxeFlixel/flixel/blob/master/flixel/system/macros/FlxMacroUtil.hx
	 */
	public static macro function buildAbstract(typePath:Expr, ?exclude:Array<String>)
	{
		var type = Context.getType(typePath.toString());
		var expressions:Array<ObjectField> = [];
		
		if (exclude == null) exclude = ["NONE"];
		
		switch (type.follow())
		{
			case TAbstract(_.get() => ab, _):
				for (f in ab.impl.get().statics.get())
				{
					switch (f.kind)
					{
						case FVar(AccInline, _):
							switch (f.expr().expr)
							{
								case TCast(Context.getTypedExpr(_) => expr, _):
									if (f.name.toUpperCase() == f.name && exclude.indexOf(f.name) == -1) // uppercase?
									{
										expressions.push({field: f.name, expr: expr});
									}
									
								default:
							}
							
						default:
					}
				}
			default:
		}
		
		var finalResult = {expr: EObjectDecl(expressions), pos: Context.currentPos()};
		return macro $b{[macro $finalResult]};
	}
}
