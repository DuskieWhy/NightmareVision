package funkin.objects;

import flixel.graphics.frames.FlxAtlasFrames;

import animate.FlxAnimateFrames;
import animate.FlxAnimate;

class FunkinSprite extends FlxAnimate
{
	/**
	 *	Animation offsets
	 * 
	 * applied through `playAnim`
	 */
	public final animOffsets:Map<String, Array<Float>> = [];
	
	/**
	 * The current sprite offset.
	 * 
	 * This offset is transformed by scale, angle and skew (whenever applicable) when drawing the sprite and is applied regardless of the current animation.
	 */
	public final spriteOffset:FlxPoint = FlxPoint.get();
	
	/**
	 * The current animation offset.
	 * 
	 * This offset is transformed by scale, angle and skew (whenever applicable) when drawing the sprite.
	 */
	public final animOffset:FlxPoint = FlxPoint.get();
	
	/**
	 * Base scale for sprite / animation offsets.
	 */
	public final baseScale:FlxPoint = FlxPoint.get(1, 1);
	
	/**
	 * If true, animation offsets will scale with the sprite.
	 */
	public var scalableOffsets:Bool = true;
	
	/**
	 * If true, animation offsets will rotate with the sprite.
	 */
	public var rotatableOffsets:Bool = true;
	
	/**
	 * If true, animation offsets will skew with the sprite.
	 */
	public var skewableOffsets:Bool = true;
	
	/**
	 * Corrects this sprite's animation offsets when it's flipped.
	 * 
	 * (incomplete saaave me saaave me)
	 */
	public var correctFlippedOffsets:Bool = false;
	
	/**
	 * If `false`, playAnim will no longer function
	 * 
	 * used by `playAnimForDuration`'s `force` arguement.
	 */
	public var canPlayAnimations:Bool = true;
	
	/**
	 * Loads frames onto the sprite
	 * 
	 * It can load multiple sparrow, packer, and texture atlases simultaneously.
	 * 
	 * This is the recommended way to load frames for a bopper
	 * @param path the image path to the frames. For multiple, split the path with `,` For texture atlas, Provide the path to the folder.
	 * 
	 * @return this `Bopper` instance. Useful for chaining
	 */
	public function loadAtlas(path:String):FunkinSprite
	{
		final splitPath = path.split(',');
		
		var framesFound:Array<FlxAtlasFrames> = [];
		
		var containsFlxAnimate:Bool = false;
		
		for (path in splitPath)
		{
			path = path.trim();
			
			final isAtlasSprite = FunkinAssets.exists(Paths.getPath('images/$path/Animation.json', null, true));
			if (isAtlasSprite)
			{
				var atlas = FlxAnimateFrames.fromAnimate(Paths.getPath('images/$path', null, true), null, null, null, false, {cacheOnLoad: true});
				if (atlas != null)
				{
					// unsure if flxanimate messes with the buffer or not but if it does then drop this
					if (ClientPrefs.gpuCaching && atlas.parent.bitmap != null) atlas.parent.bitmap.disposeImage();
					
					containsFlxAnimate = true;
					
					framesFound.push(atlas);
				}
			}
			else
			{
				var atlas = Paths.getAtlasFrames(path);
				
				if (atlas != null) framesFound.push(atlas);
			}
		}
		
		if (framesFound.length != 0)
		{
			if (containsFlxAnimate) // a bit hacky workaround.. we cant keep use cached bitmaps in multi collection // look into this later
			{
				for (collection in framesFound)
				{
					@:privateAccess
					{
						var path = collection.parent.key.withoutExtension();
						if (Paths.tempAtlasFramesCache.exists(path)) Paths.tempAtlasFramesCache.remove(path);
					}
					
					if (FunkinAssets.cache.currentTrackedGraphics.exists(collection.parent.key))
					{
						FunkinAssets.cache.currentTrackedGraphics.remove(collection.parent.key);
					}
					
					collection.parent.persist = false;
				}
			}
			this.frames = FlxAnimateFrames.combineAtlas(framesFound);
		}
		
		return this;
	}
	
