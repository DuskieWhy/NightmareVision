import funkin.objects.BGSprite;

var lightningStrikeBeat:Int = 0;
var lightningOffset:Int = 8;

function onBeatHit()
{
	if (FlxG.random.bool(5) && curBeat > (lightningStrikeBeat + lightningOffset)) lightningStrikeShit();
}

function lightningStrikeShit()
{
	FlxG.sound.play(Paths.sound("thunder_" + FlxG.random.int(1, 2)));
	if (!ClientPrefs.lowQuality) bg.playAnim('lightning');
	
	lightningStrikeBeat = curBeat;
	lightningOffset = FlxG.random.int(8, 24);
	
	for (i in [boyfriend, gf])
	{
		if (i.animOffsets.exists('scared'))
		{
			i.playAnim('scared', true);
			i.specialAnim = true;
			FlxTimer.wait(2, () -> {
				i.playAnim('idle', true);
			});
		}
	}
	
	if (ClientPrefs.flashing)
	{
		whiteFlash.alpha = 0.4;
		FlxTween.tween(whiteFlash, {alpha: 0.5}, 0.075);
		FlxTween.tween(whiteFlash, {alpha: 0}, 0.25, {startDelay: 0.15});
	}
}

var seen = false;

function onStartCountdown()
{
	if (PlayState.SONG.song.toLowerCase() == 'monster' && !seen)
	{
		seen = true;
		var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeScaledGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
		add(whiteScreen);
		whiteScreen.zIndex = 2;
		whiteScreen.scrollFactor.set();
		whiteScreen.blend = BlendMode.ADD;
		camHUD.visible = false;
		snapCamToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
		inCutscene = true;
		
		FlxTween.tween(whiteScreen, {alpha: 0}, 1,
			{
				startDelay: 0.1,
				ease: FlxEase.linear,
				onComplete: function(twn:FlxTween) {
					camHUD.visible = true;
					remove(whiteScreen);
					startCountdown();
				}
			});
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if (gf != null) gf.playAnim('scared', true);
		boyfriend.playAnim('scared', true);
		
		return ScriptConstants.Function_Stop;
	}
}
