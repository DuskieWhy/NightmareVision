package funkin.backend;

import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;

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
}
