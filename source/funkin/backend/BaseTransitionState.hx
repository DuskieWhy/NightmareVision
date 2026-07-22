package funkin.backend;

import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;

import funkin.states.transitions.*;
import funkin.data.FunkinTransitionState;
import funkin.scripts.FunkinScript;

// incredibly basic. if you want to apply more to this feel free
class BaseTransitionState extends MusicBeatSubstate
{
	public var finishCallback:Void->Void = null;
	
	final status:TransitionStatus;
	
	public function new(status:TransitionStatus, ?finishCallback:Void->Void)
	{
		this.status = status;
		if (finishCallback != null) this.finishCallback = finishCallback;
		super();
	}
	
	/**
	 * ends the transition
	 */
	public function dispatchFinish()
	{
		if (finishCallback != null) finishCallback();
		FlxTimer.wait(0, close);
	}
	
	@:access(funkin.states.transitions.ScriptedTransition)
	public static function getTransitionFromState(state:FunkinTransitionState):Class<BaseTransitionState>
	{
		return switch (state)
		{
			case SWIPE: SwipeTransition;
			case FADE: FadeTransition;
			case SCRIPTED(key):
				if (!FunkinAssets.exists(FunkinScript.getPath('scripts/transitions/$key')))
				{
					Logger.log('scripted Transition [$key] not found.', WARN);
					SwipeTransition;
				}
				ScriptedTransition.scriptKey = key;
				
				ScriptedTransition;
			case ENGINE_DEFAULT: getTransitionFromState(MusicBeatState.DEFAULT_TRANSITION_STATE);
			default: SwipeTransition;
		}
	}
}
