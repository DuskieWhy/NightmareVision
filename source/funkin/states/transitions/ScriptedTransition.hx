package funkin.states.transitions;

import funkin.backend.BaseTransitionState;
import funkin.backend.MusicBeatState;

class ScriptedTransition extends BaseTransitionState
{
	public static var _transition:String = 'default';
	
	public static function setTransition(newTransition:String)
	{
		if (!FunkinAssets.exists(funkin.scripts.FunkinIris.getPath('scripts/transitions/$newTransition')))
		{
			Logger.log('scripted Transition [$newTransition] not found.', WARN);
			return;
		}
		_transition = newTransition;
		MusicBeatState.transitionInState = ScriptedTransition;
		MusicBeatState.transitionOutState = ScriptedTransition;
	}
	
	override function create()
	{
		scriptPrefix = 'transitions';
		setUpScript(_transition, false);
		
		scriptGroup.call('onCreate', []);
	}
}
