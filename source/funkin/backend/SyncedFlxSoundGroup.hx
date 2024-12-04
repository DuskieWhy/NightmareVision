package funkin.backend;

import flixel.util.FlxSignal;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;

// based off smth i seen in the funkin repo i liked the idea of it
// @:access(flixel.sound.FlxSound)
class SyncedFlxSoundGroup extends FlxTypedGroup<FlxSound>
{
	public var onComplete:Void->Void = null;

	public var volume(get, set):Float;

	public var pitch(get, set):Float;

	public var time(get, set):Float;

	public var playing(get, never):Bool;

	public function resume() forEachAlive(f -> f.resume());

	public function pause() forEachAlive(f -> f.pause());

	public function play(ForceRestart:Bool = false, StartTime:Float = 0.0, ?EndTime:Null<Float>) forEachAlive(f -> f.play(ForceRestart, StartTime, EndTime));

	public function stop() forEachAlive(f -> f.stop());

	public function new()
	{
		super();
	}

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

	public function getDesyncDifference(?desiredTime:Float)
	{
		desiredTime ??= getFirstAlive().time;

		var diff:Float = 0;
		forEachAlive(f -> {
			final s = Math.abs(f.time - desiredTime);
			if (s > diff) diff = s; // get the highest difference
		});

		return diff;
	}

	public function resync(?time:Float)
	{
		time ??= getFirstAlive().time; // nothing given. synce to the first track

		forEachAlive(f -> {
			f.pause();
			f.time = time;
			f.play(false, time);
		});
	}

	override function destroy()
	{
		stop();
		onComplete = null;
		super.destroy();
	}

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
