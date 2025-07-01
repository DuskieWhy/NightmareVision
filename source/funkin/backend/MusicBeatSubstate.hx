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
	public var scriptPrefix:String = 'menus/substates';
	public var scriptGroup:HScriptGroup = new HScriptGroup();
	
	public function setUpScript(s:String = '', callOnCreate:Bool = true):Bool
	{
		scriptGroup.parent = this;
		scriptName = s;
		
		final scriptFile = FunkinIris.getPath('scripts/$scriptPrefix/$scriptName');
		// trace(FunkinIris.getPath('scripts/$scriptPrefix/$scriptName'));
		
		if (FunkinAssets.exists(scriptFile))
		{
			var tScript = FunkinIris.fromFile(scriptFile);
			if (tScript.__garbage)
			{
				tScript = FlxDestroyUtil.destroy(tScript);
				return false;
			}
			
			scriptGroup.addScript(tScript);
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
		// everyStep();
		var oldStep:Int = curStep;
		
		updateCurStep();
		updateBeat();
		
		if (oldStep != curStep && curStep > 0) stepHit();
		
		scriptGroup.call('onUpdate', [elapsed]);
		
		super.update(elapsed);
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
	
	override function destroy()
	{
		scriptGroup.call('onDestroy', []);
		
		scriptGroup = FlxDestroyUtil.destroy(scriptGroup);
		
		super.destroy();
	}
}
