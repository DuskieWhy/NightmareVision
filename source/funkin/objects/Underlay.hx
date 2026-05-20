package funkin.objects;

import funkin.objects.note.*;

@:nullSafety
class Underlay extends FlxSprite
{
	public var parentField:Null<PlayField>;
	
	public var padding:Float = 15;
	
	public function new(parent:PlayField)
	{
		super(x, y);
		makeGraphic(1, 1, FlxColor.WHITE);
		color = FlxColor.BLACK;
		alpha = ClientPrefs.underlayOpacity;
		scrollFactor.set();
		
		this.parentField = parent;
	}
	
	override public function update(elapsed)
	{
		super.update(elapsed);
		
		if (parentField != null && this != null)
		{
			var minX:Float = Math.POSITIVE_INFINITY;
			var maxX:Float = Math.NEGATIVE_INFINITY;
			
			for (strum in parentField.members)
			{
				if (strum != null && strum.visible)
				{
					if (strum.x < minX) minX = strum.x;
					if ((strum.x + strum.width) > maxX) maxX = strum.x + strum.width;
				}
			}
			
			parentField.forEachAliveNote((daNote:Note) -> {
				if (daNote != null && daNote.isOnScreen())
				{
					if (daNote.x < minX) minX = daNote.x;
					if ((daNote.x + daNote.width) > maxX) maxX = daNote.x + daNote.width;
				}
			});
			
			if (minX != Math.POSITIVE_INFINITY)
			{
				var targetX = minX - padding;
				var targetW = (maxX - minX) + (padding * 2);
				
				// Instant update
				x = FlxMath.lerp(x, targetX, FlxMath.bound(0, 1, elapsed * 60));
				scale.x = FlxMath.lerp(scale.x, targetW, FlxMath.bound(0, 1, elapsed * 60));
				scale.y = FlxG.height / (camera.zoom);
				screenCenter(Y);
				updateHitbox();
			}
		}
	}
}
