package extensions.hscript;

import haxe.Constraints.IMap;
import haxe.PosInfos;

import Type.ValueType;

import crowplexus.iris.Iris;
import crowplexus.hscript.*;
import crowplexus.hscript.Expr;
import crowplexus.hscript.Tools;
import crowplexus.iris.Iris;
import crowplexus.iris.IrisUsingClass;
import crowplexus.iris.utils.UsingEntry;
import crowplexus.hscript.Interp.LocalVar;

// whgy is this private
private enum Stop
{
	SBreak;
	SContinue;
	SReturn;
}

/**
 * Modified Iris Interp for variety of improvements.
 * 
 * crash fix on for loops in debug
 * 
 * improved error reporting on null functions
 * 
 * parent field to directly access an object
 * 
 * public fields support with `Sharables`
 */
class InterpEx extends crowplexus.hscript.Interp
{
	public var sharedFields:Null<Sharables> = null;
	
	public function new(?parent:Dynamic, ?shareables:Sharables)
	{
		super();
		if (parent != null) this.parent = parent;
		this.sharedFields = shareables;
		showPosOnLog = false;
	}
	
	override function makeIterator(v:Dynamic):Iterator<Dynamic>
	{
		#if ((flash && !flash9) || (php && !php7 && haxe_ver < '4.0.0'))
		if (v.iterator != null) v = v.iterator();
		#else
		// DATA CHANGE //does a null check because this crashes on debug build
		if (v.iterator != null) try
			v = v.iterator()
		catch (e:Dynamic) {};
		#end
		if (v.hasNext == null || v.next == null) error(EInvalidIterator(v));
		return v;
	}
	
	public var parentFields:Array<String> = [];
	public var parent(default, set):Dynamic;
	
	function set_parent(value:Dynamic)
	{
		parent = value;
		parentFields = value != null ? Type.getInstanceFields(Type.getClass(value)) : [];
		return parent;
	}
	
	override function resolve(id:String):Dynamic
	{
		if (locals.exists(id))
		{
			var l = locals.get(id);
			return l.r;
		}
		
		if (variables.exists(id))
		{
			var v = variables.get(id);
			return v;
		}
		
		if (imports.exists(id))
		{
			var v = imports.get(id);
			return v;
		}
		
		if (parent != null && parentFields.contains(id))
		{
			var v = Reflect.getProperty(parent, id);
			if (v != null) return v;
		}
		
		if (sharedFields != null && sharedFields.exists(id))
		{
			var v = sharedFields.get(id);
			if (v != null) return v;
		}
		
		error(EUnknownVariable(id));
		
		return null;
	}
	
