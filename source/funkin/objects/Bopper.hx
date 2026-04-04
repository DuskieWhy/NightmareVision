package funkin.objects;

import flixel.graphics.frames.FlxAtlasFrames;

import animate.FlxAnimateFrames;
import animate.FlxAnimate;

import flixel.util.FlxSignal.FlxTypedSignal;

// highly based of base games bopper class
// i liked it alot
class Bopper extends FunkinSprite
{
	@:inheritDoc(flixel.animation.FlxAnimationController.onFinish)
	public final onAnimationFinish = new FlxTypedSignal<(animName:String) -> Void>();
	
	@:inheritDoc(flixel.animation.FlxAnimationController.onFrameChange)
	public final onAnimationFrameChange = new FlxTypedSignal<(animName:String, frameNumber:Int, frameIndex:Int) -> Void>();
	
	@:inheritDoc(flixel.animation.FlxAnimationController.onLoop)
	public final onAnimationLoop = new FlxTypedSignal<(animName:String) -> Void>();
	
	/**
	 * Texture atlas instance. Initiated through `loadAtlas`.
	 */
	@:deprecated("animateAtlas is deprecated. Use this Bopper directly instead.")
	public var animateAtlas(get, never):Null<FlxAnimate>;
	
	function get_animateAtlas():Null<FlxAnimate>
	{
		if (library != null) return this;
		return null;
	}
	
	/**
	 * However many beats between dances
	 */
	public var danceEveryNumBeats:Int = 2;
	
	/**
	 * Whether the bopper should dance left and right.
	 * - If true, alternate playing `danceLeft` and `danceRight`.
	 * - If false, play `idle` every time.
	 *
	 * You can manually set this value, or you can leave it as `null` to determine it automatically.
	 */
	public var alternatingDance:Null<Bool> = null;
	
	/**
	 * internal tracker for alternating dance chars.
	 */
	var danced:Bool = false;
	
	/**
	 * Suffix added to the characters `dance` animation.
	 */
	public var idleSuffix:String = '';
	
	//-----
	
	public function new(x:Float = 0, y:Float = 0, danceEveryNumBeats:Int = 2)
	{
		super(x, y);
		this.danceEveryNumBeats = danceEveryNumBeats;
		
		this.animation.onFinish.add((anim) -> onAnimationFinish.dispatch(anim));
		this.animation.onFrameChange.add((anim, num, idx) -> onAnimationFrameChange.dispatch(anim, num, idx));
		this.animation.onLoop.add((anim) -> onAnimationLoop.dispatch(anim));
	}
	
	/**
	 * If false, This `Bopper` will be unable to dance
	 */
	public var canDance:Bool = true;
	
	/**
	 * Makes the sprite "dance".
	 */
	public function dance(forced:Bool = false):Void
	{
		if (alternatingDance == null)
		{
			recalculateDanceIdle();
		}
		
		if (!canDance) return;
		
		if (alternatingDance)
		{
			danced = !danced;
			if (danced) playAnim('danceRight$idleSuffix', forced);
			else playAnim('danceLeft$idleSuffix', forced);
		}
		else
		{
			playAnim('idle$idleSuffix', forced);
		}
	}
	
	/**
	 * Updates if the current character has a alternating `left/right` dance
	 */
	public function recalculateDanceIdle():Void
	{
		alternatingDance = hasAnim('danceLeft' + idleSuffix) && hasAnim('danceRight' + idleSuffix);
	}
	
	public function onBeatHit(beat:Int)
	{
		if (!isAnimNull() && beat % danceEveryNumBeats == 0) dance();
	}
	
	override function destroy()
	{
		onAnimationFinish.removeAll();
		onAnimationFrameChange.removeAll();
		onAnimationFinish.removeAll();
		
		super.destroy();
	}
}
