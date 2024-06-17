var halloweenWhite:BGSprite;
function onLoad(){
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
    // halloweenWhite.blend = ADD;
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