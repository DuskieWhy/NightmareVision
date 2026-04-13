package insanity.backend.types;

import insanity.custom.InsanityReflect;
import insanity.custom.InsanityType;
import insanity.backend.Interp;
import insanity.backend.Expr;
import insanity.Environment;
import insanity.Module;
import insanity.tools.Printer;
import insanity.tools.Tools;

using StringTools;

using insanity.backend.TypeCollection;

class ScriptedTools
{
	public static var scriptedClasses(default, never):Map<String, Class<IInsanityScripted>> = insanity.backend.macro.ScriptedMacro.listScriptedClasses();
	
	public static function resolve(t:Dynamic):Dynamic
	{
		if (t is InsanityScriptedClass) return cast t;
		
		var cls:String = Type.getClassName(t);
		if (scriptedClasses.exists(cls)) return scriptedClasses.get(cls);
		
		throw 'Class $cls can\'t be extended for scripting';
		return null;
	}
}

@:access(insanity.backend.Interp)
@:access(insanity.backend.types.IInsanityScripted)
class InsanityScriptedClass implements IInsanityType implements ICustomReflection implements ICustomClassType
{
	public var path:String;
	public var name:String;
	public var module:Module;
	public var pack:Array<String>;
	
	public var safe:Bool = false;
	public var snapshotAll:Bool = false;
	
	public var interp:Interp;
	public var extending(get, never):Dynamic;
	public var instanceClass(get, never):Dynamic;
	
	var decl:ClassDecl;
	var __vars:Map<String, Variable> = [];
	
	public var failed:Bool = false;
	public var initialized:Bool = false;
	public var initializing:Bool = false;
	
	public function new(decl:ClassDecl, ?module:Module)
	{
		this.name = decl.name;
		this.pack = (module?.pack ?? []);
		this.module = module;
		this.decl = decl;
		
		path = Tools.pathToString(name, pack);
		
		interp = Type.createInstance(Config.interpClass, []);
		interp.canDefer = true;
	}
	
