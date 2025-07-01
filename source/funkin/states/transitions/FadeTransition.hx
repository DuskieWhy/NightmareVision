package funkin.states.transitions;

import flixel.system.FlxBGSprite;

import funkin.utils.CameraUtil;
import funkin.backend.BaseTransitionState;

// simple fade transition between states
class FadeTransition extends BaseTransitionState
{
	var sprite:FlxBGSprite;
	
	override function create()
	{
		cameras = [CameraUtil.lastCamera];
		
		sprite = new FlxBGSprite();
		sprite.color = FlxColor.BLACK;
		add(sprite);
		
		sprite.alpha = status == IN ? 0 : 1;
		final desiredAlpha = status == IN ? 1 : 0;
		final time = status == IN ? 0.48 : 0.8;
		
		FlxTween.tween(sprite, {alpha: desiredAlpha}, time, {onComplete: Void -> dispatchFinish()});
		
		super.create();
	}
}
