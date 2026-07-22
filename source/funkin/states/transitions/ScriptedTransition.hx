package funkin.states.transitions;

import funkin.backend.BaseTransitionState;
import funkin.backend.MusicBeatState;

class ScriptedTransition extends BaseTransitionState
{
	public static var scriptKey:String = '';
	
	override function create()
	{
		scriptPrefix = 'transitions';
		initStateScript(scriptKey, false);
		super.create();
		
		scriptGroup.call('onLoad', []);
	}
}
