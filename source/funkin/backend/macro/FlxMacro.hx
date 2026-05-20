package funkin.backend.macro;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.Tools;

using Lambda;
#end

class FlxMacro
{
	/**
	 * Adds a variety of functions related to loading sprites for convenienec
	 */
	public static macro function buildFlxSprite():Array<haxe.macro.Expr.Field>
	{
		var fields:Array<haxe.macro.Expr.Field> = Context.getBuildFields();
		
		fields.push(
			{
				name: "loadFromSheet",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [
							{name: 'path', type: (macro :String)},
							{name: 'animName', type: (macro :String)},
							{name: 'fps', type: (macro :Int), value: macro $v{24}},
							{name: 'looped', type: (macro :Bool), value: macro $v{true}}
						],
						expr: macro
						{
							this.frames = funkin.Paths.getAtlasFrames(path);
							this.animation.addByPrefix(animName, animName, fps, looped);
							this.animation.play(animName);
							if (this.animation.curAnim == null || this.animation.curAnim.numFrames == 1)
							{
								this.active = false;
							}
							
							return this;
						}
					}),
				pos: Context.currentPos(),
			});
			
		fields.push(
			{
				doc: "sets frames to the given collection.\nReturns `this` for chaining.",
				name: "loadAtlasFrames",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [
							{name: 'frames', type: (macro :flixel.graphics.frames.FlxAtlasFrames)},
						],
						expr: macro
						{
							this.frames = frames;
							return this;
						}
					}),
				pos: Context.currentPos(),
			});
			
		fields.push(
			{
				doc: "creates a 1x1 graphic and scales it to the given width and height.",
				name: "makeScaledGraphic",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [
							{name: 'width', type: (macro :Float)},
							{name: 'height', type: (macro :Float)},
							{
								name: "color",
								opt: true,
								type: (macro :flixel.util.FlxColor),
								value: (macro flixel.util.FlxColor.WHITE)
							}
						],
						expr: macro
						{
							this.makeGraphic(1, 1, color, false, 'solid#${color.toHexString(true, false)}');
							this.scale.set(width, height);
							this.updateHitbox();
							return this;
						}
					}),
				pos: Context.currentPos(),
			});
			
		fields.push(
			{
				doc: "Sets the scale of an object then updates the hitbox.",
				name: "setScale",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [
							{name: "x", type: (macro :Float)},
							{name: "y", type: (macro :Float)},
							{name: "update", type: (macro :Bool), value: (macro $v{true})}
						],
						expr: macro
						{
							this.scale.set(x, y);
							if (update) this.updateHitbox();
							return this;
						}
					}),
				pos: Context.currentPos(),
			});
			
		fields.push(
			{
				doc: "centers the sprite onto a FlxObject by their hitboxes.",
				name: "centerOnObject",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [
							{name: 'object', type: (macro :flixel.FlxObject)},
							{
								name: 'axes',
								opt: true,
								type: (macro :flixel.util.FlxAxes),
								value: (macro cast 0x11)}
						],
						expr: macro
						{
							if (axes.x) this.x = object.x + (object.width - this.width) / 2;
							if (axes.y) this.y = object.y + (object.height - this.height) / 2;
							return this;
						}
					}),
				pos: Context.currentPos(),
			});
			
		fields.push(
			{
				name: "shake",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [
							{name: 'ShakeValue', type: (macro :Float), value: macro $v{0.05}},
							{name: 'AngleValue', type: (macro :Int), value: macro $v{0}},
							{name: 'Timer', type: (macro :Float), value: macro $v{1}}
						],
						expr: macro
						{
							var stop:Bool = false;
							
							if (!stop)
							{
								if (AngleValue > 360) AngleValue = 360;
								
								offset.x = FlxG.random.float(-ShakeValue, ShakeValue);
								offset.y = FlxG.random.float(-ShakeValue, ShakeValue);
								angle = FlxG.random.int(-AngleValue, AngleValue);
							}
							
							new flixel.util.FlxTimer().start(Timer, timer -> stop = true);
							
							return this;
						}
					}),
				pos: Context.currentPos(),
			});
			
		return fields;
	}
	
	/**
	 * Adds zIndex to `FlxBasic`'
	 */
	public static macro function buildFlxBasic():Array<haxe.macro.Expr.Field>
	{
		var fields:Array<haxe.macro.Expr.Field> = Context.getBuildFields();
		
		fields.push(
			{
				name: "zIndex",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FVar(macro :Int, macro $v{0}),
				pos: Context.currentPos(),
			});
			
		return fields;
	}
	
	public static macro function buildFlxCamera():Array<haxe.macro.Expr.Field>
	{
		var fields:Array<haxe.macro.Expr.Field> = Context.getBuildFields();
		
		fields.push(
			{
				name: "addShader",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [{name: 'shader', type: (macro :flixel.graphics.tile.FlxGraphicsShader)}],
						expr: macro
						{
							if (shader == null) return;
							
							var filter = new openfl.filters.ShaderFilter(shader);
							filters ??= [];
							filters.push(filter);
						}
					}),
				pos: Context.currentPos()
			});
			
		fields.push(
			{
				name: "removeShader",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [{name: 'shader', type: (macro :flixel.graphics.tile.FlxGraphicsShader)}],
						expr: macro
						{
							if (filters == null) return false;
							
							for (filter in filters)
							{
								if (filter is openfl.filters.ShaderFilter)
								{
									var fl:openfl.filters.ShaderFilter = cast filter;
									if (fl.shader == shader)
									{
										filters.remove(filter);
										return true;
									}
								}
							}
							
							return false;
						}
					}),
				pos: Context.currentPos()
			});
			
		return fields;
	}
}
