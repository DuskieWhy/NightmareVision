package funkin.backend;

import flixel.util.FlxSignal;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;

class SyncedFlxSoundGroup extends FlxTypedGroup<FlxSound>
{
	// make this work later lol
	public var onFinish:FlxSignal;
	
	/**
	 * Set volume to a value between 0 and 1 to change how this sound is.
	 */
	public var volume(get, set):Float;
	
	/**
	 * Set pitch, which also alters the playback speed. Default is 1.
	 */
	public var pitch(get, set):Float;
	
	/**
	 * The position in runtime of the music playback in milliseconds.
	 * If set while paused, changes only come into effect after a `resume()` call.
	 */
	public var time(get, set):Float;
	
	/**
	 * Whether or not the sound is currently playing.
	 */
	public var playing(get, never):Bool;
	
	@:inheritDoc(flixel.sound.FlxSound.resume)
	public function resume() forEachAlive(f -> f.resume());
	
	@:inheritDoc(flixel.sound.FlxSound.pause)
	public function pause() forEachAlive(f -> f.pause());
	
	@:inheritDoc(flixel.sound.FlxSound.play)
	public function play(forceRestart:Bool = false, startTime:Float = 0.0, ?endTime:Null<Float>) forEachAlive(f -> f.play(forceRestart, startTime, endTime));
	
	@:inheritDoc(flixel.sound.FlxSound.stop)
	public function stop() forEachAlive(f -> f.stop());
	
	public function new()
	{
		super();
	}
	
	/**
	 * Adds a new FlxSound instance to the group 
	 * @param sound The FlxSound instance
	 * @return FlxSound
	 */
	override function add(sound:FlxSound):FlxSound
	{
		var f = super.add(sound);
		if (f == null) return f;
		
		// copy the group settings
		f.time = time;
		f.pitch = pitch;
		f.volume = volume;
		
		FlxG.sound.list.add(f);
		
		return f;
	}
	
	/**
	 * Culls through the group to find the largest desync value
	 * @param baseTime The reference to compare difference to. Defaults to the groups first instance's time
	 */
	public function getDesyncDifference(?baseTime:Float)
	{
		baseTime ??= getFirstAlive().time;
		
		var diff:Float = 0;
		forEachAlive(f -> {
			final s = Math.abs(f.time - baseTime);
			if (s > diff) diff = s; // get the highest difference
		});
		
		return diff;
	}
	
	/**
	 * Resyncs all group members to a given time. 
	 * @param baseTime The reference to compare difference to. Defaults to the groups first instance's time
	 */
	public function resync(?baseTime:Float)
	{
		baseTime ??= getFirstAlive().time; // nothing given. synce to the first track
		
		forEachAlive(f -> {
			f.pause();
			f.time = baseTime;
			f.play(false, baseTime);
		});
	}
	
	@:inheritDoc
	override function destroy()
	{
		stop();
		super.destroy();
	}
	
	@:inheritDoc
	override function clear()
	{
		stop();
		super.clear();
	}
	
	function set_volume(value:Float):Float
	{
		forEachAlive(f -> f.volume = value);
		return value;
	}
	
	function get_volume():Float return getFirstAlive() == null ? 1 : getFirstAlive().volume;
	
	function set_pitch(value:Float):Float
	{
		#if FLX_PITCH
		forEachAlive(f -> f.pitch = value);
		#end
		return value;
	}
	
	function get_pitch():Float return #if FLX_PITCH getFirstAlive() == null ? 1 : getFirstAlive().pitch #else 1 #end;
	
	function set_time(value:Float):Float
	{
		forEachAlive(f -> f.time = value);
		return value;
	}
	
	function get_time():Float return getFirstAlive() == null ? 0 : getFirstAlive().time;
	
	function get_playing():Bool return getFirstAlive() == null ? false : getFirstAlive().playing;
}

// specialized ver
class VocalGroup extends SyncedFlxSoundGroup
{
	public var playerVocals:SyncedFlxSoundGroup; // sound groups inside sound groups hype
	public var opponentVocals:SyncedFlxSoundGroup;
	
	public var playerVolume(get, set):Float;
	
	public var opponentVolume(get, set):Float;
	
	public function new()
	{
		super();
		playerVocals = new SyncedFlxSoundGroup();
		opponentVocals = new SyncedFlxSoundGroup();
	}
	
	public function addOpponentVocals(sound:flixel.sound.FlxSound)
	{
		if (sound == null) return null;
		opponentVocals.add(sound);
		return add(sound);
	}
	
	public function addPlayerVocals(sound:flixel.sound.FlxSound)
	{
		if (sound == null) return null;
		playerVocals.add(sound);
		return add(sound);
	}
	
	function set_playerVolume(value:Float):Float
	{
		if (playerVocals != null) playerVocals.volume = value;
		return value;
	}
	
	function get_playerVolume():Float return playerVocals != null ? playerVocals.volume : 1;
	
	function set_opponentVolume(value:Float):Float
	{
		if (opponentVocals != null) opponentVocals.volume = value;
		return value;
	}
	
	function get_opponentVolume():Float return opponentVocals != null ? opponentVocals.volume : 1;
	
	override function clear()
	{
		opponentVocals.clear();
		playerVocals.clear();
		super.clear();
	}
	
	override function destroy()
	{
		if (opponentVocals != null)
		{
			opponentVocals.destroy();
			opponentVocals = null;
		}
		
		if (playerVocals != null)
		{
			playerVocals.destroy();
			playerVocals = null;
		}
		
		super.destroy();
	}
}
