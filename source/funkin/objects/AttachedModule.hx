package funkin.objects;

import flixel.util.FlxAxes;
import flixel.FlxObject;

/**
 * Basic class to help have one Flxobject `follow` another.
 * 
 * Use case:
 * ```haxe
 * // secondSprite will follow the position of the mainSprite
 * var mainSprite = new FlxSprite();
 * add(mainSprite);
 * 
 * var secondSprite = new FlxSprite();
 * add(secondSprite);
 * 
 * var attachedModule = new AttachedModule(secondSprite, mainSprite);
 * add(attachedModule);
 * ```
 */
@:nullSafety
class AttachedModule extends FlxBasic
{
	/**
	 * The core FlxObject that will copy `tracked`.
	 */
	public var root:Null<FlxObject> = null;
	
	/**
	 * The FlxObject that `root` will copy.
	 */
	public var tracked:Null<FlxObject> = null;
	
	/**
	 * The position axis for `root` to copy.
	 * 
	 */
	public var copyAxis:FlxAxes = XY;
	
	/**
	 * Whether `root` will copy `tracked`'s `alpha` param.
	 * 
	 * Note: Only applies if both extend `FlxSprite`.
	 */
	public var copyAlpha:Bool = true;
	
	/**
	 * Whether `root` will copy `tracked`'s `visible` param.
	 */
	public var copyVisibility:Bool = true;
	
	/**
	 * Whether `root` will copy `tracked`'s `angle` param.
	 */
	public var copyAngle:Bool = true;
	
	/**
	 * Additional offset applied to `root` when copying `tracked`'s position.
	 */
	public var positionOffset:FlxPoint = FlxPoint.get();
	
	/**
	 * Additional offset applied to `root` when copying `tracked`'s angle.
	 */
	public var angleOffset:Float = 0;
	
	/**
	 * A multiplier applied onto the copied alpha
	 * 
	 * Note: Only applies if `copyAlpha` is true and both extend `FlxSprite`
	 */
	public var alphaMultiplier:Float = 1;
	
	public function new(root:FlxObject, tracked:FlxObject)
	{
		super();
		this.root = root;
		this.tracked = tracked;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		updateRoot();
	}
	
	function updateRoot()
	{
		if (root != null && tracked != null)
		{
			if (copyAxis.x) root.x = tracked.x + positionOffset.x;
			if (copyAxis.y) root.y = tracked.y + positionOffset.y;
			
			if (copyVisibility) root.visible = tracked.visible;
			if (copyAngle) root.angle = tracked.angle + angleOffset;
			if (copyAlpha)
			{
				if (root is FlxSprite && tracked is FlxSprite)
				{
					(cast root : FlxSprite).alpha = (cast tracked : FlxSprite).alpha * alphaMultiplier;
				}
			}
		}
	}
	
	override function destroy()
	{
		positionOffset.put();
		
		super.destroy();
	}
}

/**
 * FlxSprite with a attachedModule var built in.
 */
class AttachedSprite extends FlxSprite
{
	public var attachedModule:AttachedModule;
	
	public function new(?tracker:FlxObject)
	{
		super();
		
		attachedModule = new AttachedModule(this, tracker);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		attachedModule.update(elapsed);
	}
	
	override function destroy()
	{
		attachedModule.destroy();
		super.destroy();
	}
}
