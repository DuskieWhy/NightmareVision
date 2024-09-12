
import funkin.objects.BGSprite;
import funkin.states.transitions.FixedFlxBGSprite;

var halloweenWhite:BGSprite;
function onLoad()
{
    if(!ClientPrefs.lowQuality) {
        halloweenBG = new BGSprite('week2/halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
    } else {
        halloweenBG = new BGSprite('week2/halloween_bg_low', -200, -100);
    }
    halloweenBG.scrollFactor.set(1,1);
    add(halloweenBG);

    halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
    halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
    halloweenWhite.alpha = 0;
    halloweenWhite.blend = BlendMode.ADD;
    foreground.add(halloweenWhite);
}

var lightningStrikeBeat:Int = 0;
var lightningOffset:Int = 8;

function onBeatHit(){
    if(FlxG.random.bool(10) && game.curBeat > lightningStrikeBeat + lightningOffset)
         lightningStrikeShit();
}

function lightningStrikeShit(){
    FlxG.sound.play(Paths.sound("thunder_" + FlxG.random.int(1,2)));
    if(!ClientPrefs.lowQuality) halloweenBG.animation.play("halloweem bg0");

    // lightningStrikeBeat = game.curBeat;
    // lightningOffset = FlxG.random.int(8, 16);

    if(game.boyfriend.animOffsets.exists('scared')){
        game.boyfriend.playAnim('scared', true);
    }
    if(game.gf.animOffsets.exists('scared')){
        game.gf.playAnim('scared', true);
    }

    if(ClientPrefs.flashing) {
        halloweenWhite.alpha = 0.4;
        FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
        FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
    }
}

function doStartCountdown()
{
    if (game.curSong == 'Monster' && PlayState.isStoryMode && !PlayState.seenCutscene)
    {
        var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeScaledGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
        foreground.add(whiteScreen);
        whiteScreen.scrollFactor.set();
        whiteScreen.blend = BlendMode.ADD;
        game.camHUD.visible = false;
        game.snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
        game.inCutscene = true;
    
        FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
            startDelay: 0.1,
            ease: FlxEase.linear,
            onComplete: function(twn:FlxTween)
            {
                camHUD.visible = true;
                remove(whiteScreen);
                game.startCountdown();
            }
        });
        FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
        if (gf != null)
            gf.playAnim('scared', true);
        boyfriend.playAnim('scared', true);


        return Globals.Function_Stop;
    }




}