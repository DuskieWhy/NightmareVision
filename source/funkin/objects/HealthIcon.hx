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
	public var frameCount(default, set):Int = 3;
	
	public var alphaMultipler(default, set):Float = 1;
	
	// Used to determine if the icon is animated or not, if true it'll try to load an xml file with the same name as the image
	public var isAnimated:Bool = false;
	
	// Used to determine if the icon has a winning or not
	public var hasWinIcon:Bool = false;
	
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
	public function changeIcon(char:String, overide:Bool = false):Void
	{
		if (this.characterName == char && !overide) return;
		
		this.characterName = char;
		
		var name:String = 'icons/' + char;
		if (!Paths.fileExists('images/' + name + '.png')) name = 'icons/icon-' + char; // Older versions of psych engine's support
		if (!Paths.fileExists('images/' + name + '.png')) name = 'icons/icon-face'; // Prevents crash from missing icon
		
		var animToFind:String = Paths.getPath(name + '.xml', null, false);
		
		if (FunkinAssets.exists(animToFind))
		{
			isAnimated = true;
			
			final graphic = Paths.getSparrowAtlas(name, null, false);
			frames = graphic;
			
			animation.addByPrefix('idle', 'idle', 24, true, isPlayer);
			animation.addByPrefix('winning', 'winning', 24, true, isPlayer);
			animation.addByPrefix('losing', 'losing', 24, true, isPlayer);
			animation.addByPrefix('toWinning', 'toWinning', 24, false, isPlayer);
			animation.addByPrefix('toLosing', 'toLosing', 24, false, isPlayer);
			animation.addByPrefix('fromWinning', 'fromWinning', 24, false, isPlayer);
			animation.addByPrefix('fromLosing', 'fromLosing', 24, false, isPlayer);
			animation.play('idle');
			iconOffsets[0] = (width - 150);
			iconOffsets[1] = (height - 150);
		}
		else
		{
			final graphic = Paths.image(name, null, false);
			var iSize:Float = Math.round(graphic.width / graphic.height);
			loadGraphic(graphic, true, Math.floor(graphic.width / iSize), Math.floor(graphic.height));
			iconOffsets[0] = (width - 150) / iSize;
			iconOffsets[1] = (height - 150) / iSize;
			animation.add(char, [for (i in 0...frames.frames.length) i], 0, false, isPlayer);
			animation.play(char); // i do plan on adding more functionality to icons at a later date

			if (animation.curAnim.numFrames == 3) hasWinIcon = true;
		}
		updateHitbox();
		antialiasing = char.endsWith('-pixel') ? false : ClientPrefs.globalAntialiasing;
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
	
	public function getCurrentAnimation():String
	{
		if (this.animation == null || this.animation.curAnim == null) return "";
		return this.animation.curAnim.name;
	}
	
	public function hasAnimation(id:String):Bool
	{
		if (animation == null) return false;
		return animation.getByName(id) != null;
	}
	
	public function isAnimationFinished():Bool return this.animation.finished;
	
	/**
	 * Updates the current animation based on a value from 0 - 1.
	 */
	public inline function updateIconAnim(health:Float):Void
	{
		if (!updateFrames) return;
		
		if (isAnimated)
		{
			switch (getCurrentAnimation())
			{
				case 'idle':
					if (health < 20) playAnimation('toLosing', 'losing');
					else if (health > 80) playAnimation('toWinning', 'winning');
					else playAnimation('idle');
				case 'winning':
					if (health < 80) playAnimation('fromWinning', 'idle');
					else playAnimation('winning', 'idle');
				case 'losing':
					if (health > 20) playAnimation('fromLosing', 'idle');
					else playAnimation('losing', 'idle');
				case 'toLosing':
					if (isAnimationFinished()) playAnimation('losing', 'idle');
				case 'toWinning':
					if (isAnimationFinished()) playAnimation('winning', 'idle');
				case 'fromLosing' | 'fromWinning':
					if (isAnimationFinished()) playAnimation('idle');
				case '':
					playAnimation('idle');
				default:
					playAnimation('idle');
			}
		}
		else animation.frameIndex = health < 0.2 ? 1 : (health > 0.8 && hasWinIcon) ? 2 : 0;
	}
	
	public function playAnimation(name:String, fallback:String = null, restart = false):Void
	{
		// Attempt to play the animation
		if (hasAnimation(name))
		{
			animation.play(name, restart, false, 0);
			return;
		}
		
		// Play the fallback animation if the requested animation was not found
		if (fallback != null && hasAnimation(fallback))
		{
			animation.play(fallback, restart, false, 0);
			return;
		}
	}
}
