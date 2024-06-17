function onLoad(){
    var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
    bg.setGraphicSize(Std.int(bg.width * 0.8));
    bg.updateHitbox();
    add(bg);

    var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
    add(evilTree);

    var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
    add(evilSnow);
}

var allowCountdown:Bool = false;
function onStartCountdown(){
    if(!allowCountdown){
        var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
        add(blackScreen);
        blackScreen.scrollFactor.set();
        game.camHUD.visible = false;
        game.inCutscene = true;

        FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
            ease: FlxEase.linear,
            onComplete: function(twn:FlxTween) {
                remove(blackScreen);
            }
        });
        FlxG.sound.play(Paths.sound('Lights_Turn_On'));
        game.snapCamFollowToPos(400, -2050);
        FlxG.camera.focusOn(game.camFollow);
        FlxG.camera.zoom = 1.5;

        new FlxTimer().start(0.8, function(tmr:FlxTimer)
        {
            game.camHUD.visible = true;
            remove(blackScreen);
            FlxTween.tween(FlxG.camera, {zoom: game.defaultCamZoom}, 2.5, {
                ease: FlxEase.quadInOut,
                onComplete: function(twn:FlxTween)
                {
                    allowCountdown = true;
                    game.inCutscene = false;
                    game.startCountdown();
                }
            });
        });
        return Function_Stop;
    }

}