	public function init(?env:Environment, ?baseInterp:Interp, restore:Bool = true):Void
	{
		interp.environment = env;
		interp.setDefaults(true, baseInterp == null);
		
		if (baseInterp != null)
		{
			for (u in baseInterp.usings)
				interp.usings.push(u);
			for (k => i in baseInterp.imports)
				interp.imports.set(k, i);
			for (k => v in baseInterp.variables)
				if (!interp.variables.exists(k)) interp.variables.set(k, v);
		}
		
		interp.pushStack(insanity.backend.CallStack.StackItem.SModule(module?.path ?? name));
		
		safe = false;
		snapshotAll = false;
		for (meta in decl.meta)
		{
			safe = (safe || meta.name == ':safe');
			snapshotAll = (snapshotAll || meta.name == ':snapshot');
		}
		
		var overridingFields:Array<String> = [];
		var knownFields:Array<String> = [];
		
		for (field in decl.fields)
		{
			var f:String = field.name;
			
			if (f == 'new') continue;
			
			if (insanity.backend.macro.ScriptedMacro.ignoreFields.contains(f))
			{
				throw 'Field $f reserved for internal use!!! - HScriptInsanity';
			}
			else if (knownFields.contains(f))
			{
				throw 'Duplicate class field declaration: $name.$f';
			}
			else
			{
				knownFields.push(f);
				if (field.access.contains(AOverride)) overridingFields.push(f);
			}
			
			if (!field.access.contains(AStatic)) continue;
			
			var l:Variable = {r: null, access: field.access};
			
			switch (field.kind)
			{
				default:
				case KVar(v):
					if (v.get != null) l.get = v.get;
					if (v.set != null) l.set = v.set;
					if (v.isFinal != null) l.isFinal = v.isFinal;
			}
			
			interp.locals.set(f, l);
		}
		
		for (field in decl.fields)
		{
			var f:String = field.name;
			
			if (f == 'new' || !field.access.contains(AStatic)) continue;
			
			switch (field.kind)
			{
				case KFunction(fun):
					interp.locals.get(f).r = interp.buildFunction(f, fun.args, fun.expr, fun.ret, interp.locals);
					
				case KVar(v):
					if (restore)
					{
						var snapshot:Bool = snapshotAll;
						if (!snapshot) for (meta in field.meta)
							snapshot = (snapshot || meta.name == ':snapshot');
							
						if (snapshot && Module.snapshots.exists(path))
						{
							var fields:Map<String, Dynamic> = Module.snapshots.get(path);
							if (fields.exists(f))
							{
								interp.locals.get(f).r = fields.get(f);
								continue;
							}
						}
					}
					
					try
					{
						interp.locals.get(f).r = (v.expr == null ? null : interp.exprReturn(v.expr, v.type));
					}
					catch (d:Defer)
					{
						var signal = (env?.onInitialized ?? module.onInitialized);
						
						signal.push(function(_) {
							try
							{
								interp.locals.get(f).r = interp.exprReturn(v.expr, v.type);
							}
							catch (e:haxe.Exception)
							{
								onExpressionError(e, f, v.expr);
							}
							
							return false;
						});
					}
					catch (e:haxe.Exception)
					{
						onExpressionError(e, f, v.expr);
					}
			}
			
			__vars.set(f, interp.locals.get(f));
		}
		
		var foundOverridingFields:Array<String> = [];
		function overrideFieldCheck(extending:Dynamic)
		{
			if (extending is InsanityScriptedClass)
			{
				var extend:InsanityScriptedClass = cast extending;
				
				if (extend.module != null && !extend.initializing && !extend.initialized && !extend.failed)
				{
					if (!extend.module.starting && !extend.module.started) extend.module.start(env);
					
					extend.module.startType(env, extend);
				}
				
				for (field in extend.decl.fields)
				{
					var f:String = field.name;
					
					if (f == 'new' || field.access.contains(AStatic)) continue;
					
					if (overridingFields.contains(f))
					{
						if (!foundOverridingFields.contains(f)) foundOverridingFields.push(f);
					}
					else if (knownFields.contains(f))
					{
						throw 'Field $f should be declared with \'override\' since it is inherited from superclass ${extend.name}';
					}
				}
				
				if (extend.extending != null) overrideFieldCheck(extend.extending);
			}
			else
			{
				var cls = instanceClass;
				if (cls == null) return;
				
				var instanceFields:Array<String> = (cls.instanceFields ?? Type.getInstanceFields(cast cls));
				var inlinedFields:Array<String> = cls.inlinedFields;
				var unexposedFields:Array<String> = cls.unexposedFields;
				
				for (field in instanceFields)
				{
					if (insanity.backend.macro.ScriptedMacro.ignoreFields.contains(field)) continue;
					
					if (overridingFields.contains(field))
					{
						if (inlinedFields?.contains(field))
						{
							throw 'Field $field is inlined and cannot be overridden';
						}
						else if (unexposedFields?.contains(field))
						{
							throw 'Field $field is unexposed and cannot be overridden';
						}
						
						if (!foundOverridingFields.contains(field)) foundOverridingFields.push(field);
					}
					else if (knownFields.contains(field))
					{
						throw 'Field $field should be declared with \'override\' since it is inherited from superclass ${cls.getBaseClass()}';
					}
				}
			}
		}
		overrideFieldCheck(extending);
		if (foundOverridingFields.length < overridingFields.length)
		{
			for (f in overridingFields)
			{
				if (!foundOverridingFields.contains(f)) throw 'Field $f is declared \'override\' but doesn\'t override any field'; // TODO (Suggestion: ) ?
			}
		}
	}
	
	public function snapshot():Void
	{
		for (field in decl.fields)
		{
			if (field.name == 'new' || !field.access.contains(AStatic)) continue;
			
			var snapshot:Bool = snapshotAll;
			if (!snapshot) for (meta in field.meta)
				snapshot = (snapshot || meta.name == ':snapshot');
			if (!snapshot) continue;
			
			switch (field.kind)
			{
				case KFunction(_):
				case KVar(_):
					var fields:Map<String, Dynamic> = (Module.snapshots.get(path) ?? []);
					fields.set(field.name, interp.getLocal(field.name));
					Module.snapshots.set(path, fields);
			}
		}
	}
	
