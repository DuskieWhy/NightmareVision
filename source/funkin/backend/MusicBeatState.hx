package funkin.backend;

import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxDestroyUtil;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;

import funkin.backend.BaseTransitionState;
import funkin.states.transitions.SwipeTransition;
import funkin.data.*;
import funkin.scripts.*;

class MusicBeatState extends FlxUIState
{
	static final _defaultTransState:Class<BaseTransitionState> = SwipeTransition;
	
	// change these to change the transition
	public static var transitionInState:Null<Class<BaseTransitionState>> = null;
	public static var transitionOutState:Null<Class<BaseTransitionState>> = null;
	
	public function new() super();
	
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;
	
	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	
	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;
	
	// script related vars
	public var scripted:Bool = false;
	public var scriptName:String = 'Placeholder';
	public var script:HScriptGroup = new HScriptGroup();
	
	inline function isHardcodedState() return (script != null && !script.call('customMenu') == true) || (script == null);
	
	public function setUpScript(?s:String, callOnCreate:Bool = true):Bool
	{
		script.parent = this;
		
		if (s == null)
		{
			final stateName = Type.getClassName(Type.getClass(this)).split('.');
			s = stateName[stateName.length - 1];
		}
		
		scriptName = s;
		
		var scriptFile = FunkinIris.getPath('scripts/menus/$scriptName');
		
		if (FunkinAssets.exists(scriptFile))
		{
			var tScript = FunkinIris.fromFile(scriptFile);
			if (tScript.__garbage)
			{
				tScript = FlxDestroyUtil.destroy(tScript);
				return false;
			}
			
			script.addScript(tScript);
			scripted = true;
		}
		else
		{
			Logger.log('$scriptName script [$scriptName] not found.');
		}
		
		if (callOnCreate) script.call('onCreate', []);
		
		return scripted;
	}
	
	inline function get_controls():Controls return PlayerSettings.player1.controls;
	
	override function create()
	{
		super.create();
		
		if (!FlxTransitionableState.skipNextTransOut)
		{
			openSubState(Type.createInstance(transitionOutState ?? _defaultTransState, [TransitionStatus.OUT]));
		}
		
		FlxTransitionableState.skipNextTransOut = false;
	}
	
	public function refreshZ(?group:FlxTypedGroup<FlxBasic>)
	{
		group ??= FlxG.state;
		group.sort(SortUtil.sortByZ, flixel.util.FlxSort.ASCENDING);
	}
	
	override function update(elapsed:Float)
	{
		// everyStep();
		var oldStep:Int = curStep;
		
		updateCurStep();
		updateBeat();
		
		if (oldStep != curStep)
		{
			if (curStep > 0) stepHit();
			
			if (PlayState.SONG != null)
			{
				if (oldStep < curStep) updateSection();
				else rollbackSection();
			}
		}
		
		script.call('onUpdate', [elapsed]);
		
		super.update(elapsed);
	}
	
	private function updateSection():Void
	{
		if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}
	
	private function rollbackSection():Void
	{
		if (curStep < 0) return;
		
		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep) break;
				
				curSection++;
			}
		}
		
		if (curSection > lastSection) sectionHit();
	}
	
	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}
	
	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
		
		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrotchet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}
	
	public static function getState():MusicBeatState
	{
		return cast FlxG.state;
	}
	
	public function stepHit():Void
	{
		if (curStep % 4 == 0) beatHit();
		script.call('onStepHit', [curStep]);
	}
	
	public function beatHit():Void
	{
		script.call('onBeatHit', [curBeat]);
	}
	
	public function sectionHit():Void {}
	
	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
	
	@:access(funkin.states.FreeplayState)
	override function startOutro(onOutroComplete:() -> Void)
	{
		FlxG.sound?.music?.fadeTween?.cancel();
		FreeplayState.vocals?.fadeTween?.cancel();
		
		if (FlxG.sound != null && FlxG.sound.music != null) FlxG.sound.music.onComplete = null;
		
		if (!FlxTransitionableState.skipNextTransIn)
		{
			openSubState(Type.createInstance(transitionInState ?? _defaultTransState, [TransitionStatus.IN, onOutroComplete]));
			return;
		}
		
		FlxTransitionableState.skipNextTransIn = false;
		
		super.startOutro(onOutroComplete);
	}
	
	override function destroy()
	{
		script.call('onDestroy');
		
		script = FlxDestroyUtil.destroy(script);
		
		super.destroy();
	}
}
