package funkin.backend;

// whole setup for this by data thx
// incredibly basic. if you want to apply more to this feel free
class BaseTransitionState extends MusicBeatSubstate
{
	var finishCallback:Void->Void = null;

	public function setCallback(func:Void->Void) finishCallback = func;

	var status:TransStatus;

	public function new(status:TransStatus)
	{
		this.status = status;
		super();
	}

	// ensure u call this to end!!
	public function onFinish()
	{
		if (finishCallback != null) finishCallback();
	}
}

enum abstract TransStatus(Int) from Int to Int
{
	public var IN_TO = 0;
	public var OUT_OF = 1;
}
