package;

import flixel.FlxState;

import funkin.FunkinAssets;
import funkin.states.TitleState;
#if VIDEOS_ALLOWED
import funkin.video.FunkinVideoSprite;
#end

using StringTools;

@:access(flixel.FlxGame)
class Splash extends FlxState
{
	var _cachedAutoPause:Bool;
	
	var spriteEvents:FlxTimer;
	var logo:FlxSprite;
	
	#if VIDEOS_ALLOWED
	var video:FunkinVideoSprite;
	#end
	
	override function create()
	{
		_cachedAutoPause = FlxG.autoPause;
		FlxG.autoPause = false;
		
		FlxTimer.wait(1, () -> {
			#if VIDEOS_ALLOWED
			video = new FunkinVideoSprite();
			add(video);
			video.onFormat(() -> {
				video.setGraphicSize(0, FlxG.height);
				video.updateHitbox();
				video.screenCenter();
			});
			video.onEnd(finish);
			if (video.load(Paths.video('intro'))) video.delayAndStart();
			else
			#end
			
			logoFunc();
		});
	}
	
	override function update(elapsed:Float)
	{
		if (logo != null)
		{
			logo.updateHitbox();
			logo.screenCenter();
		}
		
		if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER)
		{
			finish();
		}
		super.update(elapsed);
	}
	
	function logoFunc()
	{
		var files = Paths.listAllFilesInDirectory('images/branding/watermarks');
		
		if (files.length == 0)
		{
			finish();
			return;
		}
		
		files = files.filter(str -> !FileSystem.isDirectory('assets/images/branding/watermarks/$str'));
		
		final imgPath:String = Path.withoutDirectory(Path.withoutExtension(FlxG.random.getObject(files)));
		
		trace(files);
		
		logo = new FlxSprite().loadGraphic(Paths.image('branding/watermarks/$imgPath'));
		logo.screenCenter();
		logo.visible = false;
		add(logo);
		
		final logoScale:Float = Math.min(FlxG.width / logo.width, FlxG.height / logo.height) * 0.8;
		
		logo.scale.set(logoScale, logoScale);
		
		logo.antialiasing = !imgPath.endsWith('-pixel');
		
		spriteEvents = new FlxTimer().start(1, (tmr:FlxTimer) -> {
			var step = 0;
			new FlxTimer().start(0.25, (t:FlxTimer) -> {
				switch (step++)
				{
					case 0:
						FlxG.sound.volume = 1;
						FlxG.sound.play(Paths.sound('intro'));
						logo.visible = true;
						logo.scale.set(0.2 * logoScale, 1.25 * logoScale);
						t.reset(0.06125);
					case 1:
						logo.scale.set(1.25 * logoScale, 0.5 * logoScale);
						t.reset(0.06125);
					case 2:
						logo.scale.set(1.125 * logoScale, 1.125 * logoScale);
						FlxTween.tween(logo.scale, {x: 1 * logoScale, y: 1 * logoScale}, 0.25, {ease: FlxEase.elasticOut});
						t.reset(1.25);
					case 3:
						FlxTween.tween(logo.scale, {x: 0.2 * logoScale, y: 0.2 * logoScale}, 1.5, {ease: FlxEase.quadIn});
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
		#if VIDEOS_ALLOWED
		video.stop();
		video.destroy();
		#end
		complete();
	}
	
	function complete()
	{
		FlxG.sound.muted = FlxG.save.data.mute;
		FlxG.sound.volume = FlxG.save.data.volume;
		
		FlxG.autoPause = _cachedAutoPause;
		FlxG.switchState(() -> Type.createInstance(Main.startMeta.initialState, []));
	}
}
