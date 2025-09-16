package funkin.objects;

import flixel.util.helpers.FlxBounds;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;

@:nullSafety
class Bar extends FlxSpriteGroup
{
	public final bg:FlxSprite;
	public final leftBar:FlxSprite;
	public final rightBar:FlxSprite;
	
	public var valueFunction:Null<Void->Float> = null;
	
	public var percent(default, set):Float = 0;
	
	public var bounds:FlxBounds<Float> = new FlxBounds(0.0, 0.0);
	
	public var leftToRight(default, set):Bool = true;
	
	public var barCenter(default, null):Float = 0;
	
	/**
	 * Custom width set for the bars fill
	 * 
	 * default is bar frame width - 6
	 */
	public var barWidth(default, set):Int = 1;
	
	/**
	 * Custom height set for the bars fill
	 * 
	 * default is bar frame height - 6
	 */
	public var barHeight(default, set):Int = 1;
	
	/**
	 * additive offset for the bar fill position
	 */
	public var barOffset:FlxPoint = new FlxPoint(3, 3);
	
	public function new(x:Float, y:Float, image:String = 'healthBar', ?valueFunction:Void->Float, boundX:Float = 0, boundY:Float = 1)
	{
		super(x, y);
		
		this.valueFunction = valueFunction;
		
		bg = new FlxSprite().loadGraphic(Paths.image(image));
		bg.setPosition(bg.x, bg.y);
		
		@:bypassAccessor barWidth = Std.int(bg.width - 6);
		@:bypassAccessor barHeight = Std.int(bg.height - 6);
		
		leftBar = new FlxSprite().makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.WHITE);
		
		rightBar = new FlxSprite().makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.WHITE);
		rightBar.color = FlxColor.BLACK;
		
		add(leftBar);
		add(rightBar);
		add(bg);
		
		setBounds(boundX, boundY);
		
		regenerateClips();
	}
	
	public var enabled:Bool = true;
	
	override function update(elapsed:Float)
	{
		if (!enabled)
		{
			super.update(elapsed);
			return;
		}
		
		if (valueFunction != null)
		{
			var value:Null<Float> = FlxMath.remapToRange(FlxMath.bound(valueFunction(), bounds.min, bounds.max), bounds.min, bounds.max, 0, 100);
			percent = (value != null ? value : 0);
		}
		else percent = 0;
		super.update(elapsed);
	}
	
	public function setBounds(min:Float, max:Float)
	{
		bounds.min = min;
		bounds.max = max;
	}
	
	public function setColors(?left:FlxColor, ?right:FlxColor)
	{
		if (left != null) leftBar.color = left;
		if (right != null) rightBar.color = right;
	}
	
	public function updateBar()
	{
		if (leftBar == null || rightBar == null) return;
		
		leftBar.setPosition(bg.x, bg.y);
		rightBar.setPosition(bg.x, bg.y);
		
		var leftSize:Float = 0;
		if (leftToRight) leftSize = FlxMath.lerp(0, barWidth, percent / 100);
		else leftSize = FlxMath.lerp(0, barWidth, 1 - percent / 100);
		
		leftBar.clipRect.width = leftSize;
		leftBar.clipRect.height = barHeight;
		leftBar.clipRect.x = barOffset.x;
		leftBar.clipRect.y = barOffset.y;
		
		rightBar.clipRect.width = barWidth - leftSize;
		rightBar.clipRect.height = barHeight;
		rightBar.clipRect.x = barOffset.x + leftSize;
		rightBar.clipRect.y = barOffset.y;
		
		barCenter = leftBar.x + leftSize + barOffset.x;
		
		// flixel is retarded
		leftBar.clipRect = leftBar.clipRect;
		rightBar.clipRect = rightBar.clipRect;
	}
	
	public function regenerateClips()
	{
		if (leftBar != null)
		{
			if (Std.int(leftBar.frameWidth) != Std.int(bg.frameWidth) || Std.int(leftBar.frameHeight) != Std.int(bg.frameHeight))
			{
				leftBar.makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.WHITE);
			}
			else
			{
				leftBar.setGraphicSize(Std.int(bg.width), Std.int(bg.height));
			}
			leftBar.updateHitbox();
			leftBar.clipRect = new FlxRect(0, 0, Std.int(bg.width), Std.int(bg.height));
		}
		if (rightBar != null)
		{
			if (rightBar.frameWidth != Std.int(bg.frameWidth) || rightBar.frameHeight != Std.int(bg.frameHeight))
			{
				rightBar.makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.WHITE);
			}
			else
			{
				rightBar.setGraphicSize(Std.int(bg.width), Std.int(bg.height));
			}
			rightBar.updateHitbox();
			rightBar.clipRect = new FlxRect(0, 0, Std.int(bg.width), Std.int(bg.height));
		}
		updateBar();
	}
	
	private function set_percent(value:Float)
	{
		var doUpdate:Bool = false;
		if (value != percent) doUpdate = true;
		percent = value;
		
		if (doUpdate) updateBar();
		return value;
	}
	
	private function set_leftToRight(value:Bool)
	{
		leftToRight = value;
		updateBar();
		return value;
	}
	
	private function set_barWidth(value:Int)
	{
		barWidth = value;
		regenerateClips();
		return value;
	}
	
	private function set_barHeight(value:Int)
	{
		barHeight = value;
		regenerateClips();
		return value;
	}
}
