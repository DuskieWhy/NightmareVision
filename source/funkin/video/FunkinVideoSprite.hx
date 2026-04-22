package funkin.video;

// sigh rework coming again soon
import funkin.input.Controls;

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;
import hxvlc.util.Location;

// with hxvlcs improvements this is less needed but still has its values

/**
 * Handles video playback as a `FlxSprite`. Has additional features for ease
 * 
 * If used in `PlayState`, will autopause when the game is paused too
 * 
 * General Usage:
 * ```haxe
 * 	var video = new FunkinVideoSprite(x,y);
 * 	add(video);
 * 	video.onFormat(()->{
 * 		video.setGraphicSize(0,FlxG.height);
 * 		video.updateHitbox();
 * 		video.screenCenter(FlxAxes.X);
 * 
 * 	});
 * 	if (video.load(Paths.video('pathToVideo')))
 * 	{
 *		video.delayAndStart();
 * 	}
 * ```
 */
class FunkinVideoSprite extends FlxVideoSprite
{
	/**
	 * All currently active video instances
	 */
	public static final instances:Array<FunkinVideoSprite> = [];
	
	/**
	 * Video loading argument to make the video loop
	 * 
	 * Usage:
	 * ```haxe
	 * video.load(Paths.video(''),[FunkinVideoSprite.looping]);
	 * ```
	 */
	public static final looping:String = ':input-repeat=65535';
	
	/**
	 * Video loading argument to make the video muted
	 * Use if your video doesnt require audio
	 * 
	 * Usage:
	 * ```haxe
	 * video.load(Paths.video(''),[FunkinVideoSprite.muted]);
	 * ```
	 */
	public static final muted:String = ':no-audio';
	
	/**
	 * Manually initiates the Libvlc instance
	 */
	public static function init()
	{
		hxvlc.util.Handle.init();
	}
	
	/**
	 * Bool that decides if `this` should be affected by states
	 * 
	 * Disable this if you dont want your video to pause when paused in `PlayState`
	 */
	public var tiedToGame:Bool = true;
	
	/**
	 * Bool that decides if the video can be skipped.
	 */
	public var canSkip:Bool = false;
	
	/**
	 * The playback speed of the video. 1.0 is normal speed.
	 */
	public var playbackRate(default, set):Float = 1.0;
	
	function set_playbackRate(value:Float):Float
	{
		if (bitmap != null) bitmap.rate = value;
		
		return playbackRate = value;
	}
	
	/** Returns whether the video is currently playing. */
	public var isPlaying(get, never):Bool;
	
	inline function get_isPlaying():Bool return bitmap != null && bitmap.isPlaying;
	
	/**
	 * Returns a normalized progress value (`0.0` to `1.0`) representing
	 * how far through the video playback currently is.
	 * Returns `0.0` if the video has no duration.
	 */
	public var progress(get, never):Float;
	
	inline function get_progress():Float
	{
		if (bitmap == null || bitmap.length <= 0) return 0.0;
		return (haxe.Int64.toInt(bitmap.time) : Float) / (haxe.Int64.toInt(bitmap.length) : Float);
	}
	
	/**
	 * Returns the current playback position in milliseconds.
	 * Returns `-1` if the bitmap is unavailable.
	 */
	public var currentTime(get, never):Int;
	
	inline function get_currentTime():Int return bitmap != null ? haxe.Int64.toInt(bitmap.length) : -1;
	
	/**
	 * Returns the total duration of the loaded video in milliseconds.
	 * Returns `-1` if unavailable or not yet loaded.
	 */
	public var duration(get, never):Int;
	
	inline function get_duration():Int return bitmap != null ? haxe.Int64.toInt(bitmap.length) : -1;
	
	/**
	 * Sets the volume of the video's audio. Range is `0.0` (silent) to `1.0` (full).
	 * Values are clamped to this range automatically.
	 */
	public var volume(default, set):Float = 1.0;
	
	function set_volume(value:Float):Float
	{
		value = FlxMath.bound(value, 0.0, 1.0);
		if (bitmap != null) bitmap.volume = Std.int(value * 100);
		return volume = value;
	}
	
	/**
	 * Creates a new FunkinVideoSprite
	 * @param x `x` position
	 * @param y `y` position
	 * @param oneTimeUse if `true` on video complete, the video will self destroy
	 */
	public function new(x:Float = 0, y:Float = 0, oneTimeUse:Bool = true, isSkippable = false)
	{
		super(x, y);
		canSkip = isSkippable;
		if (oneTimeUse) bitmap.onEndReached.add(this.destroy, true, -10);
		
		instances.push(this);
	}
	
	/**
	 * Starts the video but sets a delay before starting
	 * 
	 * Recommended over `this.play`
	 * @param delay The delay before the video starts. default is next update call
	 */
	public function delayAndStart(delay:Float = 0)
	{
		FlxTimer.wait(delay, function() {
			if (bitmap != null) play();
		});
	}
	
	// flxvideosprite already contains these 2
	// /** Pauses the video. */
	// public function pause()
	// {
	// 	if (bitmap != null) bitmap.pause();
	// }
	// /** Resumes the video. */
	// public function resume()
	// {
	// 	if (bitmap != null) bitmap.resume();
	// }
	
