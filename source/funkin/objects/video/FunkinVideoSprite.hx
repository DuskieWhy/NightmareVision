package funkin.objects.video;

import openfl.Assets;
import haxe.io.Bytes;
import hxvlc.flixel.FlxVideoSprite;

class FunkinVideoSprite extends FlxVideoSprite
{
	static var _init:Bool = false;

	public static function init()
	{
		if (_init) return;
		_init = true;
		trace('handle init? ' + hxvlc.util.Handle.init());
	}

	public static final looping:String = ':input-repeat=65535';
	public static final muted:String = ':no-audio';

	public function new(x:Float = 0, y:Float = 0, destroyOnUse:Bool = true, dontAdd:Bool = false)
	{
		super(x, y);

		if (destroyOnUse) bitmap.onEndReached.add(() -> {
			this.destroy();
		}, true);

		if (!dontAdd) tryAddingToPlayState();
	}

	function tryAddingToPlayState()
	{
		if (Std.isOfType(FlxG.state, PlayState) && PlayState.instance != null)
		{
			var cur:PlayState = cast FlxG.state;

			cur.onPauseSignal.add(this.pause);
			cur.onResumeSignal.add(this.resume);
		}
	}

	// this was gonna be more elaborate but i decided not to
	function decipherLocation(local:Location)
	{
		if (local != null && !(local is Int) && !(local is Bytes) && (local is String))
		{
			var local:String = cast(local, String);

			var modPath:String = Paths.modFolders('videos/$local');
			var assetPath:String = 'assets/videos/$local';

			// found bytes. return em
			if (Assets.exists(modPath, BINARY)) return cast Assets.getBytes(modPath);
			else if (Assets.exists(assetPath, BINARY)) return cast Assets.getBytes(assetPath);

			if (FileSystem.exists(modPath)) return cast modPath;
			else if (FileSystem.exists(assetPath)) return cast assetPath;
		}

		return local;
	}

	override function load(location:Location, ?options:Array<String>):Bool
	{
		if (bitmap == null) return false;

		if (autoPause)
		{
			if (!FlxG.signals.focusGained.has(bitmap.resume)) FlxG.signals.focusGained.add(bitmap.resume);
			if (!FlxG.signals.focusLost.has(bitmap.pause)) FlxG.signals.focusLost.add(bitmap.pause);
		}

		final realLocal = decipherLocation(location);

		if (realLocal != null && !(realLocal is Int) && !(realLocal is Bytes) && (realLocal is String))
		{
			final realLocal:String = cast(realLocal, String);

			if (!realLocal.contains('://'))
			{
				final absolutePath:String = FileSystem.absolutePath(realLocal);

				if (FileSystem.exists(absolutePath)) return bitmap.load(absolutePath, options);
				else
				{
					FlxG.log.warn('Unable to find the video file at location "$absolutePath".');

					return false;
				}
			}
		}

		return bitmap.load(realLocal, options);
	}

	override function pause()
	{
		super.pause();

		if (autoPause)
		{
			if (FlxG.signals.focusGained.has(bitmap.resume)) FlxG.signals.focusGained.remove(bitmap.resume);
			if (FlxG.signals.focusLost.has(bitmap.pause)) FlxG.signals.focusLost.remove(bitmap.pause);
		}
	}

	override function resume()
	{
		super.resume();
		if (autoPause)
		{
			if (!FlxG.signals.focusGained.has(bitmap.resume)) FlxG.signals.focusGained.add(bitmap.resume);
			if (!FlxG.signals.focusLost.has(bitmap.pause)) FlxG.signals.focusLost.add(bitmap.pause);
		}
	}

	public function addCallback(vidCallBack:VidCallbacks, func:Void->Void, once:Bool = false)
	{
		switch (vidCallBack)
		{
			case ONEND:
				if (func != null) bitmap.onEndReached.add(func, once);
			case ONSTART:
				if (func != null) bitmap.onOpening.add(func, once);
			case ONFORMAT:
				if (func != null) bitmap.onFormatSetup.add(func, once);
		}
	}

	public static function quickGen(data:VideoData)
	{
		var video = new FunkinVideoSprite();
		final isMute = data.muted ? muted : '';
		final loops = data.loops ? looping : '';
		video.load(data.file, [isMute, loops]);
		return video;
	}

	public static function cacheVid(path:String)
	{
		var video = new FunkinVideoSprite(0, 0, false, true);
		video.load(path, [muted]);
		video.addCallback(ONFORMAT, () -> {
			video.destroy();
		});
		video.play();
	}

	override function destroy()
	{
		if (Std.isOfType(FlxG.state, PlayState) && PlayState.instance != null)
		{
			var cur:PlayState = cast FlxG.state;
			if (cur.onPauseSignal.has(this.pause)) cur.onPauseSignal.remove(this.pause);
			if (cur.onResumeSignal.has(this.resume)) cur.onResumeSignal.remove(this.resume);
		}
		if (bitmap != null)
		{
			bitmap.stop();

			if (FlxG.signals.focusGained.has(bitmap.resume)) FlxG.signals.focusGained.remove(bitmap.resume);
			if (FlxG.signals.focusLost.has(bitmap.pause)) FlxG.signals.focusLost.remove(bitmap.pause);
		}

		super.destroy();
	}
}

typedef VideoData =
{
	file:String,
	loops:Bool,
	muted:Bool
}

enum abstract VidCallbacks(String) to String from String
{
	public var ONEND:String = 'onEnd';
	public var ONSTART:String = 'onStart';
	public var ONFORMAT:String = 'onFormat';
}

typedef Location = #if (hxvlc <= "1.5.5") hxvlc.util.OneOfThree<String, Int, Bytes>; #else hxvlc.util.Location; #end
