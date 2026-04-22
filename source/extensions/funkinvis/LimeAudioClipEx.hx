package extensions.funkinvis;

import funkin.vis.audioclip.frontends.LimeAudioClip;

import lime.media.AudioSource;

class LimeAudioClipEx extends LimeAudioClip
{
	public var trackedSource:Null<FlxSound> = null;
	
	public function new(audioSource:AudioSource, ?trackedSource:FlxSound)
	{
		super(audioSource);
		
		this.trackedSource = trackedSource;
	}
	
	override function get_currentFrame():Int
	{
		var dataLength:Int = 0;
		
		#if web
		dataLength = source.length;
		#else
		dataLength = audioBuffer?.data?.length ?? 0;
		#end
		
		final snd = trackedSource ?? FlxG.sound.music;
		if (snd == null) return -1;
		
		var value = Std.int(FlxMath.remapToRange(snd.time, 0, snd.length, 0, dataLength));
		
		if (value < 0) return -1;
		
		return value;
	}
}
