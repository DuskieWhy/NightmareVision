package funkin.backend;

import flixel.util.FlxSignal;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;

/**
 * Container of FlxSounds with some functions to make multiple tracks act as one
 */
@:nullSafety(Strict)
class SyncedFlxSoundGroup extends FlxTypedGroup<FlxSound>
{
	// // make this work later lol
	// public var onFinish:FlxSignal;
	
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
	public function resume() forEachAlive(snd -> snd.resume());
	
	@:inheritDoc(flixel.sound.FlxSound.pause)
	public function pause() forEachAlive(snd -> snd.pause());
	
	@:inheritDoc(flixel.sound.FlxSound.play)
	public function play(forceRestart:Bool = false, startTime:Float = 0.0, ?endTime:Null<Float>) forEachAlive(snd -> snd.play(forceRestart, startTime, endTime));
	
	@:inheritDoc(flixel.sound.FlxSound.stop)
	public function stop() forEachAlive(snd -> snd.stop());
	
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
		var snd = super.add(sound);
		if (snd == null) return snd;
		
		// copy the group settings
		snd.time = time;
		snd.pitch = pitch;
		snd.volume = volume;
		
		FlxG.sound.list.add(snd);
		
		return snd;
	}
	
	/**
	 * Culls through the group to find the largest desync value
	 * @param baseTime The reference to compare difference to. Defaults to the groups first instance's time
	 */
	public function getDesyncDifference(?baseTime:Float)
	{
		final time = baseTime ?? getFirstAlive()?.time ?? 0.0;
		
		var diff:Float = 0;
		forEachAlive(snd -> {
			final s = Math.abs(snd.time - time);
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
		final time = baseTime ?? getFirstAlive()?.time ?? 0.0;
		
		forEachAlive(snd -> {
			snd.pause();
			snd.time = time;
			snd.play(false, time);
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
		forEachAlive(snd -> snd.volume = value);
		return value;
	}
	
	function get_volume():Float return getFirstAlive()?.volume ?? 1.0;
	
	function set_pitch(value:Float):Float
	{
		#if FLX_PITCH
		forEachAlive(snd -> snd.pitch = value);
		#else
		return 1.0;
		#end
		
		return value;
	}
	
	function get_pitch():Float return #if FLX_PITCH getFirstAlive()?.pitch ?? 1.0 #else 1.0 #end;
	
	function set_time(value:Float):Float
	{
		forEachAlive(snd -> snd.time = value);
		return value;
	}
	
	function get_time():Float return getFirstAlive()?.time ?? 0.0;
	
	function get_playing():Bool return getFirstAlive()?.playing ?? false;
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
	
	public function addOpponentVocals(?sound:flixel.sound.FlxSound)
	{
		if (sound == null) return null;
		opponentVocals.add(sound);
		return add(sound);
	}
	
	public function addPlayerVocals(?sound:flixel.sound.FlxSound)
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
	
	function get_playerVolume():Float return playerVocals?.volume ?? 1.0;
	
	function set_opponentVolume(value:Float):Float
	{
		if (opponentVocals != null) opponentVocals.volume = value;
		return value;
	}
	
	function get_opponentVolume():Float return opponentVocals?.volume ?? 1.0;
	
	override function clear()
	{
		opponentVocals.clear();
		playerVocals.clear();
		super.clear();
	}
	
	override function destroy()
	{
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
		playerVocals = FlxDestroyUtil.destroy(playerVocals);
		
		super.destroy();
	}
}
