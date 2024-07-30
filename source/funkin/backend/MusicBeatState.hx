package funkin.backend; 

import funkin.backend.BaseTransitionState;
import funkin.states.transitions.SwipeTransition;
import flixel.addons.ui.FlxUIState;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxState;
import funkin.data.*;

class MusicBeatState extends FlxUIState
{
	//do not touch.
	@:noCompletion static var _defaultTransState:Class<BaseTransitionState> = SwipeTransition;

	//change these to change the transition
	public static var transitionInState:Class<BaseTransitionState> = null;
	public static var transitionOutState:Class<BaseTransitionState> = null;

	public function new() {super();}

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	public static var camBeat:FlxCamera;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function create() {
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();
	}
	

	#if (VIDEOS_ALLOWED && windows)
	override public function onFocus():Void
	{
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();
	}
	#end

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrotchet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState)
	{
		FlxG.switchState(nextState); // just because im too lazy to goto every instance of switchState and change it to a FlxG call
	}

	public static function resetState()
	{
		FlxG.resetState();
	}

	public static function getState():MusicBeatState {
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}



	//overriden to use our own custom trans subs
	override function get_hasTransOut():Bool
	{
		return true;
	}
	override public function transitionOut(?OnExit:Void->Void):Void
	{
		_onExit = OnExit;
		if (FlxTransitionableState.skipNextTransOut) {
			FlxTransitionableState.skipNextTransOut = false;
			_onExit();
		}
		else {
			var transClass = _defaultTransState;
			if (transitionOutState != null) transClass = transitionOutState;
			var _trans:BaseTransitionState = Type.createInstance(transClass,[IN_TO]);
			openSubState(_trans);
			_trans.setCallback(finishTransOut);

		}
	}

	override public function transitionIn():Void
	{
		if (FlxTransitionableState.skipNextTransIn) {
			FlxTransitionableState.skipNextTransIn = false;
			if (finishTransIn != null)finishTransIn();
			return;
		}

		var transClass = _defaultTransState;
		if (transitionInState != null) transClass = transitionInState;
		var _trans:BaseTransitionState = Type.createInstance(transClass,[OUT_OF]);
		openSubState(_trans);
		_trans.setCallback(finishTransIn);

	}
}
