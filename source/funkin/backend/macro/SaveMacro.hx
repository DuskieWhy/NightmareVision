package funkin.backend.macro;

// da ta 5 5 5 5 5 5 5
// sorry if its a bit messy and incomplete macros are confusing !
// #if macro
import haxe.macro.ExprTools;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.ClassField;
import haxe.macro.Expr.FieldType;
import haxe.macro.Expr.ComplexType;

using haxe.macro.Tools;

using Lambda;

// #end
class SaveMacro
{
	public macro static function buildSaveVars(?bindPath:String):Array<haxe.macro.Expr.Field>
	{
		var position = Context.currentPos();
		var fields:Array<haxe.macro.Expr.Field> = Context.getBuildFields();
		
		final saveDoc = "Loads save data from disk";
		final loadDoc = "Saves the current preferences to disk";
		
		var loadBody:Array<Expr> = [];
		var saveBody:Array<Expr> = [];
		
		var hasLoadBody = false;
		var hasSaveBody = false;
		
		for (i in fields) // look for flush and load
		{
			if (!i.access.contains(AStatic)) continue;
			
			if (i.name == 'flush')
			{
				switch (i.kind)
				{
					case FFun(f):
						saveBody = getFuncBody(f);
						
						i.doc = i.doc != null ? saveDoc + '\n' + i.doc : saveDoc;
						
						hasSaveBody = true;
						
					default:
				}
			}
			
			if (i.name == 'load') // find the load function and grab its body
			{
				switch (i.kind)
				{
					case FFun(f):
						loadBody = getFuncBody(f);
						
						i.doc = i.doc != null ? loadDoc + '\n' + i.doc : loadDoc;
						
						hasLoadBody = true;
					default:
				}
			}
		}
		
		// doesnt have a save func make one
		if (!hasSaveBody)
		{
			fields.push(
				{
					name: 'flush',
					access: [APublic, AStatic],
					kind: FFun(
						{
							args: [],
							expr: macro {},
						}),
					pos: position,
					doc: saveDoc
				});
		}
		
		if (!hasLoadBody)
		{
			fields.push(
				{
					name: 'load',
					access: [APublic, AStatic],
					kind: FFun(
						{
							args: [],
							expr: macro {},
						}),
					pos: position,
					doc: loadDoc
				});
		}
		
		for (field in fields)
		{
			if (field.meta != null)
			{
				for (meta in field.meta)
				{
					if (meta.name == 'saveVar')
					{
						switch (field.kind)
						{
							case FVar(type):
								var autoSave = true;
								var autoLoad = true;
								
								if (meta.params[0] != null && meta.params[0].getValue() == false) autoSave = false;
								if (meta.params[1] != null && meta.params[1].getValue() == false) autoLoad = false;
								
								if (autoSave)
								{
									saveBody.insert(0, macro
										{
											Reflect.setField(flixel.FlxG.save.data, $v{field.name}, $i{field.name});
										});
								}
								
								if (autoLoad)
								{
									loadBody.insert(0, macro
										{
											if (Reflect.hasField(flixel.FlxG.save.data, $v{field.name}))
											{
												if ($i{field.name} is haxe.ds.StringMap)
												{
													var fuck = $i{field.name};
													
													funkin.utils.CoolUtil.copyMapValues(Reflect.field(flixel.FlxG.save.data, $v{field.name}), cast fuck);
												}
												else
												{
													$i{field.name} = Reflect.field(flixel.FlxG.save.data, $v{field.name});
												}
											}
										});
								}
								
							default:
						}
					}
				}
			}
		}
		
		return fields;
	}
	
	static function getFuncBody(func:Function):Array<Expr>
	{
		var body:Array<Expr> = null;
		
		switch (func.expr.expr)
		{
			case EBlock(exprs):
				body = exprs;
				
			default:
				body = [func.expr];
		}
		if (body == null) body = [];
		
		return body;
	}
}
