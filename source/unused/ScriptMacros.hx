package funkin.scripts;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.ClassField;

using haxe.macro.Tools;

using Lambda;
#end

// might be scrapped, might be fixed up who knows
class ScriptMacros
{
	// NOT DONE
	// this will be cool
	// this has helped
	// https://community.openfl.org/t/append-an-expr-in-haxe-macro-context/10311/2
	public macro static function buildScriptedState():Array<haxe.macro.Expr.Field>
	{
		var curClass:haxe.macro.Type.ClassType = haxe.macro.Context.getLocalClass().get();
		
		var position = Context.currentPos();
		
		var fields:Array<haxe.macro.Expr.Field> = Context.getBuildFields();
		
		function specificBodyInjections(funcName:String, expr:Array<Expr>):Array<Expr>
		{
			switch (funcName)
			{
				case 'update':
					expr.insert(0, macro // after testing a while i got mad i cant just reset the state easily
						{
							if (flixel.FlxG.keys.justPressed.F4) // idk a good reset state keybibnd
							{
								flixel.addons.transition.FlxTransitionableState.skipNextTransIn = flixel.addons.transition.FlxTransitionableState.skipNextTransOut = true;
								flixel.FlxG.resetState();
							}
						});
				case 'create':
					expr.insert(0, macro // so the script actually gets initialized
						{
							tryInitiatingStateScript();
						});
						
				case 'destroy':
					expr.push(macro // so we dont just have an instance lying around aha..
						{
							if (this.__script != null)
							{
								this.__script.stop();
							}
						});
			}
			return expr;
		}
		
		fields.push(
			{
				name: "shouldBuildHardcoded",
				access: [haxe.macro.Expr.Access.APrivate],
				kind: FFun(
					{
						args: [],
						expr: macro
						{
							var isHardcoded:Bool = true;
							@:privateAccess
							if (this.__script != null && this.__script._script.interp.locals.exists('isCleanState')) isHardcoded = false;
							
							return isHardcoded;
						}
					}),
				pos: position,
			});
			
		// injecting script var
		fields.push(
			{
				name: "__script",
				access: [haxe.macro.Expr.Access.APrivate],
				kind: FVar(macro :funkin.scripts.FunkinIris, macro $v{null}),
				pos: position,
			});
			
		// injecting the actual function which loads a script
		fields.push(
			{
				name: "tryInitiatingStateScript",
				access: [haxe.macro.Expr.Access.APrivate],
				kind: FFun(
					{
						args: [],
						expr: macro
						{
							var clName = Type.getClassName(Type.getClass(this));
							if (clName.contains('.')) clName = clName.substr(clName.lastIndexOf('.') + 1, clName.length);
							
							var scriptFile = funkin.scripts.FunkinIris.getPath('scripts/menus/' + clName, false);
							
							var found = sys.FileSystem.exists(scriptFile);
							
							if (found)
							{
								this.__script = funkin.scripts.FunkinIris.fromFile(scriptFile);
								this.__script.set('game', FlxG.state);
							}
							
							return found;
						}
					}),
				pos: position,
			});
			
		var fieldsToRemove:Array<Field> = [];
		
		var copied:Array<
			{
				name:String,
				pos:Position,
				body:Array<Expr>,
				access:Array<Access>,
				funcData:Function
			}> = [];
			
		// okay so the issue with this currently is we dont have the inherited fields workaround is overriding them // to do figure that out
		for (i in fields)
		{
			switch (i.kind)
			{
				case FFun(f):
					var body:Array<Expr> = null;
					
					switch (f.expr.expr)
					{
						case EBlock(exprs):
							body = exprs;
							
						default:
							body = [f.expr];
					}
					if (body == null) body = [];
					
					var funcName:String = i.name.toString();
					funcName = funcName.charAt(0).toUpperCase() + funcName.substr(1);
					
					// place at the beginning of the body
					
					var funcArgs = [for (i in f.args) macro $i{i.name}];
					
					body.insert(0, macro
						{
							var finalFuncName = 'on' + $v{funcName};
							
							// trace('inserted ' + finalFuncName);
							
							if (this.__script != null) this.__script.call(finalFuncName, $a{funcArgs});
						});
						
					// and then at the end
					body.push(macro
						{
							var finalFuncName = 'on' + $v{funcName} + 'Post';
							// trace('on' + finalFuncName + 'Post');
							if (this.__script != null) this.__script.call(finalFuncName, $a{funcArgs});
						});
						
					var functionName:String = i.name.toString();
					
					body = specificBodyInjections(functionName, body);
					
					copied.push(
						{
							name: i.name,
							pos: i.pos,
							body: body,
							access: i.access,
							funcData: f
						});
						
					fieldsToRemove.push(i);
					
				default:
			}
		}
		
		for (i in fieldsToRemove)
		{
			fields.remove(i);
		}
		
		for (i in copied)
		{
			// trace(i.name);
			fields.push(
				{
					name: i.name,
					pos: i.pos,
					access: i.access,
					kind: FFun(
						{
							params: i.funcData.params,
							args: i.funcData.args,
							ret: i.funcData.ret,
							expr: macro $b{i.body}
						})
				});
		}
		
		return fields;
	}
}
