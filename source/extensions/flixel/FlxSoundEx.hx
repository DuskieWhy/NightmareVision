package extensions.flixel;

import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.sound.FlxSoundGroup;

class FlxSoundEx extends FlxSound
{
	public var muted(default, set):Bool;
	
	function set_muted(value:Bool):Bool
	{
		muted = value;
		updateTransform();
		return (muted);
	}
	
	override function updateTransform()
	{
		_transform.volume = #if FLX_SOUND_SYSTEM ((FlxG.sound.muted || muted) ? 0 : 1) * FlxG.sound.volume * #end
			(group != null ? group.volume : 1) * _volume * _volumeAdjust;
			
		if (_channel != null) _channel.soundTransform = _transform;
	}
}
