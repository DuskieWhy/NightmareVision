package;

import flixel.FlxState;

import funkin.FunkinAssets;
import funkin.states.TitleState;
import funkin.video.FunkinVideoSprite;

using StringTools;

@:access(flixel.FlxGame)
@:access(Main)
class Splash extends FlxState
{
	var _cachedAutoPause:Bool;
	
	var spriteEvents:FlxTimer;
	var logo:FlxSprite;
	
	override function create()
	{
		_cachedAutoPause = FlxG.autoPause;
		FlxG.autoPause = false;
		
		FlxTimer.wait(1, () -> {
			#if VIDEOS_ALLOWED
			var video = new FunkinVideoSprite();
			add(video);
			video.onFormat(() -> {
				video.setGraphicSize(0, FlxG.height);
				video.updateHitbox();
				video.screenCenter();
			});
			video.onEnd(finish);
			if (video.load(Paths.video('intro'))) video.delayAndStart();
			else
			#end logoFunc();
		});
	}
	
	override function update(elapsed:Float)
	{
		if (logo != null)
		{
			logo.updateHitbox();
			logo.screenCenter();
			
			if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER)
			{
				finish();
			}
		}
		
		super.update(elapsed);
	}
	
	function logoFunc()
	{
		var folder = FileSystem.readDirectory('assets/images/branding');
		var img = folder[FlxG.random.int(0, folder.length - 1)];
		trace(folder);
		
		logo = new FlxSprite().loadGraphic(Paths.image('branding/${img.replace('.png', '')}'));
		logo.screenCenter();
		logo.visible = false;
		add(logo);
		
		spriteEvents = new FlxTimer().start(1, (stupidFuckingTimer:FlxTimer) -> {
			var step = 0;
			new FlxTimer().start(0.25, (t:FlxTimer) -> {
				switch (step++)
				{
					case 0:
						FlxG.sound.volume = 1;
						FlxG.sound.play(Paths.sound('intro'));
						logo.visible = true;
						logo.scale.set(0.2, 1.25);
						t.reset(0.06125);
					case 1:
						logo.scale.set(1.25, 0.5);
						t.reset(0.06125);
					case 2:
						logo.scale.set(1.125, 1.125);
						FlxTween.tween(logo.scale, {x: 1, y: 1}, 0.25, {ease: FlxEase.elasticOut});
						t.reset(1.25);
					case 3:
						FlxTween.tween(logo.scale, {x: 0.2, y: 0.2}, 1.5, {ease: FlxEase.quadIn});
						FlxTween.tween(logo, {alpha: 0}, 1.5,
							{
								ease: FlxEase.quadIn,
								onComplete: (t:FlxTween) -> {
									FlxTimer.wait(0.8, finish);
								}
							});
				}
			});
		});
	}
	
	function finish()
	{
		if (spriteEvents != null)
		{
			spriteEvents.cancel();
			spriteEvents.destroy();
		}
		complete();
	}
	
	function complete()
	{
		FlxG.autoPause = _cachedAutoPause;
		FlxG.switchState(TitleState.new);
	}
}
