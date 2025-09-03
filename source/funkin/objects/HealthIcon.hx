package funkin.objects;

import flixel.FlxSprite;

@:nullSafety
class HealthIcon extends FlxSprite
{
	/**
	 * Optional parented sprite
	 * 
	 * If set `this` will follow the set parents position
	 */
	public var sprTracker:Null<FlxSprite> = null;
	
	/**
	 * Additional offsets for the icon
	 * 
	 * Used when `sprTracker` is not null.
	 */
	public var sprOffsets(default, null):FlxPoint = FlxPoint.get(10, -30);
	
	/**
	 * The icons current character name
	 */
	public var characterName(default, null):String = '';
	
	var iconOffsets:Array<Float> = [0, 0];
	
	/**
	 * Used to decide if the icon will be flipped
	 */
	var isPlayer:Bool = false;
	
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
		
		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + sprOffsets.x, sprTracker.y + sprOffsets.y);
	}
	
	/**
	 * Attempts to load a new icon by file name
	 */
	public function changeIcon(char:String)
	{
		if (this.characterName == char) return;
		
		this.characterName = char;
		
		var name:String = 'icons/' + char;
		if (!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; // Older versions of psych engine's support
		if (!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; // Prevents crash from missing icon
		
		final graphic = Paths.image(name, null, false);
		
		loadGraphic(graphic, true, Math.floor(graphic.width / 2), Math.floor(graphic.height));
		iconOffsets[0] = (width - 150) / 2;
		iconOffsets[1] = (width - 150) / 2;
		updateHitbox();
		
		animation.add(char, [0, 1], 0, false, isPlayer);
		animation.play(char);
		
		antialiasing = char.endsWith('-pixel') ? false : ClientPrefs.globalAntialiasing;
	}
	
	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}
	
	override function destroy()
	{
		sprOffsets = FlxDestroyUtil.put(sprOffsets);
		super.destroy();
	}
}
