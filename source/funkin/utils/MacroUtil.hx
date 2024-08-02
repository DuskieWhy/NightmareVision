package funkin.utils;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
using haxe.macro.Tools;
using Lambda;
 #end
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

    //https://code.haxe.org/category/macros/combine-objects.html
    //https://github.com/HaxeFlixel/flixel/blob/master/flixel/system/macros/FlxMacroUtil.hx
    /**
    * wip!! Cannot build non abstracted enums yet!!!!
    * Builds a anon strcture from static uppercase inline variables in an abstract type.
    * ripped from FlxMacroUtil but modified to fit my needs
    */
    public static macro function buildAbstract(typePath:Expr,?exclude:Array<String>) {
        var type = Context.getType(typePath.toString());
        var expressions:Array<ObjectField> = [];

        if (exclude == null)
            exclude = ["NONE"];

        switch (type.follow())
        {

            //no enum support yet
            case TEnum(_.get()=> en,_):
                
        
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
                                        expressions.push({field: f.name,expr: expr});
                                    }

                                default:
                            }

                        default:
                    }
                }
            default:
        }


        var finalResult = {expr:EObjectDecl(expressions), pos: Context.currentPos()};
        return macro $b{[macro $finalResult]};
    }


    //KILL EVERYONE
    public static macro function buildEnumStruct(enu:haxe.macro.Expr) {
        return macro $v{0};
    }

}