	function get_extending():Dynamic
	{
		return switch (decl.extend)
		{
			case CTPath(path, _):
				var p:String = path.join('.');
				
				var type = (module?.interp.imports.get(p) ?? interp.imports.get(p) ?? Tools.resolve(p, interp.environment));
				if (type == null) throw 'Type not found: $p';
				
				ScriptedTools.resolve(type);
			case null:
				null;
			default:
				throw 'Invalid extend ${decl.extend}';
				null;
		}
	}
	
	function get_instanceClass():Dynamic
	{
		if (extending is InsanityScriptedClass)
		{
			return cast(extending, InsanityScriptedClass).instanceClass;
		}
		else if (extending == null)
		{
			return InsanityDummyClass;
		}
		else
		{
			return extending;
		}
	}
	
	public function toString():String
	{
		if (interp.locals?.exists('toString')) return interp.locals.get('toString').r();
		
		return 'InsanityScriptedClass<$path>';
	}
	
	public function typeCreateInstance(arguments:Array<Dynamic>):Dynamic
	{
		if (!initialized) throw 'Type $path is not initialized';
		
		var inst:IInsanityScripted = Type.createEmptyInstance(instanceClass);
		inst.__construct(this, arguments);
		return inst;
	}
	
	public function typeCreateEmptyInstance():Dynamic
	{
		if (!initialized) throw 'Type $path is not initialized';
		
		return Type.createEmptyInstance(instanceClass);
	}
	
	public function typeGetClass():Dynamic
	{
		return null;
	}
	
	public function typeGetClassFields():Array<String>
	{
		var fields:Array<String> = [for (loc => _ in interp.locals) loc];
		return fields;
	}
	
	public function typeGetInstanceFields():Array<String>
	{
		var fields:Array<String> = [];
		
		function getFields(c:Dynamic)
		{
			if (c is InsanityScriptedClass)
			{
				for (field in cast(c, InsanityScriptedClass).decl.fields)
				{
					var f:String = field.name;
					if (f == 'new' || field.access.contains(AStatic)) continue;
					if (!fields.contains(f)) fields.push(f);
				}
				
				var instance = c.instanceClass;
				if (instance != InsanityScriptedClass) getFields(instance);
				
				if (c.extending != null)
				{
					getFields(c.extending);
				}
			}
			else if (c is Class)
			{
				for (f in Type.getInstanceFields(c))
				{
					if (!fields.contains(f) && !insanity.backend.macro.ScriptedMacro.ignoreFields.contains(f)) fields.push(f);
				}
			}
		}
		
		getFields(this);
		
		return fields;
	}
	
	public function reflectHasField(field:String):Bool
	{
		return (__vars.exists(field));
	}
	
	public function reflectGetField(field:String):Dynamic
	{
		return (__vars.exists(field) ? __vars.get(field).r : null);
	}
	
	public function reflectSetField(field:String, value:Dynamic):Dynamic
	{
		return (__vars.exists(field) ? __vars.get(field).r = value : null);
	}
	
	public function reflectGetProperty(property:String):Dynamic
	{
		return (__vars.exists(property) ? interp.getLocal(property, __vars) : null);
	}
	
	public function reflectSetProperty(property:String, value:Dynamic):Dynamic
	{
		return (__vars.exists(property) ? interp.setLocal(property, value, __vars) : null);
	}
	
	public function reflectListFields():Array<String>
	{
		return [for (field in __vars.keys()) field];
	}
	
	public dynamic function onExpressionError(error:Dynamic, field:String, ?expr:Expr):Void
	{
		trace('Error on field $field of $path: $error');
	}
	
	public dynamic function onInstanceError(error:Dynamic, fun:String, ?instance:IInsanityScripted):Void
	{
		trace('Error on function $fun of $path: $error');
	}
}

@:access(insanity.backend.Interp)
class InsanityScriptedTypedef implements IInsanityType
{
	public var name:String;
	public var module:Module;
	public var pack:Array<String>;
	public var path:String;
	
	public var alias:Dynamic;
	
	var decl:TypeDecl;
	
	public var failed:Bool = false;
	public var initialized:Bool = false;
	public var initializing:Bool = false;
	
