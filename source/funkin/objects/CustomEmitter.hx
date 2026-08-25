package funkin.objects;

import flixel.util.FlxPool.IFlxPooled;
import flixel.util.helpers.FlxRangeBounds;
import flixel.util.FlxDestroyUtil;
import flixel.effects.particles.FlxParticle;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.effects.particles.FlxEmitter;
import flixel.util.helpers.FlxPointRangeBounds;

// taken from updog 2025 but cleaned up
// originally written by data, new stuff by duskie
class CustomEmitter extends FlxEmitter
{
	public var scrollFactorMin:FlxPoint = new FlxPoint(1.0, 1.0);
	public var scrollFactorMax:FlxPoint = new FlxPoint(1.0, 1.0);

	/**
	 * called on particle emittion
	 */
	public var onEmit(default, null) = new FlxTypedSignal<FlxParticle->Void>();

	public function new(x:Float = 0, y:Float = 0, size:Int = 0)
	{
		super(x, y, size);
	}

	override function emitParticle():FlxParticle
	{
		final _particle = super.emitParticle();
        
        _particle.scrollFactor.set();

		if (scrollFactorMin != null && scrollFactorMax != null)
		{
			final scrollX = FlxG.random.float(scrollFactorMin.x,scrollFactorMax.x);
			final scrollY = FlxG.random.float(scrollFactorMin.y,scrollFactorMax.y);

            _particle.scrollFactor.set(scrollX,scrollY);

		}

		onEmit.dispatch(_particle);

		return _particle;
	}

	override function destroy()
	{
		if (onEmit != null) //this should never happen ???
		{
			onEmit.removeAll();
			onEmit.destroy();
			onEmit = null;
		}
		else trace('onEmit call is null?');

		scrollFactorMin = FlxDestroyUtil.put(scrollFactorMin);
		scrollFactorMax = FlxDestroyUtil.put(scrollFactorMax);

		super.destroy();
	}
}
