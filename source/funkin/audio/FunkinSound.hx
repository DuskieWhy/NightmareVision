package funkin.audio;

import flixel.sound.FlxSoundGroup;
import flixel.system.FlxAssets.FlxSoundAsset;

/**
 * just a copy paste for now 
 */
@:access(flixel.system.frontEnds.SoundFrontEnd)
@:access(flixel.sound.FlxSound)
class FunkinSound
{
	@:inheritDoc(flixel.system.frontEnds.SoundFrontEnd.playMusic)
	public static function playMusic(embeddedMusic:FlxSoundAsset, volume = 1.0, looped = true, ?group:FlxSoundGroup):Void
	{
		FlxG.sound.music ??= new FlxSoundEx();
		FlxG.sound.playMusic(embeddedMusic, volume, looped, group);
	}
	
	@:inheritDoc(flixel.system.frontEnds.SoundFrontEnd.load)
	public static function load(?embeddedSound:FlxSoundAsset, volume = 1.0, looped = false, ?group:FlxSoundGroup, autoDestroy = false, autoPlay = false, ?url:String, ?onComplete:Void->Void,
			?onLoad:Void->Void):FlxSoundEx
	{
		if ((embeddedSound == null) && (url == null))
		{
			FlxG.log.warn("FlxG.sound.load() requires either\nan embedded sound or a URL to work.");
			return null;
		}
		final sound:FlxSoundEx = cast FlxG.sound.list.recycle(FlxSoundEx);
		if (embeddedSound != null)
		{
			sound.loadEmbedded(embeddedSound, looped, autoDestroy, onComplete);
			FlxG.sound.loadHelper(sound, volume, group, autoPlay);
			// Call OnlLoad() because the sound already loaded
			if (onLoad != null && sound._sound != null) onLoad();
		}
		else
		{
			var loadCallback = onLoad;
			if (autoPlay)
			{
				// Auto play the sound when it's done loading
				loadCallback = function() {
					sound.play();
					if (onLoad != null) onLoad();
				}
			}
			sound.loadStream(url, looped, autoDestroy, onComplete, loadCallback);
			FlxG.sound.loadHelper(sound, volume, group);
		}
		return sound;
	}
	
	@:inheritDoc(flixel.system.frontEnds.SoundFrontEnd.play)
	public static function play(embeddedSound:FlxSoundAsset, volume = 1.0, looped = false, ?group:FlxSoundGroup, autoDestroy = true, ?onComplete:Void->Void):FlxSoundEx
	{
		if ((embeddedSound is String))
		{
			embeddedSound = FlxG.sound.cache(embeddedSound);
		}
		final sound = FlxG.sound.list.recycle(FlxSoundEx).loadEmbedded(embeddedSound, looped, autoDestroy, onComplete);
		return cast FlxG.sound.loadHelper(sound, volume, group, true);
	}
}
