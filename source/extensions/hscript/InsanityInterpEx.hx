package extensions.hscript;

import funkin.backend.Logger;

import insanity.tools.Printer;
import insanity.backend.Expr;
import insanity.backend.Exception;
import insanity.backend.CallStack;
import insanity.backend.types.Scripted;
import insanity.backend.Interp;

import haxe.PosInfos;
import haxe.Constraints.IMap;

import Type as HaxeType;
import Reflect as HaxeReflect;

import insanity.custom.InsanityType.ICustomEnumValueType;
import insanity.custom.InsanityReflect as Reflect;
import insanity.custom.InsanityType as Type;
import insanity.custom.InsanityStd as Std;

using StringTools;

using insanity.tools.Tools;
using insanity.backend.TypeCollection;
using insanity.backend.types.Abstract;

class InsanityInterpEx extends Interp
{
	@:isVar
	public var scriptParent(get, set):Dynamic;
	
	private var __fieldParent:Dynamic;
	
	public var parentFields:Array<String> = [];
	public var sharedFields:Sharables = new Sharables(); // to make my job MUCH easier.
	
	// the only purpose of this is to act as a setter for parent.
	public function setParent(field:Dynamic)
	{
		if ((this.__fieldParent != null && field != null && this.__fieldParent == field) || field == null) return; // no need for useless parent assignments! waste of cpu
		
		this.__fieldParent = field;
		
		this.parentFields = try
		{
			this.__fieldParent != null ? HaxeType.getInstanceFields(HaxeType.getClass(this.__fieldParent ?? {unknown: null})) : [];
		}
		catch (e:haxe.Exception)
		{
			Logger.log('Invalid parent assignment in script.\n${e.details()}', ERROR);
			[];
		}
	}
	
	public function getGlobal(id:String, ?isExternalCall:Bool = false)
	{
		if (!isResolvable(id)) return null;
		
		if (!isExternalCall)
		{
			if (variables.exists(id) && !parentFields.contains(id)) return variables.get(id);
			if (parentFields.contains(id)) return Reflect.getProperty(__fieldParent, id);
			if (sharedFields.exists(id) && !parentFields.contains(id)) return sharedFields.get(id);
		}
		else
		{
			if (variables.exists(id)) return variables.get(id);
			if (sharedFields.exists(id)) return sharedFields.get(id);
		}
		
		return null;
	}
	
	override function call(o:Dynamic, f:Dynamic, args:Array<Dynamic>):Dynamic
	{
		return super.call(o, f, args);
	}
	
	override function assign(e1:Expr, e2:Expr):Dynamic
	{
		var v = expr(e2);
		switch (Tools.expr(e1))
		{
			case EIdent(id):
				if (locals.exists(id))
				{
					setLocal(id, v);
				}
				else if (parentFields.contains(id) && !variables.exists(id))
				{
					// assign wip!
					Reflect.setProperty(__fieldParent, id, v);
				}
				else if (sharedFields.exists(id) && !variables.exists(id))
				{
					sharedFields.set(id, v);
				}
				else
				{
					setVar(id, v);
				}
			case EField(e, f, _):
				v = set(expr(e), f, v);
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
	
	override function expr(e:Expr, ?t:CType, void:Bool = false, mapCompr:Bool = false):Dynamic
	{
		return switch (e.e)
		{
			case EMeta(meta, _, e):
				if (meta == ':sharable' && sharedFields != null)
				{
					switch (Tools.expr(e))
					{
						case EFunction(_, _, field):
							final r = expr(e);
							sharedFields.set(field, r);
							r;
							
						case EVar(field, _, e):
							final r = (e != null ? expr(e) : null);
							sharedFields.set(field, r);
							r;
							
						default:
							expr(e);
					}
				}
				else
				{
					expr(e);
				}
				
			default:
				super.expr(e);
		}
	}
	
	override function evalAssignOp(op:String, fop:(Dynamic, Dynamic) -> Dynamic, e1:Expr, e2:Expr):Dynamic
	{
		var v;
		switch (Tools.expr(e1))
		{
			case EIdent(id):
				v = fop(expr(e1), expr(e2));
				
				if (locals.exists(id))
				{
					setLocal(id, v);
				}
				else if (parentFields.contains(id))
				{
					Reflect.setProperty(__fieldParent, id, v);
				}
				else if (sharedFields.exists(id))
				{
					sharedFields.set(id, v);
				}
				else
				{
					setVar(id, v);
				}
			case EField(e, f, _):
				var obj = expr(e);
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
	
	override function resolve(id:String):Dynamic
	{
		if (!isResolvable(id))
		{
			error(EUnknownVariable('Unknown Variable $id!'));
			return null;
		}
		
		if (imports.exists(id))
		{
			var v:Dynamic = imports.get(id);
			
			if (v == null) error(ECustom('Module $id does not define type $id'));
			
			return resolveMirror(v);
		}
		else if (parentFields.contains(id))
		{
			// resolve wip!
			
			var v:Dynamic = Reflect.getProperty(__fieldParent, id);
			
			if (v == null) error(ECustom('Field $id not found in parent variable'));
			
			return resolveMirror(v);
		}
		else if (sharedFields.exists(id))
		{
			// resolve wip!
			
			var v:Dynamic = sharedFields.get(id);
			
			if (v == null) error(ECustom('$id is not a valid sharable field'));
			
			return resolveMirror(v);
		}
		
		return resolveMirror(variables.get(id));
	}
	
	override function isResolvable(id:String):Bool
	{
		// trace('resolving $id');
		return (imports.exists(id) || variables.exists(id) || parentFields.contains(id) || sharedFields.exists(id));
	}
	
	override function increment(e:Expr, prefix:Bool, delta:Int):Dynamic
	{
		position = e.pos;
		var e = e.e;
		
		switch (e)
		{
			case EIdent(id):
				var l = locals.get(id);
				var v:Dynamic = (locals.exists(id) ? getLocal(id) : resolve(id));
				
				if (prefix)
				{
					v += delta;
					if (locals.exists(id)) setLocal(id, v);
					else if (parentFields.contains(id)) Reflect.setProperty(__fieldParent, id, v);
					else if (sharedFields.exists(id)) sharedFields.set(id, v);
					else setVar(id, v);
				}
				else
				{
					if (locals.exists(id)) setLocal(id, v + delta);
					else if (parentFields.contains(id)) Reflect.setProperty(__fieldParent, id, v + delta);
					else if (sharedFields.exists(id)) sharedFields.set(id, v + delta);
					else setVar(id, v + delta);
				}
				
				return v;
			case EField(e, f, _):
				var obj = expr(e);
				var v:Dynamic = get(obj, f);
				if (prefix)
				{
					v += delta;
					set(obj, f, v);
				}
				else set(obj, f, v + delta);
				return v;
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr))
				{
					var v = getMapValue(arr, index);
					if (prefix)
					{
						v += delta;
						setMapValue(arr, index, v);
					}
					else
					{
						setMapValue(arr, index, v + delta);
					}
					return v;
				}
				else
				{
					var v = arr[index];
					if (prefix)
					{
						v += delta;
						arr[index] = v;
					}
					else arr[index] = v + delta;
					return v;
				}
			default:
				return error(EInvalidOp((delta > 0) ? "++" : "--"));
		}
	}
	
	function set_scriptParent(value:Dynamic):Dynamic
	{
		setParent(value);
		return scriptParent = value;
	}
	
	function get_scriptParent():Dynamic
	{
		return __fieldParent;
	}
}