	/**
	 * Adds a event to be dispatched when the video reaches its end
	 * @param func the event to be called
	 * @param once if this event should be dispatched once, or every time the video ends.
	 */
	public function onEnd(func:Void->Void, once:Bool = false, priority:Int = 0)
	{
		if (bitmap != null) bitmap.onEndReached.add(func, once, priority);
	}
	
	/**
	 * Adds a event to be dispatched when the video starts
	 * @param func the event to be called
	 * @param once if this event should be dispatched once, or every time the video ends.
	 */
	public function onStart(func:Void->Void, once:Bool = false, priority:Int = 0)
	{
		if (bitmap != null) bitmap.onOpening.add(func, once, priority);
	}
	
	/**
	 * Adds a callback to be dispatched when the video is paused.
	 * 
	 * @param func The function to call when the video pauses.
	 * @param once If `true`, the callback fires only once.
	 * @param priority Signal priority for dispatch ordering.
	 */
	public function onPause(func:Void->Void, once:Bool = false, priority:Int = 0)
	{
		if (bitmap != null) bitmap.onPaused.add(func, once, priority);
	}
	
	/**
	 * Adds a callback dispatched when the video is stopped (not paused — fully stopped).
	 * 
	 * @param func The function to call on stop.
	 * @param once If `true`, the callback fires only once.
	 * @param priority Signal priority for dispatch ordering.
	 */
	public function onStop(func:Void->Void, once:Bool = false, priority:Int = 0)
	{
		if (bitmap != null) bitmap.onStopped.add(func, once, priority);
	}
	
	/**
	 * Adds a callback dispatched when an error is encountered during playback or loading.
	 * 
	 * @param func The function to call on error. Receives no parameters.
	 * @param once If `true`, the callback fires only once.
	 * @param priority Signal priority for dispatch ordering.
	 */
	public function onError(func:String->Void, once:Bool = false, priority:Int = 0)
	{
		if (bitmap != null) bitmap.onEncounteredError.add(func, once, priority);
	}
	
	/**
	 * Adds a event to be dispatched when the video has formatted itself 
	 * 
	 * Recommended to setup ur video during this event
	 * example: 
	 * ```haxe
	 * 	onFormat(()->{
	 * 		this.scale.set(3,3);
	 * 		this.updateHitbox();
	 * 		this.cameras = [camera];
	 * 	});
	 * ```
	 * @param func the event to be called
	 * @param once if this event should be dispatched once, or every time the video ends.
	 */
	public function onFormat(func:Void->Void, once:Bool = false, priority:Int = 0)
	{
		if (bitmap != null) bitmap.onFormatSetup.add(func, once, priority);
	}
	
	/**
	 * Stops the video immediately and triggers the onEndReached event.
	 * Useful for skipping cutscenes.
	 */
	public function skip()
	{
		if (bitmap != null && bitmap.isPlaying)
		{
			bitmap.stop();
		}
	}
	
	/**
	 * Seeks to a specific time position in the video.
	 * 
	 * @param time The time in milliseconds to seek to.
	 */
	public function seekTo(time:Int)
	{
		if (bitmap != null) bitmap.time = time;
	}
	
	/**
	 * Seeks to a normalized position in the video.
	 * 
	 * @param value A value from `0.0` (start) to `1.0` (end).
	 */
	public function seekToProgress(value:Float)
	{
		if (bitmap != null && bitmap.length > 0) bitmap.time = haxe.Int64.ofInt(Std.int(FlxMath.bound(value, 0.0, 1.0) * haxe.Int64.toInt(bitmap.length)));
	}
	
	override public function update(elapsed:Float)
	{
		if (canSkip && Controls.instance.ACCEPT)
		{
			skip();
		}
	}
	
	/**
	 * Quickly scales and centers the video to fit the entire screen.
	 * Best used inside the `onFormat` callback!
	 */
	public function fitToScreen()
	{
		setGraphicSize(FlxG.width, FlxG.height);
		updateHitbox();
		screenCenter();
	}
	
	override function destroy()
	{
		if (instances.contains(this)) instances.remove(this);
		
		if (bitmap != null)
		{
			bitmap.stop();
			bitmap.onEndReached.removeAll();
			
			bitmap.onFormatSetup.removeAll();
			
			bitmap.onOpening.removeAll();
			
			if (FlxG.signals.focusGained.has(bitmap.resume)) FlxG.signals.focusGained.remove(bitmap.resume);
			if (FlxG.signals.focusLost.has(bitmap.pause)) FlxG.signals.focusLost.remove(bitmap.pause);
		}
		
		super.destroy();
	}
	
	/**
	 * Iterates over `FunkinVideoSprite.instances` and calls a function on them
	 */
	public static function forEach(func:FunkinVideoSprite->Void)
	{
		for (video in instances)
			if (video != null) func(video);
	}
	
	/**
	 * Iterates over `FunkinVideoSprite.instances` and calls a function on them
	 */
	public static function forEachAlive(func:FunkinVideoSprite->Void)
	{
		for (video in instances)
			if (video != null && video.exists && video.alive) func(video);
	}
}
#end