	public function new(decl:TypeDecl, ?module:Module)
	{
		this.name = decl.name;
		this.pack = (module?.pack ?? []);
		this.module = module;
		this.decl = decl;
		
		path = Tools.pathToString(name, pack);
	}
	
	public function init(?env:Environment, ?baseInterp:Interp, restore:Bool = true):Void
	{
		alias = null;
		
		trace(decl.t);
		
		switch (decl.t)
		{
			case CTAnon(fields):
				alias = Dynamic; // this would technically work for anonymous structures for now!
				trace('anon typedefs aren\'t widely supported, though they should function at a basic level.');
			case insanity.backend.Expr.CType.CTPath(path, params):
				var fullPath:String = path.join('.');
				
				if (fullPath == 'Map')
				{ // infer from parameters
					if (params == null || params.length < 2) throw 'Not enough type parameters for Map'; // we dont really care about the value type , but whatever
					else if (params.length > 2) throw 'Too many type parameters for Map';
					
					switch (params[0])
					{
						case CTAnon(_):
							alias = haxe.ds.ObjectMap;
						case CTPath(path, _):
							var fullPath:String = path.join('.');
							
							if (fullPath == 'String')
							{
								alias = haxe.ds.StringMap;
							}
							else if (fullPath == 'Int')
							{
								alias = haxe.ds.IntMap;
							}
							else
							{
								var type:TypeInfo = null;
								var r = (Tools.resolve(fullPath, env) ?? baseInterp.imports.get(fullPath));
								if (r is Class)
								{
									type = TypeCollection.main.fromCompilePath(InsanityType.getClassName(r))[0];
								}
								else if (r == null)
								{
									throw Printer.errorToString(EUnknownType(fullPath));
								}
								
								if (type?.kind == 'class')
								{
									alias = haxe.ds.ObjectMap;
								}
							}
						default:
					}
					
					if (alias == null)
					{
						var p = new Printer();
						throw 'Map of type <${p.typeToString(params[0])}, ${p.typeToString(params[1])}> is not accepted';
					}
				}
				else
				{
					alias = baseInterp.resolve(fullPath);
				}
				
				if (alias == null) throw Printer.errorToString(EUnknownType(fullPath));
				
			default:
				trace('Non type-alias typedefs are not supported');
		}
	}
	
	public function snapshot():Void {}
}

@:access(insanity.Module)
class InsanityScriptedEnum implements IInsanityType implements ICustomReflection implements ICustomEnumType
{
	public var name:String;
	public var module:Module;
	public var pack:Array<String>;
	public var path:String;
	
	public var values:Array<String>;
	public var constructs:Map<String, EnumFieldDecl>;
	
	var constructFunctions:Map<String, Array<Dynamic>->InsanityScriptedEnumValue>;
	
	var decl:EnumDecl;
	
	public var failed:Bool = false;
	public var initialized:Bool = false;
	public var initializing:Bool = false;
	
	public function new(decl:EnumDecl, ?module:Module)
	{
		this.name = decl.name;
		this.pack = (module?.pack ?? []);
		this.module = module;
		this.decl = decl;
		
		path = Tools.pathToString(name, pack);
	}
	
	public function init(?env:Environment, ?baseInterp:Interp, restore:Bool = true):Void
	{
		values = decl.names.copy();
		constructs = decl.constructs.copy();
		constructFunctions = new Map();
		
		for (name => construct in constructs)
		{
			var params = construct.arguments;
			if (params != null)
			{
				var minParams:Int = 0;
				for (i => p in params)
				{
					if (!p.opt) minParams = (i + 1);
				}
				
				constructFunctions.set(name, Reflect.makeVarArgs(function(args:Array<Dynamic>) {
					if (args.length < minParams)
					{
						var arg = params[args.length];
						var argType:String = arg.name;
						if (arg.t != null) argType += (':' + new Printer().typeToString(arg.t));
						
						throw 'Not enough arguments, expected $argType';
					}
					if (args.length > params.length && params.length > 0)
					{
						throw 'Too many arguments';
					}
					
					return new InsanityScriptedEnumValue(this, values.indexOf(name), args);
				}));
			}
		}
	}
	
