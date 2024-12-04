package funkin.states.transitions;

import funkin.utils.CameraUtil;
import flixel.system.FlxBGSprite;
import funkin.backend.BaseTransitionState;

// simple fade transition between states
class FadeTransition extends BaseTransitionState
{
	var sprite:FixedFlxBGSprite;

	override function create()
	{
		cameras = [CameraUtil.lastCamera];

		sprite = new FixedFlxBGSprite();
		sprite.color = FlxColor.BLACK;
		add(sprite);

		sprite.alpha = status == IN_TO ? 0 : 1;
		final desiredAlpha = status == IN_TO ? 1 : 0;
		final time = status == IN_TO ? 0.48 : 0.8;

		FlxTween.tween(sprite, {alpha: desiredAlpha}, time, {onComplete: Void -> onFinish()});

		super.create();
	}

	override function destroy()
	{
		super.destroy();
		if (sprite != null) sprite.destroy();
		sprite = null;
	}
}

class FixedFlxBGSprite extends FlxBGSprite
{
	@:access(flixel.FlxCamera)
	override public function draw():Void
	{
		for (camera in getCamerasLegacy())
		{
			if (!camera.visible || !camera.exists)
			{
				continue;
			}

			_matrix.identity();
			_matrix.scale(camera.viewWidth, camera.viewHeight);
			_matrix.translate(camera.viewMarginLeft, camera.viewMarginTop);
			camera.drawPixels(frame, _matrix, colorTransform);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}
}
