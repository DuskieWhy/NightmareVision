package funkin.objects;

import flixel.FlxSprite;

class HealthIcon extends FlxSprite
{
	public var sprTracker:Null<FlxSprite> = null;
	
	var iconOffsets:Array<Float> = [0, 0];
	
	var isPlayer:Bool = false;
	var char:String = '';
	
	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
	
	public function changeIcon(char:String)
	{
		if (this.char != char)
		{
			var name:String = 'icons/' + char;
			if (!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; // Older versions of psych engine's support
			if (!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; // Prevents crash from missing icon
			final graphic = Paths.image(name, null, false);
			
			loadGraphic(graphic, true, Math.floor(graphic.width / 2), Math.floor(graphic.height)); // Then load it fr
			iconOffsets[0] = (width - 150) / 2;
			iconOffsets[1] = (width - 150) / 2;
			updateHitbox();
			
			animation.add(char, [0, 1], 0, false, isPlayer);
			animation.play(char);
			this.char = char;
			
			antialiasing = char.endsWith('-pixel') ? false : ClientPrefs.globalAntialiasing;
		}
	}
	
	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}
	
	public function getCharacter():String
	{
		return char;
	}
}
