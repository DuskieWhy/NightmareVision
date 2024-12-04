package funkin.states.transitions;

import funkin.backend.BaseTransitionState;
import flixel.util.FlxGradient;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.util.FlxColor;

// the regular swipe transition used in fnf
class SwipeTransition extends BaseTransitionState
{
	var gradientFill:FlxSprite;
	var gradient:FlxSprite;

	public override function destroy():Void
	{
		super.destroy();
		if (gradient != null) gradient.destroy();
		if (gradientFill != null) gradientFill.destroy();
		gradient = null;
		gradientFill = null;
	}

	public override function update(elapsed:Float)
	{
		if (gradientFill != null && gradient != null)
		{
			switch (status)
			{
				case IN_TO:
					gradientFill.y = gradient.y - gradient.height;
				case OUT_OF:
					gradientFill.y = gradient.y + gradient.height;
				default:
			}
		}
		super.update(elapsed);
	}

	override function create()
	{
		var cam = FlxG.cameras.list[FlxG.cameras.list.length - 1];
		cameras = [cam];

		var yStart:Float = 0;
		var yEnd:Float = 0;
		var duration:Float = .48;
		var angle:Int = 90;
		var zoom:Float = FlxMath.bound(cam.zoom, 0.001);
		var width:Int = Math.ceil(cam.width / zoom);
		var height:Int = Math.ceil(cam.height / zoom);

		yStart = -height;
		yEnd = height;

		switch (status)
		{
			case IN_TO:
			case OUT_OF:
				angle = 270;
				duration = .6;
			default:
				// trace("bruh");
		}

		gradient = FlxGradient.createGradientFlxSprite(1, height, [FlxColor.BLACK, FlxColor.TRANSPARENT], 1, angle);
		gradient.scale.x = width;
		gradient.scrollFactor.set();
		gradient.screenCenter(X);
		gradient.y = yStart;

		gradientFill = new FlxSprite().makeScaledGraphic(width, height, FlxColor.BLACK);
		gradientFill.screenCenter(X);
		gradientFill.scrollFactor.set();
		add(gradientFill);
		add(gradient);

		FlxTween.tween(gradient, {y: yEnd}, duration, {onComplete: Void -> onFinish()});

		super.create();
	}
}
