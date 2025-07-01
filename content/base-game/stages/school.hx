function onLoad(){
    GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
    GameOverSubstate.loopSoundName = 'gameOver-pixel';
    GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
    GameOverSubstate.characterName = 'bf-pixel-dead';

    var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
    add(bgSky);
    bgSky.antialiasing = false;

    var repositionShit = -200;

    var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
    add(bgSchool);
    bgSchool.antialiasing = false;

    var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
    add(bgStreet);
    bgStreet.antialiasing = false;

    var widShit = Std.int(bgSky.width * 6);
    if(!ClientPrefs.lowQuality) {
        var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
        fgTrees.setGraphicSize(Std.int(widShit * 0.8));
        fgTrees.updateHitbox();
        add(fgTrees);
        fgTrees.antialiasing = false;
    }

    var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
    bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
    bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
    bgTrees.animation.play('treeLoop');
    bgTrees.scrollFactor.set(0.85, 0.85);
    add(bgTrees);
    bgTrees.antialiasing = false;

    if(!ClientPrefs.lowQuality) {
        var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
        treeLeaves.setGraphicSize(widShit);
        treeLeaves.updateHitbox();
        add(treeLeaves);
        treeLeaves.antialiasing = false;
    }

    bgSky.setGraphicSize(widShit);
    bgSchool.setGraphicSize(widShit);
    bgStreet.setGraphicSize(widShit);
    bgTrees.setGraphicSize(Std.int(widShit * 1.4));

    bgSky.updateHitbox();
    bgSchool.updateHitbox();
    bgStreet.updateHitbox();
    bgTrees.updateHitbox();

    if(!ClientPrefs.lowQuality) {
        bgGirls = new BackgroundGirls(-100, 190);
        bgGirls.scrollFactor.set(0.9, 0.9);

        // bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
        bgGirls.scale.set(6,6);
        bgGirls.updateHitbox();
        add(bgGirls);
    }
}

function onCreatePost(){
    playHUD.ratingPrefix = 'pixelUI/';
	playHUD.ratingSuffix = '-pixel';
}


function onEvent(eventName, value1, value2){ 
    if(eventName == 'BG Freaks Expression') bgGirls.swapDanceType();
}

function onCountdownTick(){
    if(!ClientPrefs.lowQuality) {
        bgGirls.dance();
    }
}

function onBeatHit(){
    if(!ClientPrefs.lowQuality) {
        bgGirls.dance();
    }
}

var a = false;
function onStartCountdown() {
    if(!a && PlayState.isStoryMode){
        a = true;
        if (Paths.formatToSongPath(PlayState.SONG.song) == 'roses')
            FlxG.sound.play(Paths.sound('ANGRY'));
    
        schoolIntro(doof);
    
        return Function_Stop;
    }
}

function schoolIntro(dialogueBox) {
    inCutscene = true;

    snapCamToPos(600, 550);

    var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
    black.scrollFactor.set();
    black.cameras = [ camHUD ];
    add(black);

    var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
    red.cameras = [ camOther ];
    red.scrollFactor.set();

    var senpaiEvil:FlxSprite = new FlxSprite();
    senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
    senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
    senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
    senpaiEvil.scrollFactor.set();
    senpaiEvil.updateHitbox();
    senpaiEvil.screenCenter();
    senpaiEvil.cameras = [ camOther ];
    senpaiEvil.x += 300;

    var songName:String = Paths.formatToSongPath(PlayState.SONG.song);
    if (songName == 'roses' || songName == 'thorns')
    {
        remove(black);

        if (songName == 'thorns')
        {
            add(red);
            camHUD.visible = false;
        }
    }

    new FlxTimer().start(0.3, function(tmr:FlxTimer)
    {
        black.alpha -= 0.15;

        if (black.alpha > 0)
        {
            tmr.reset(0.3);
        }
        else
        {
            if (dialogueBox != null)
            {
                if (Paths.formatToSongPath(PlayState.SONG.song) == 'thorns')
                {
                    add(senpaiEvil);
                    senpaiEvil.alpha = 0;
                    new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
                    {
                        senpaiEvil.alpha += 0.15;
                        if (senpaiEvil.alpha < 1)
                        {
                            swagTimer.reset();
                        }
                        else
                        {
                            senpaiEvil.animation.play('idle');
                            FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
                            {
                                // Just incase...
                                senpaiEvil.alpha = 0.001;
                                red.alpha = 0.001;

                                remove(senpaiEvil);
                                remove(red);
                                camOther.fade(FlxColor.WHITE, 0.01, true, function()
                                {
                                    add(dialogueBox);
                                    camHUD.visible = true;
                                }, true);
                            });
                            new FlxTimer().start(3.2, function(deadTime:FlxTimer)
                            {
                                camOther.fade(FlxColor.WHITE, 1.6, false);
                            });
                        }
                    });
                }
                else
                {
                    add(dialogueBox);
                }
            }
            else
                startCountdown();

            remove(black);
        }
    });
}