	/**
	 * Ensures a anim exists before playing
	 * 
	 * If there is no anim but there is a suffix, it will strip the suffix and try again
	 * 
	 * If still fails, `Null` is returned.
	 */
	public function correctAnimationName(animName:String):Null<String> // from base game !
	{
		if (hasAnim(animName)) return animName;
		
		// strip any post fix
		if (animName.lastIndexOf('-') != -1)
		{
			final correctedName = animName.substring(0, animName.lastIndexOf('-'));
			return correctAnimationName(correctedName);
		}
		
		return null;
	}
	
	/**
	 * Use over `animation.play`
	 */
	@:inheritDoc(flixel.animation.FlxAnimationController.play)
	public function playAnim(animToPlay:String, isForced:Bool = false, isReversed:Bool = false, frame:Int = 0):Void
	{
		if (!canPlayAnimations) return;
		
		final correctedAnim = correctAnimationName(animToPlay);
		
		if (correctedAnim == null) return;
		
		animation.play(correctedAnim, isForced, isReversed, frame);
		
		setOffsets(correctedAnim);
	}

	public function setOffsets(anim:String = 'idle')
	{
		final animationOffsets = animOffsets.get(anim);
		
		if (animationOffsets != null)
		{
			animOffset.set(animationOffsets[0], animationOffsets[1]);
			
			if (correctFlippedOffsets)
			{
				final scaleXFactor:Float = scalableOffsets ? scale.x : 1.0;
				final scaleYFactor:Float = scalableOffsets ? scale.y : 1.0;
				
				if (flipX) animOffset.x = ((frameWidth * scaleXFactor) - width) - animOffset.x;
				
				if (flipY) animOffset.y = ((frameHeight * scaleYFactor) - height) - animOffset.y;
			}
		}
	}
	
	final forcedAnimationTimer:FlxTimer = new FlxTimer();
	
	/**
	 * Plays a animation for a given amount of time and will `dance` when it is done
	 * @param forced If true, the character will not play any other animation until the duration is complete
	 */
	public function playAnimForDuration(animToPlay:String, duration:Float = 0.6, forced:Bool = false)
	{
		if (forced) canPlayAnimations = true;
		playAnim(animToPlay, true);
		
		if (forced) canPlayAnimations = false;
		forcedAnimationTimer.start(duration, tmr -> {
			if (forced) canPlayAnimations = true;
			// dance();
		});
	}
	
	/**
	 * Helper function to quickly set an anim offset
	 */
	public function addOffset(anim:String, x:Float = 0, y:Float = 0):Void
	{
		animOffsets[anim] = [x, y];
	}
	
	/**
	 * Helper function add a animation by prefix. It will attempt to add by `frame label`, `symbol`, then `prefix`
	 */
	@:inheritDoc(flixel.animation.FlxAnimationController.addByPrefix)
	public function addAnimByPrefix(name:String, prefix:String, fps:Int = 24, looping:Bool = true, flipX:Bool = false, flipY:Bool = false)
	{
		if (library != null && anim.findFrameLabelIndices(prefix).length > 0)
		{
			anim.addByFrameLabel(name, prefix, fps, looping, flipX, flipY);
		}
		else if (checkLibraryForSymbol(library, prefix))
		{
			anim.addBySymbol(name, prefix, fps, looping, flipX, flipY);
		}
		else
		{
			animation.addByPrefix(name, prefix, fps, looping, flipX, flipY);
		}
	}
	
	/**
	 * Helper function add a animation by indices. It will attempt to add by `frame label`, `symbol`, then `prefix`
	 */
	@:inheritDoc(flixel.animation.FlxAnimationController.addByIndices)
	public function addAnimByIndices(name:String, prefix:String, indices:Array<Int>, fps:Int = 24, looping:Bool = true, flipX:Bool = false, flipY:Bool = false)
	{
		if (library != null && anim.findFrameLabelIndices(prefix).length > 0)
		{
			anim.addByFrameLabelIndices(name, prefix, indices, fps, looping, flipX, flipY);
		}
		else if (checkLibraryForSymbol(library, prefix))
		{
			anim.addBySymbolIndices(name, prefix, indices, fps, looping, flipX, flipY);
		}
		else
		{
			animation.addByIndices(name, prefix, indices, '', fps, looping, flipX, flipY);
		}
	}
	
