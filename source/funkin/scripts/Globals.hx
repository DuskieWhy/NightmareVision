package funkin.scripts;

import funkin.scripts.FunkinScript.FunkyScript;
import funkin.states.*;
import funkin.states.substates.*;

// this class name feels kinda wrong
class Globals
{
	public static var Function_Stop:Dynamic = 1;
	public static var Function_Continue:Dynamic = 0;
	public static var Function_Halt:Dynamic = 2;
	
	public static inline function getInstance():Dynamic
	{
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}
	
	/**
		Helper function
		Sets a bunch of basic variables for the script depending on the state
	**/
	public static function implementDefaultVars(script:FunkyScript)
	{
		if ((FlxG.state is PlayState))
		{
			script.set("inPlaystate", true);
			script.set('bpm', PlayState.SONG.bpm);
			script.set('scrollSpeed', PlayState.SONG.speed);
			script.set('songName', PlayState.SONG.song);
			script.set('isStoryMode', PlayState.isStoryMode);
			script.set('difficulty', PlayState.storyDifficulty);
			script.set('weekRaw', PlayState.storyWeek);
			script.set('seenCutscene', PlayState.seenCutscene);
			script.set('week', funkin.data.WeekData.weeksList[PlayState.storyWeek]);
			script.set('difficultyName', funkin.backend.Difficulty.difficulties[PlayState.storyDifficulty]);
			script.set('songLength', flixel.FlxG.sound.music.length);
			script.set('healthGainMult', PlayState.instance.healthGain);
			script.set('healthLossMult', PlayState.instance.healthLoss);
			script.set('instakillOnMiss', PlayState.instance.instakillOnMiss);
			script.set('botPlay', PlayState.instance.cpuControlled);
			script.set('practice', PlayState.instance.practiceMode);
			script.set('startedCountdown', false);
		}
		else
		{
			script.set("inPlaystate", false);
		}
		
		script.set('inGameOver', false);
		script.set('downscroll', ClientPrefs.downScroll);
		script.set('middlescroll', ClientPrefs.middleScroll);
		script.set('framerate', ClientPrefs.framerate);
		script.set('ghostTapping', ClientPrefs.ghostTapping);
		script.set('hideHud', ClientPrefs.hideHud);
		script.set('timeBarType', ClientPrefs.timeBarType);
		script.set('scoreZoom', ClientPrefs.scoreZoom);
		script.set('cameraZoomOnBeat', ClientPrefs.camZooms);
		script.set('flashingLights', ClientPrefs.flashing);
		script.set('noteOffset', ClientPrefs.noteOffset);
		script.set('healthBarAlpha', ClientPrefs.healthBarAlpha);
		script.set('noResetButton', ClientPrefs.noReset);
		script.set('lowQuality', ClientPrefs.lowQuality);
		script.set("scriptName", script.scriptName);
		
		script.set('curBpm', Conductor.bpm);
		script.set('crotchet', Conductor.crotchet);
		script.set('stepCrotchet', Conductor.stepCrotchet);
		script.set('Function_Halt', Globals.Function_Halt);
		script.set('Function_Stop', Globals.Function_Stop);
		script.set('Function_Continue', Globals.Function_Continue);
		script.set('curBeat', 0);
		script.set('curStep', 0);
		script.set('curDecBeat', 0);
		script.set('curDecStep', 0);
		script.set('version', Main.NMV_VERSION.trim());
	}
}
