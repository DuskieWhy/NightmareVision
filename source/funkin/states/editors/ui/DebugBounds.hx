package funkin.states.editors.ui;

class DebugBounds extends FlxBasic
{
	public var target:Null<FlxSprite> = null;
	
	public var alpha:Float = 1;
	public var color:FlxColor = FlxColor.WHITE;
	
	public var thickness = 3;
	
	final top:FlxSprite;
	final left:FlxSprite;
	final right:FlxSprite;
	final bottom:FlxSprite;
	
	public function new(?target:FlxSprite)
	{
		super();
		
		this.target = target;
		
		top = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		left = new FlxSprite().loadGraphic(top.graphic);
		right = new FlxSprite().loadGraphic(top.graphic);
		bottom = new FlxSprite().loadGraphic(top.graphic);
		
		top.active = left.active = right.active = bottom.active = false;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (target != null)
		{
			final targetBounds = target.getGraphicBounds();
			
			// set the cameras
			top.cameras = target.getCameras();
			left.cameras = target.getCameras();
			right.cameras = target.getCameras();
			bottom.cameras = target.getCameras();
			
			// set the sizes
			top.scale.set(targetBounds.width + (thickness * 2), thickness);
			top.updateHitbox();
			
			left.scale.set(thickness, targetBounds.height + thickness);
			left.updateHitbox();
			
			right.scale.set(thickness, targetBounds.height + thickness);
			right.updateHitbox();
			
			bottom.scale.set(targetBounds.width, thickness);
			bottom.updateHitbox();
			
			// position em
			top.x = targetBounds.x - thickness;
			top.y = targetBounds.y - thickness;
			
			left.x = targetBounds.x - thickness;
			left.y = targetBounds.y;
			
			bottom.x = targetBounds.x;
			bottom.y = targetBounds.bottom;
			
			right.x = targetBounds.right;
			right.y = targetBounds.y;
			
			top.alpha = alpha;
			right.alpha = alpha;
			left.alpha = alpha;
			bottom.alpha = alpha;
			
			top.color = color;
			right.color = color;
			left.color = color;
			bottom.color = color;
			
			targetBounds.put();
		}
		else
		{
			visible = false;
		}
	}
	
	override function draw()
	{
		if (visible)
		{
			top.draw();
			left.draw();
			right.draw();
			bottom.draw();
		}
		super.draw();
	}
	
	override function destroy()
	{
		FlxDestroyUtil.destroy(top);
		FlxDestroyUtil.destroy(left);
		FlxDestroyUtil.destroy(right);
		FlxDestroyUtil.destroy(bottom);
		
		super.destroy();
	}
}
