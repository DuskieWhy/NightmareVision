package funkin.states.transitions;

import flixel.util.FlxGradient;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

import funkin.backend.BaseTransitionState;

// the regular swipe transition used in fnf
class SwipeTransition extends BaseTransitionState
{
	var gradientFill:FlxSprite;
	var gradient:FlxSprite;
	
	public override function update(elapsed:Float)
	{
		if (gradientFill != null && gradient != null)
		{
			switch (status)
			{
				case IN:
					gradientFill.y = gradient.y - gradient.height;
				case OUT:
					gradientFill.y = gradient.y + gradient.height;
				default:
			}
		}
		super.update(elapsed);
	}
	
	override function create()
	{
		camera = CameraUtil.lastCamera;
		
		final duration:Float = status == OUT ? 0.6 : 0.48;
		final angle:Int = status == OUT ? 270 : 90;
		
		final yStart:Float = -camera.viewHeight;
		final yEnd:Float = camera.viewHeight;
		
		gradient = FlxGradient.createGradientFlxSprite(1, Math.round(camera.viewHeight), [FlxColor.BLACK, FlxColor.TRANSPARENT], 1, angle);
		gradient.scale.x = camera.viewWidth + 5;
		gradient.scrollFactor.set();
		gradient.screenCenter(X);
		gradient.y = yStart;
		
		gradientFill = new FlxSprite().makeScaledGraphic(camera.viewWidth + 5, camera.viewHeight, FlxColor.BLACK);
		gradientFill.screenCenter(X);
		gradientFill.scrollFactor.set();
		add(gradientFill);
		add(gradient);
		
		FlxTween.tween(gradient, {y: yEnd}, duration, {onComplete: Void -> dispatchFinish()});
		
		super.create();
	}
}