	override function evalAssignOp(op, fop, e1, e2):Dynamic
	{
		var v;
		switch (Tools.expr(e1))
		{
			case EIdent(id):
				var l = locals.get(id);
				v = fop(expr(e1), expr(e2));
				if (l == null)
				{
					if (parentFields.contains(id))
					{
						Reflect.setProperty(parent, id, v);
					}
					else if (sharedFields != null && sharedFields.get(id))
					{
						sharedFields.set(id, v);
					}
					else
					{
						setVar(id, v);
					}
				}
				else
				{
					if (l.const != true) l.r = v;
					else warn(ECustom("Cannot reassign final, for constant expression -> " + id));
				}
			case EField(e, f, s):
				var obj = expr(e);
				if (obj == null) if (!s) error(EInvalidAccess(f));
				else return null;
				v = fop(get(obj, f), expr(e2));
				v = set(obj, f, v);
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr))
				{
					v = fop(getMapValue(arr, index), expr(e2));
					setMapValue(arr, index, v);
				}
				else
				{
					v = fop(arr[index], expr(e2));
					arr[index] = v;
				}
			default:
				return error(EInvalidOp(op));
		}
		return v;
	}
	
	override function assign(e1:Expr, e2:Expr):Dynamic
	{
		var v = expr(e2);
		switch (Tools.expr(e1))
		{
			case EIdent(id):
				var l = locals.get(id);
				if (l == null)
				{
					if (!variables.exists(id) && parentFields.contains(id))
					{
						Reflect.setProperty(parent, id, v);
					}
					else if (!variables.exists(id) && sharedFields != null && sharedFields.exists(id))
					{
						sharedFields.set(id, v);
					}
					else
					{
						setVar(id, v);
					}
				}
				else
				{
					if (l.const != true) l.r = v;
					else warn(ECustom("Cannot reassign final, for constant expression -> " + id));
				}
			case EField(e, f, s):
				var e = expr(e);
				if (e == null) if (!s) error(EInvalidAccess(f));
				else return null;
				v = set(e, f, v);
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr))
				{
					setMapValue(arr, index, v);
				}
				else
				{
					arr[index] = v;
				}
				
			default:
				error(EInvalidOp("="));
		}
		return v;
	}
	
	override function fcall(o:Dynamic, f:String, args:Array<Dynamic>):Dynamic
	{
		for (_using in usings)
		{
			var v = _using.call(o, f, args);
			if (v != null) return v;
		}
		
		final method = get(o, f);
		
		if (method == null)
		{
			Iris.error('Unknown function: $f', posInfos());
			return null; // return before call so we dont double error messages
		}
		
		return call(o, method, args);
	}
	
	override public function expr(e:Expr):Dynamic
	{
		#if hscriptPos
		curExpr = e;
		var e = e.e;
		#end
		switch (e)
		{
			case EIgnore(_):
			case EConst(c):
				return switch (c)
				{
					case CInt(v): v;
					case CFloat(f): f;
					case CString(s): s;
					#if !haxe3
					case CInt32(v): v;
					#end
				}
			case EIdent(id):
				return resolve(id);
			case EVar(n, _, v, isConst):
				declared.push({n: n, old: locals.get(n)});
				locals.set(n, {r: (v == null) ? null : expr(v), const: isConst});
				return null;
			case EParent(e):
				return expr(e);
			case EBlock(exprs):
				var old = declared.length;
				var v = null;
				for (e in exprs)
					v = expr(e);
				restore(old);
				return v;
			case EField(e, f, true):
				var e = expr(e);
				if (e == null) return null;
				return get(e, f);
			case EField(e, f, false):
				return get(expr(e), f);
			case EBinop(op, e1, e2):
				var fop = binops.get(op);
				if (fop == null) error(EInvalidOp(op));
				return fop(e1, e2);
			case EUnop(op, prefix, e):
				return switch (op)
				{
					case "!":
						expr(e) != true;
					case "-":
						-expr(e);
					case "++":
						increment(e, prefix, 1);
					case "--":
						increment(e, prefix, -1);
					case "~":
						#if (neko && !haxe3)
						haxe.Int32.complement(expr(e));
						#else
						~expr(e);
						#end
					default:
						error(EInvalidOp(op));
						null;
				}
			case ECall(e, params):
				var args = new Array();
				for (p in params)
					args.push(expr(p));
					
				switch (Tools.expr(e))
				{
					case EField(e, f, s):
						var obj = expr(e);
						if (obj == null) if (!s) error(EInvalidAccess(f));
						return fcall(obj, f, args);
					default:
						return call(null, expr(e), args);
				}
			case EIf(econd, e1, e2):
				return if (expr(econd) == true) expr(e1) else if (e2 == null) null else expr(e2);
			case EWhile(econd, e):
				whileLoop(econd, e);
				return null;
			case EDoWhile(econd, e):
				doWhileLoop(econd, e);
				return null;
			case EFor(v, it, e):
				forLoop(v, it, e);
				return null;
			case EBreak:
				throw SBreak;
			case EContinue:
				throw SContinue;
			case EReturn(e):
				returnValue = e == null ? null : expr(e);
				throw SReturn;
			case EImport(v, as):
				final aliasStr = (as != null ? " named " + as : ""); // for errors
				if (Iris.blocklistImports.contains(v))
				{
					error(ECustom("You cannot add a blacklisted import, for class " + v + aliasStr));
					return null;
				}
				
				var n = Tools.last(v.split("."));
				if (imports.exists(n)) return imports.get(n);
				
				var c:Dynamic = getOrImportClass(v);
				if (c == null) // if it's still null then throw an error message.
					return warn(ECustom("Import" + aliasStr + " of class " + v + " could not be added"));
				else
				{
					imports.set(n, c);
					if (as != null) imports.set(as, c);
					// resembles older haxe versions where you could use both the alias and the import
					// for all the "Colour" enjoyers :D
				}
				return null; // yeah. -Crow
				
			case EFunction(params, fexpr, name, _):
				var capturedLocals = duplicate(locals);
				var me = this;
				var hasOpt = false, minParams = 0;
				for (p in params)
					if (p.opt) hasOpt = true;
					else minParams++;
				var f = function(args:Array<Dynamic>) {
					if (((args == null) ? 0 : args.length) != params.length)
					{
						if (args.length < minParams)
						{
							var str = "Invalid number of parameters. Got " + args.length + ", required " + minParams;
							if (name != null) str += " for function '" + name + "'";
							error(ECustom(str));
						}
						// make sure mandatory args are forced
						var args2 = [];
						var extraParams = args.length - minParams;
						var pos = 0;
						for (p in params)
							if (p.opt)
							{
								if (extraParams > 0)
								{
									args2.push(args[pos++]);
									extraParams--;
								}
								else args2.push(null);
							}
							else args2.push(args[pos++]);
						args = args2;
					}
					var old = me.locals, depth = me.depth;
					me.depth++;
					me.locals = me.duplicate(capturedLocals);
					for (i in 0...params.length)
						me.locals.set(params[i].name, {r: args[i], const: false});
					var r = null;
					var oldDecl = declared.length;
					if (inTry) try
					{
						r = me.exprReturn(fexpr);
					}
					catch (e:Dynamic)
					{
						me.locals = old;
						me.depth = depth;
						#if neko
						neko.Lib.rethrow(e);
						#else
						throw e;
						#end
					}
					else r = me.exprReturn(fexpr);
					restore(oldDecl);
					me.locals = old;
					me.depth = depth;
					return r;
				};
				var f = Reflect.makeVarArgs(f);
				if (name != null)
				{
					if (depth == 0)
					{
						// global function
						variables.set(name, f);
					}
					else
					{
						// function-in-function is a local function
						declared.push({n: name, old: locals.get(name)});
						var ref:LocalVar = {r: f, const: false};
						locals.set(name, ref);
						capturedLocals.set(name, ref); // allow self-recursion
					}
				}
				return f;
			case EArrayDecl(arr):
				if (arr.length > 0 && Tools.expr(arr[0]).match(EBinop("=>", _)))
				{
					var isAllString:Bool = true;
					var isAllInt:Bool = true;
					var isAllObject:Bool = true;
					var isAllEnum:Bool = true;
					var keys:Array<Dynamic> = [];
					var values:Array<Dynamic> = [];
					for (e in arr)
					{
						switch (Tools.expr(e))
						{
							case EBinop("=>", eKey, eValue): {
									var key:Dynamic = expr(eKey);
									var value:Dynamic = expr(eValue);
									isAllString = isAllString && (key is String);
									isAllInt = isAllInt && (key is Int);
									isAllObject = isAllObject && Reflect.isObject(key);
									isAllEnum = isAllEnum && Reflect.isEnumValue(key);
									keys.push(key);
									values.push(value);
								}
							default: throw("=> expected");
						}
					}
					var map:Dynamic =
						{
							if (isAllInt) new haxe.ds.IntMap<Dynamic>();
							else if (isAllString) new haxe.ds.StringMap<Dynamic>();
							else if (isAllEnum) new haxe.ds.EnumValueMap<Dynamic, Dynamic>();
							else if (isAllObject) new haxe.ds.ObjectMap<Dynamic, Dynamic>();
							else throw 'Inconsistent key types';
						}
					for (n in 0...keys.length)
					{
						setMapValue(map, keys[n], values[n]);
					}
					return map;
				}
				else
				{
					var a = new Array();
					for (e in arr)
					{
						a.push(expr(e));
					}
					return a;
				}
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr))
				{
					return getMapValue(arr, index);
				}
				else
				{
					return arr[index];
				}
			case ENew(cl, params):
				var a = new Array();
				for (e in params)
					a.push(expr(e));
				return cnew(cl, a);
			case EThrow(e):
				throw expr(e);
			case ETry(e, n, _, ecatch):
				var old = declared.length;
				var oldTry = inTry;
				try
				{
					inTry = true;
					var v:Dynamic = expr(e);
					restore(old);
					inTry = oldTry;
					return v;
				}
				catch (err:Stop)
				{
					inTry = oldTry;
					throw err;
				}
				catch (err:Dynamic)
				{
					// restore vars
					restore(old);
					inTry = oldTry;
					// declare 'v'
					declared.push({n: n, old: locals.get(n)});
					locals.set(n, {r: err, const: false});
					var v:Dynamic = expr(ecatch);
					restore(old);
					return v;
				}
			case EObject(fl):
				var o = {};
				for (f in fl)
					set(o, f.name, expr(f.e));
				return o;
			case ETernary(econd, e1, e2):
				return if (expr(econd) == true) expr(e1) else expr(e2);
			case ESwitch(e, cases, def):
				var val:Dynamic = expr(e);
				var match = false;
				for (c in cases)
				{
					for (v in c.values)
						if ((!Type.enumEq(Tools.expr(v), EIdent("_")) && expr(v) == val) && (c.ifExpr == null || expr(c.ifExpr) == true))
						{
							match = true;
							break;
						}
					if (match)
					{
						val = expr(c.expr);
						break;
					}
				}
				if (!match) val = def == null ? null : expr(def);
				return val;
			case EMeta(meta, _, e):
				if (meta == ':sharable' && sharedFields != null)
				{
					switch (Tools.expr(e))
					{
						case EFunction(_, _, field) if (depth == 0):
							sharedFields.set(field, expr(e));
							
						case EVar(field, _) if (depth == 0):
							expr(e);
							
							sharedFields.set(field, resolve(field));
							locals.remove(field); // im not sure if this is ideal but it shouldnt be local i think if its technically a shared
							
						default:
							expr(e);
					}
					
					return null;
				}
				return expr(e);
			case ECheckType(e, _):
				return expr(e);
			case EEnum(enumName, fields):
				var obj = {};
				for (index => field in fields)
				{
					switch (field)
					{
						case ESimple(name):
							Reflect.setField(obj, name, new EnumValue(enumName, name, index, null));
						case EConstructor(name, params):
							var hasOpt = false, minParams = 0;
							for (p in params)
								if (p.opt) hasOpt = true;
								else minParams++;
							var f = function(args:Array<Dynamic>) {
								if (((args == null) ? 0 : args.length) != params.length)
								{
									if (args.length < minParams)
									{
										var str = "Invalid number of parameters. Got " + args.length + ", required " + minParams;
										if (enumName != null) str += " for enum '" + enumName + "'";
										error(ECustom(str));
									}
									// make sure mandatory args are forced
									var args2 = [];
									var extraParams = args.length - minParams;
									var pos = 0;
									for (p in params)
										if (p.opt)
										{
											if (extraParams > 0)
											{
												args2.push(args[pos++]);
												extraParams--;
											}
											else args2.push(null);
										}
										else args2.push(args[pos++]);
									args = args2;
								}
								return new EnumValue(enumName, name, index, args);
							};
							var f = Reflect.makeVarArgs(f);
							
							Reflect.setField(obj, name, f);
					}
				}
				
				variables.set(enumName, obj);
			case EDirectValue(value):
				return value;
			case EUsing(name):
				useUsing(name);
		}
		return null;
	}
	
	// overriden because Stop is private. DIE HSCRIPT DIE
	
	override function exprReturn(e):Dynamic
	{
		try
		{
			return expr(e);
		}
		catch (e:Stop)
		{
			switch (e)
			{
				case SBreak:
					throw "Invalid break";
				case SContinue:
					throw "Invalid continue";
				case SReturn:
					var v = returnValue;
					returnValue = null;
					return v;
			}
		}
		return null;
	}
	
	override function doWhileLoop(econd, e)
	{
		var old = declared.length;
		do
		{
			try
			{
				expr(e);
			}
			catch (err:Stop)
			{
				switch (err)
				{
					case SContinue:
					case SBreak:
						break;
					case SReturn:
						throw err;
				}
			}
		}
		while (expr(econd) == true);
		restore(old);
	}
	
	override function whileLoop(econd, e)
	{
		var old = declared.length;
		while (expr(econd) == true)
		{
			try
			{
				expr(e);
			}
			catch (err:Stop)
			{
				switch (err)
				{
					case SContinue:
					case SBreak:
						break;
					case SReturn:
						throw err;
				}
			}
		}
		restore(old);
	}
}
