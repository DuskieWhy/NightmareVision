package funkin.objects;

import flixel.FlxSprite;

import funkin.game.IUiSprite;

@:nullSafety
class HealthIcon extends FlxSprite implements IUiSprite
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
	
	@:allow(funkin.states.editors.ChartEditorState)
	var updateOffset:Bool = true;
	
	var iconOffsets:Array<Float> = [0, 0];
	
	/**
	 * Used to decide if the icon will be flipped
	 */
	var isPlayer:Bool = false;
	
	/** 
	 * Used for dividing icon based on how many frames it has
	**/
	public var frameCount(default, set):Int = 2;
	
	public var alphaMultipler(default, set):Float = 1;
	
	function set_alphaMultipler(v:Float):Float
	{
		alphaMultipler = FlxMath.bound(v, 0, 1);
		set_alpha(alpha);
		return alphaMultipler;
	}
	
	override function set_alpha(v:Float)
	{
		v = FlxMath.bound(v, 0, 1);
		v *= alphaMultipler;
		return super.set_alpha(v);
	}
	
	public function set_frameCount(value:Int)
	{
		frameCount = value;
		changeIcon(characterName, true);
		
		return value;
	}
	
	/**
	 * Bool that controls whether or not the frame setting is handled automatically
	**/
	public var updateFrames:Bool = true;
	
	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char);
	}
	
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + sprOffsets.x, sprTracker.y + sprOffsets.y);
	}
	
	/**
	 * Attempts to load a new icon by file name
	 */
	public function changeIcon(char:String, forced:Bool = false):HealthIcon
	{
		if (this.characterName == char && !forced) return this;
		
		this.characterName = char;
		
		var name:String = '${Paths.UI_PREFIX}icons/$char';
		if (!Paths.fileExists('images/' + name + '.png')) name = '${Paths.UI_PREFIX}icons/icon-' + char; // Older versions of psych engine's support
		if (!Paths.fileExists('images/' + name + '.png')) name = '${Paths.UI_PREFIX}icons/icon-face'; // Prevents crash from missing icon
		if (!Paths.fileExists('images/' + name + '.png')) name = 'UI/icons/icon-face'; // ultimate fallback incase icon-face doesnt exist in ur custom UI folder
		
		final graphic = Paths.image(name, null, false);
		
		loadGraphic(graphic, true, Math.floor(graphic.width / frameCount), Math.floor(graphic.height));
		iconOffsets[0] = (width - 150) / 2;
		iconOffsets[1] = (width - 150) / 2;
		updateHitbox();
		
		var c = [];
		for (i in 0...frameCount)
			c.push(i);
			
		animation.add(char, c, 0, false, isPlayer);
		animation.play(char); // i do plan on adding more functionality to icons at a later date
		
		antialiasing = char.endsWith('-pixel') ? false : ClientPrefs.globalAntialiasing;
		
		return this;
	}
	
	override function updateHitbox()
	{
		super.updateHitbox();
		
		if (updateOffset)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
	}
	
	override function destroy()
	{
		sprOffsets = FlxDestroyUtil.put(sprOffsets);
		super.destroy();
	}
	
	/**
	 * Updates the current animation based on a value from 0 - 1.
	 */
	public inline function updateIconAnim(health:Float):Void
	{
		if (!updateFrames) return;
		
		animation.frameIndex = health < 0.2 ? 1 : 0;
	}
}
