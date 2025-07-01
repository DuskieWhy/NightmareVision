// @author Nebula_Zorua
package funkin.game.modchart.events;

class StepCallbackEvent extends CallbackEvent
{
	public var endStep:Float = 0;
	
	public function new(step:Float, endStep:Float, callback:(CallbackEvent, Float) -> Void, modMgr:ModManager)
	{
		super(step, callback, modMgr);
		this.endStep = endStep;
	}
	
	override function run(curStep:Float)
	{
		if (curStep <= endStep) callback(this, curStep);
		else finished = true;
	}
}
