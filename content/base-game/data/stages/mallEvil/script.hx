function onLoad()
{
	var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
	bg.setGraphicSize(Std.int(bg.width * 0.8));
	bg.updateHitbox();
	add(bg);
	
	var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
	add(evilTree);
	
	var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -250, 700);
	add(evilSnow);
}

var allowCountdown:Bool = false;

function onStartCountdown()
{
	if (!allowCountdown)
	{
		FlxG.camera.fade(FlxColor.BLACK, 0.000001);
		camHUD.alpha = 0.0001;
		inCutscene = true;
		
		new FlxTimer().start(0.05, function(tmr:FlxTimer) FlxG.camera.fade(FlxColor.BLACK, 0.7, true));
		FlxG.sound.play(Paths.sound('Lights_Turn_On'));
		snapCamToPos(400, -2050);
		FlxG.camera.zoom = 1.5;
		
		new FlxTimer().start(0.8, function(tmr:FlxTimer) {
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5,
				{
					ease: FlxEase.quadInOut,
					onComplete: function(twn:FlxTween) {
						FlxTween.tween(camHUD, {alpha: 1}, 0.7);
						allowCountdown = true;
						inCutscene = false;
						startCountdown();
					}
				});
		});
		return Function_Stop;
	}
}