	@:access(animate.FlxAnimateFrames)
	static function checkLibraryForSymbol(atlasLibrary:FlxAnimateFrames, symbolName:String) // exists symbol doesnt check additional collections so heres my workaround.
	{
		if (atlasLibrary == null) return false;
		
		if (atlasLibrary.existsSymbol(symbolName)) return true;
		
		for (collection in atlasLibrary.addedCollections)
		{
			if (collection.dictionary.exists(symbolName)) return true;
		}
		
		return false;
	}
	
	// these funcs primarily exist for compat reasons
	
	public inline function getAnimName():String return isAnimNull() ? '' : animation.curAnim.name;
	
	public inline function hasAnim(anim:String):Bool return animation.exists(anim);
	
	public inline function isAnimNull():Bool return animation.curAnim == null;
	
	public inline function isAnimFinished():Bool return isAnimNull() ? false : animation.curAnim.finished;
	
	public inline function pauseAnim():Void animation.pause();
	
	public inline function resumeAnim():Void animation.resume();
	
	public inline function getAnimNumFrames():Int return isAnimNull() ? 0 : animation.curAnim.numFrames;
	
	public var animCurFrame(get, set):Int;
	
	inline function get_animCurFrame():Int return isAnimNull() ? 0 : animation.curAnim.curFrame;
	
	inline function set_animCurFrame(value:Int):Int return isAnimNull() ? 0 : (animation.curAnim.curFrame = value);
	
	public inline function removeAnim(anim:String):Void
	{
		animation.remove(anim);
		animOffsets.remove(anim);
	}
	
	public inline function finishAnim():Void
	{
		if (isAnimNull()) return;
		
		animation.finish();
	}
	
	public inline function stopAnim():Void
	{
		if (isAnimNull()) return;
		
		animation.stop();
	}
	
	public override function destroy():Void
	{
		_transformedAnimOffset.put();
		spriteOffset.put();
		animOffset.put();
		
		super.destroy();
	}
	
	var _transformedAnimOffset:FlxPoint = FlxPoint.get();
	
	override function prepareDrawMatrix(matrix:flixel.math.FlxMatrix, camera:FlxCamera):Void
	{
		super.prepareDrawMatrix(matrix, camera);
		
		transformSpriteOffset(_transformedAnimOffset);
		if (isPixelPerfectRender(camera)) _transformedAnimOffset.floor();
		
		matrix.translate(-_transformedAnimOffset.x, -_transformedAnimOffset.y);
	}
	
	inline function transformSpriteOffset(?point:FlxPoint):FlxPoint
	{
		point ??= FlxPoint.weak();
		
		point.set(spriteOffset.x + animOffset.x, spriteOffset.y + animOffset.y);
		
		if (scalableOffsets) point.scale(scale.x / baseScale.x, scale.y / baseScale.y);
		
		if (rotatableOffsets && FlxMath.mod(angle, 360) > 0) point.rotateByDegrees(angle);
		
		if (skewableOffsets && (skew.x != 0 || skew.y != 0))
		{
			final pX:Float = point.x, pY:Float = point.y;
			
			point.x += (pY * Math.tan(skew.x / 180 * Math.PI));
			point.y += (pX * Math.tan(skew.y / 180 * Math.PI));
		}
		
		return point;
	}
	
	override function clone():FunkinSprite
	{
		final spr = new FunkinSprite();
		
		spr.frames = this.frames;
		spr.animation.copyFrom(this.animation);
		
		for (key in this.animOffsets.keys())
		{
			var offsets = this.animOffsets.get(key);
			
			spr.animOffsets.set(key, offsets);
		}
		
		spr.spriteOffset.copyFrom(this.spriteOffset);
		spr.baseScale.copyFrom(this.baseScale);
		spr.scale.copyFrom(this.scale);
		
		spr.updateHitbox();
		
		return spr;
	}
}
