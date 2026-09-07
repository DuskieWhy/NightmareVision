package funkin.audio;

import flixel.util.FlxSignal;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;

import funkin.data.Song;

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
	
	public var songLength(get, never):Float;
	
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
		if (snd != getFirstAlive()) snd.endTime = snd.length;
		
		FlxG.sound.list.add(snd);
		
		return snd;
	}
	
	// if vocals are shorter than inst, game doesnt bug out and get stuck in a cycle of looping the vocals over and over and over and...
	public inline function checkLength(snd:Null<FlxSound>):Bool
	{
		return ((snd?.time ?? 0) < (snd?.length ?? 1));
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
			if (checkLength(snd))
			{
				final s = Math.abs(snd.time - time);
				if (s > diff) diff = s; // get the highest difference
			}
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
			if (checkLength(snd))
			{
				snd.pause();
				snd.time = time;
				snd.play(false, time);
			}
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
	
	function get_songLength():Float return getFirstAlive()?.length ?? 0.0;
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

@:nullSafety(Strict)
class PlayableSong extends VocalGroup
{
	public var inst:Null<FlxSound> = null;
	public var trackSwap:Bool = false;
	public var splitVocals:Bool = false;
	public var hasVoices:Bool = false;
	
	// used for checking if the voices are there & still actively playing
	private function validVoiceGroup(group:SyncedFlxSoundGroup):Bool return ((group?.length ?? 0) > 0 && (group?.checkLength(group?.getFirstAlive()) ?? false));
	
	// basically, if the song has voices, check if any of the voices are still playing. if so, return true. if otherwise, return false. same thing for if the song has no voices
	public function syncVoiceStatus():Bool
	{
		if (trackSwap || !hasVoices) return false;
		
		for (group in [playerVocals, opponentVocals])
		{
			if (validVoiceGroup(group)) return true;
		}
		
		return false;
	}
	
	public function populate(?data:Song):Void
	{
		volume = 1;
		
		if (data == null)
		{
			Logger.log('Song provided was null. Cannot create tracks', WARN);
			
			return;
		}
		
		volume = 1;
		
		splitVocals = false;
		trackSwap = data.trackSwap ?? false;
		
		if (trackSwap)
		{
			final instSnd = Paths.trackSwap(data.song, 'main');
			if (instSnd != null)
			{
				inst = new FlxSoundEx().loadEmbedded(instSnd);
				add(inst);
			}
			
			final missTrack = Paths.trackSwap(data.song, 'miss');
			if (missTrack != null) addOpponentVocals(new FlxSoundEx().loadEmbedded(missTrack));
			
			opponentVolume = 0;
		}
		else
		{
			inst = new FlxSoundEx().loadEmbedded(Paths.inst(data.song));
			add(inst);
			
			if (data.needsVoices)
			{
				hasVoices = true;
				
				var playerSound = Paths.voices(data.song, 'player');
				if (playerSound == null) playerSound = Paths.voices(data.song, null);
				if (playerSound != null) addPlayerVocals(new FlxSoundEx().loadEmbedded(playerSound));
				
				final opponentSound = Paths.voices(data.song, 'opp');
				if (opponentSound != null) addOpponentVocals(new FlxSoundEx().loadEmbedded(opponentSound));
				
				splitVocals = playerVocals.length != 0 && opponentVocals.length != 0;
			}
		}
	}
	
	override public function play(forceRestart:Bool = false, startTime:Float = 0.0, ?endTime:Null<Float>)
	{
		if (trackSwap && inst != null) inst.volume = 0;
		if (endTime == null || endTime == 0) endTime = songLength;
		
		super.play(forceRestart, startTime, endTime);
	}
	
	// for some reason the inst wont stop with calling stop? so itll just null it now. woohoo
	public inline function stopInst() // bandaid remove later
	{
		inst = FlxDestroyUtil.destroy(inst);
	}
	
	public function miss()
	{
		if (trackSwap)
		{
			if (inst != null) inst.volume = 0;
			opponentVolume = 1;
		}
		else playerVolume = 0;
	}
	
	public function hit()
	{
		if (trackSwap)
		{
			if (inst != null) inst.volume = 1;
			opponentVolume = 0;
		}
		else playerVolume = 1;
	}
}
