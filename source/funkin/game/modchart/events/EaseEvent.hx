// @author Nebula_Zorua
package funkin.game.modchart.events;

import flixel.tweens.FlxEase;

class EaseEvent extends ModEvent
{
	public var endStep:Float = 0;
	public var startVal:Null<Float>;
	public var easeFunc:EaseFunction;
	public var length:Float = 0;
	
	public function new(step:Float, endStep:Float, modName:String, target:Float, easeFunc:EaseFunction, player:Int = 0, modMgr:ModManager, ?startVal:Float)
	{
		super(step, modName, target, player, modMgr);
		this.endStep = endStep;
		this.easeFunc = easeFunc;
		this.startVal = startVal;
		if (mod == null) trace(modName + " is null!");
		
		length = endStep - step;
	}
	
	function ease(e:EaseFunction, t:Float, b:Float, c:Float, d:Float)
	{ // elapsed, begin, change (ending-beginning), duration
		var time = t / d;
		return c * e(time) + b;
	}
	
	override function run(curStep:Float)
	{
		if (curStep <= endStep)
		{
			if (this.startVal == null) this.startVal = mod.getValue(player);
			
			var passed = curStep - executionStep;
			var change = endVal - startVal;
			// mod.setValue(ease(easeFunc, passed, startVal, change, length), player);
			manager.setValue(modName, ease(easeFunc, passed, startVal, change, length), player);
		}
		else if (curStep > endStep)
		{
			finished = true;
			manager.setValue(modName, endVal, player);
		}
	}
}