	public function toString():String
	{
		return 'InsanityScriptedEnum<$path>';
	}
	
	public function typeGetEnumName():String
	{
		return path;
	}
	
	public function typeCreateEnum(constr:String, ?arguments:Array<Dynamic>):Dynamic
	{
		var construct:EnumFieldDecl = constructs.get(constr);
		if (construct != null)
		{
			if (constructFunctions.exists(constr))
			{
				return Reflect.callMethod(this, constructFunctions.get(constr), arguments ?? []);
			}
			else
			{
				return new InsanityScriptedEnumValue(this, values.indexOf(constr));
			}
		}
		return null;
	}
	
	public function typeCreateEnumIndex(index:Int, ?arguments:Array<Dynamic>):Dynamic
	{
		return typeCreateEnum(values[index], arguments);
	}
	
	public function typeGetEnumConstructs():Array<String>
	{
		return (values?.copy() ?? []);
	}
	
	public function typeAllEnums():Array<Dynamic>
	{
		var enums:Array<InsanityScriptedEnumValue> = [];
		
		for (index => constr in values)
		{
			if (constructs.get(constr).arguments == null) enums.push(new InsanityScriptedEnumValue(this, index));
		}
		
		return enums;
	}
	
	public function reflectHasField(field:String):Bool
	{
		return false;
	}
	
	public function reflectGetField(field:String):Dynamic
	{
		var construct:EnumFieldDecl = constructs.get(field);
		if (construct != null)
		{
			if (constructFunctions.exists(field))
			{
				return constructFunctions.get(field);
			}
			else
			{
				return new InsanityScriptedEnumValue(this, values.indexOf(field));
			}
		}
		return null;
	}
	
	public function reflectSetField(field:String, value:Dynamic):Dynamic
	{
		return null;
	}
	
	public function reflectGetProperty(property:String):Dynamic
	{
		return reflectGetField(property);
	}
	
	public function reflectSetProperty(property:String, value:Dynamic):Dynamic
	{
		return null;
	}
	
	public function reflectListFields():Array<String>
	{
		return null;
	}
	
	public function snapshot():Void {}
}

class InsanityScriptedEnumValue implements ICustomEnumValueType
{
	var base:InsanityScriptedEnum;
	
	public var index:Int;
	public var constructor:String;
	public var arguments:Array<Dynamic>;
	
	public function new(base:InsanityScriptedEnum, index:Int, ?arguments:Array<Dynamic>)
	{
		this.base = base;
		this.arguments = arguments;
		
		this.index = index;
		this.constructor = base.values[index];
	}
	
	public function toString():String
	{
		if (arguments != null) return '$constructor(${arguments.join(',')})';
		
		return constructor;
	}
	
	public function typeGetEnum():Dynamic
	{
		return base;
	}
	
	public function eq(o:ICustomEnumValueType):Bool
	{
		if (!(o is InsanityScriptedEnumValue)) return false;
		
		var o:InsanityScriptedEnumValue = cast o;
		if (o.base == base)
		{
			if (o.arguments == null && arguments == null) return true;
			
			for (i => argument in arguments)
			{
				if (argument != o.arguments[i]) return false;
			}
			
			return true;
		}
		
		return false;
	}
}

class InsanityDummyClass implements IInsanityScripted
{
	public function new() {}
}

interface IInsanityType
{
	public var name:String;
	public var module:Module;
	public var pack:Array<String>;
	public var path:String;
	
	public var failed:Bool;
	public var initialized:Bool;
	public var initializing:Bool;
	
	public function init(?env:Environment, ?baseInterp:Interp, restore:Bool = true):Void;
	public function snapshot():Void;
}

@:autoBuild(insanity.backend.macro.ScriptedMacro.build())
interface IInsanityScripted extends ICustomReflection extends ICustomClassType
{
	private var __base:InsanityScriptedClass;
	private var __interp:insanity.backend.Interp;
	private var __vars:Map<String, insanity.backend.Interp.Variable>;
	
	private var __safe:Bool;
	private var __func:String;
	private var __fields:Array<String>;
	
	private function __construct(base:InsanityScriptedClass, arguments:Array<Dynamic>):Void;
}

enum Defer
{
	DDefer;
}
