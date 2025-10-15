package funkin.backend;

import flixel.FlxSubState;
import flixel.util.FlxDestroyUtil;
import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.backend.PlayerSettings;
import funkin.data.*;
import funkin.scripts.*;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}
	
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;
	
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;
	
	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	
	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;
	
	inline function get_controls():Controls return PlayerSettings.player1.controls;
	
	public var scripted:Bool = false;
	public var scriptName:String = '';
	public var scriptPrefix:String = 'menus/substates'; // not rlly a fan of the folder being named menus tbh - data5
	public var scriptGroup:ScriptGroup = new ScriptGroup();
	
	public function initStateScript(?scriptName:String, callOnCreate:Bool = true):Bool
	{
		if (scriptName == null)
		{
			final stateName = Type.getClassName(Type.getClass(this)).split('.').pop();
			scriptName = stateName ?? '???';
		}
		
		this.scriptName = scriptName;
		
		final scriptFile = FunkinScript.getPath('scripts/$scriptPrefix/$scriptName');
		
		if (FunkinAssets.exists(scriptFile))
		{
			var _script = FunkinScript.fromFile(scriptFile);
			if (_script.__garbage)
			{
				_script = FlxDestroyUtil.destroy(_script);
				return false;
			}
			
			scriptGroup.parent = this;
			
			Logger.log('script [$scriptName] initialized', NOTICE);
			
			scriptGroup.addScript(_script);
			scripted = true;
		}
		
		if (callOnCreate) scriptGroup.call('onCreate', []);
		
		return scripted;
	}
	
	inline function isHardcodedState() return (scriptGroup != null && !scriptGroup.call('customMenu') == true) || (scriptGroup == null);
	
	public function refreshZ(?group:FlxTypedGroup<FlxBasic>)
	{
		group ??= FlxG.state;
		group.sort(SortUtil.sortByZ, flixel.util.FlxSort.ASCENDING);
	}
	
	override function update(elapsed:Float)
	{
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
		
		scriptGroup.call('onUpdate', [elapsed]);
		
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
	
	function getBeatsOnSection():Float
	{
		return PlayState.SONG?.notes[curSection]?.sectionBeats ?? 4.0;
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
	
	public function stepHit():Void
	{
		if (curStep % 4 == 0) beatHit();
		scriptGroup.call('onStepHit', [curStep]);
	}
	
	public function beatHit():Void
	{
		scriptGroup.call('onBeatHit', [curBeat]);
	}
	
	public function sectionHit()
	{
		scriptGroup.call('onSectionHit');
	}
	
	override function destroy()
	{
		scriptGroup.call('onDestroy', []);
		
		scriptGroup = FlxDestroyUtil.destroy(scriptGroup);
		
		super.destroy();
	}
}
