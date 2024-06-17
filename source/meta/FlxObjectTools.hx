package meta;

import meta.data.ClientPrefs;
import meta.data.Paths;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;

// datas beautiful static extensions
class FlxObjectTools
{

	//timer but it like checks if it aint null for you
	static inline public function cancelTween(tween:FlxTween):FlxTween
	{
		if (tween != null) tween.cancel();
		return tween;
	}

	//timer but it like checks if it aint null for you
	static inline public function cancelTmr(timer:FlxTimer):FlxTimer
	{
		if (timer != null) timer.cancel();
		return timer;
	}

	//not correct term to call it but idk what else 
	static inline public function generateGraphic(sprite:FlxSprite, width:Float,height:Float,color:FlxColor = FlxColor.WHITE):FlxSprite
	{
		sprite.makeGraphic(1,1,color);
		sprite.setGraphicSize(Std.int(width),Std.int(height));
		sprite.updateHitbox();
		return sprite;
	}
	static inline public function loadImage(sprite:FlxSprite, image:String, lib:Null<String> = null):FlxSprite
	{
		return sprite.loadGraphic(Paths.image(image, lib));
	}

    static inline public function loadFrames(sprite:FlxSprite, image:String, lib:Null<String> = null):FlxSprite
    {
        sprite.frames = Paths.getSparrowAtlas(image,lib);
        return sprite;
    }

	/**
	* persistent draw hide
	*/
	static inline public function hide(sprite:FlxSprite):FlxSprite
	{
		sprite.alpha = 0.000000001;
		return sprite;
	}

	/**
	 * applies shader to sprite BUT checks if its allowed to.
	 * @param useFramePixel prevents frame clipping on shader usage.
	 */
	static inline public function applyShader(sprite:FlxSprite,shader:flixel.system.FlxAssets.FlxShader,useFramePixel = false):FlxSprite
	{
		//if (!ClientPrefs.shaders) return sprite;
		sprite.useFramePixels = useFramePixel;
		sprite.shader = shader;
		return sprite;
	}

	static inline public function setScale(sprite:FlxSprite, scaleX:Float, ?scaleY:Null<Float> = null, ?updatehitbox = true):FlxSprite
	{
		#if (haxe >= "4.3.0") scaleY ??= scaleX; #else if (scaleY == null) scaleY = scaleX; #end

		sprite.scale.set(scaleX, scaleY);
		if (updatehitbox) sprite.updateHitbox();
		return sprite;
	}

	static inline public function graphicSize(sprite:FlxSprite, width:Float = 0, height:Float = 0, updatehitbox = true):FlxSprite
	{
		if (width <= 0 && height <= 0)
			return sprite;

		var newScaleX:Float = width / sprite.frameWidth;
		var newScaleY:Float = height / sprite.frameHeight;
		sprite.scale.set(newScaleX, newScaleY);

		if (width <= 0)
			sprite.scale.x = newScaleY;
		else if (height <= 0)
			sprite.scale.y = newScaleX;

		if (updatehitbox) sprite.updateHitbox();
		return sprite;
	}

	static inline public function centerOnSprite(sprite:FlxSprite, spr:FlxSprite, axes:FlxAxes = XY):FlxSprite
	{
		if (axes.x) sprite.x = spr.x + (spr.width - sprite.width) / 2;
		if (axes.y) sprite.y = spr.y + (spr.height - sprite.height) / 2;

		return sprite;
	}

	static inline public function screenAlignment(sprite:FlxSprite, alignment:SpriteAlignment):FlxSprite
	{
		switch (alignment) {
			case TOPLEFT:
				sprite.setPosition();
			case TOPMID:
				sprite.screenCenter(X);
				sprite.y = 0;
			case TOPRIGHT:
				sprite.setPosition(FlxG.width-sprite.width,0);
			case MIDLEFT:
				sprite.screenCenter(Y);
				sprite.x = 0;
			case MIDDLE:
				sprite.screenCenter();
			case MIDRIGHT:
				sprite.screenCenter(Y);
				sprite.x = FlxG.width-sprite.width;
			case BOTTOMLEFT:
				sprite.setPosition(0, FlxG.height-sprite.height);
			case BOTTOMMID:
				sprite.screenCenter(X);
				sprite.y = FlxG.height - sprite.height;
			case BOTTOMRIGHT:
				sprite.setPosition(FlxG.width - sprite.width, FlxG.height - sprite.height);
		}

		return sprite;
	}


	//-----------animShortcuts-----------//

	static inline public function addAnimByPrefix(sprite:FlxSprite,name:String,prefix:String,fps:Int = 24,looped:Bool = true):FlxSprite
	{
		sprite.animation.addByPrefix(name,prefix,fps,looped);
		return sprite;
	}

	static inline public function playAnim(sprite:FlxSprite,name:String,forced:Bool = true):FlxSprite
	{
		sprite.animation.play(name,forced);
		return sprite;
	}
	static inline public function getCurAnimName(sprite:FlxSprite):String
	{
		return sprite.animation.curAnim.name;
	}

}


enum SpriteAlignment 
{
	TOPLEFT;
	TOPMID;
	TOPRIGHT;
	MIDLEFT;
	MIDDLE;
	MIDRIGHT;
	BOTTOMLEFT;
	BOTTOMMID;
	BOTTOMRIGHT;
}