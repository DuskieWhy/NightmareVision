package;

import flixel.FlxState;

import funkin.FunkinAssets;
import funkin.states.TitleState;
#if VIDEOS_ALLOWED
import funkin.video.FunkinVideoSprite;
#end
#if MODS_ALLOWED
import funkin.Mods;
#end

using StringTools;

@:access(flixel.FlxGame)
class Splash extends FlxState
{
	var _cachedAutoPause:Bool;
	#if MODS_ALLOWED
	var noMods:Bool = false;
	#end
	
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
			
			if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER)
			{
				finish();
			}
		}
		#if VIDEOS_ALLOWED
		if (video != null)
		{
			if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER)
			{
				finish();
			}
		}
		#end
		super.update(elapsed);
	}
	
	function logoFunc()
	{
		var folder:Array<String> = [];
		#if MODS_ALLOWED
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0 || !noMods)
		{
			if (!FileSystem.isDirectory('content/${Mods.currentModDirectory}/images/branding/watermarks') || (folder = FileSystem.readDirectory('content/${Mods.currentModDirectory}/images/branding/watermarks'))
				.length == 0)
			{
				noMods = true;
			}
		}
		if (Mods.currentModDirectory == null && Mods.currentModDirectory.length == 0 || noMods)
		{
			if (!FileSystem.isDirectory('assets/images/branding/watermarks') || (folder = FileSystem.readDirectory('assets/images/branding/watermarks')).length == 0)
			{
				finish();
				return;
			}
		}
		
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0) folder = folder.filter(str ->
			!FileSystem.isDirectory('content/${Mods.currentModDirectory}/images/branding/watermarks/$str'));
			
		if (Mods.currentModDirectory == null && Mods.currentModDirectory.length == 0) folder = folder.filter(str -> !FileSystem.isDirectory('assets/images/branding/watermarks/$str'));
		#else
		if (!FileSystem.isDirectory('assets/images/branding/watermarks') || (folder = FileSystem.readDirectory('assets/images/branding/watermarks')).length == 0)
		{
			finish();
			return;
		}
		
		folder = folder.filter(str -> !FileSystem.isDirectory('assets/images/branding/watermarks/$str'));
		#end
		
		var img = FlxG.random.getObject(folder);
		trace(folder);
		
		logo = new FlxSprite().loadGraphic(Paths.image('branding/watermarks/${Path.withoutExtension(img)}'));
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
