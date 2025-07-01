import funkin.objects.BGSprite;
import funkin.states.substates.GameOverSubstate;
import funkin.objects.stageobjects.TankmenBG;

var tankWatchtower:BGSprite;
var tankGround:BGSprite;
var tankmanRun:FlxTypedGroup;
var foregroundSprites:FlxTypedGroup;
var chart:SONG.SwagSong = null;
var picoAnims:Array<CrowdAnim> = [];
var anims:Array<String> = ['shoot1', 'shoot2', 'shoot3', 'shoot4'];

var boppers:Array<FlxSprite> = [];

typedef CrowdAnim = {
	var time:Float;
	var data:Int;
	var length:Int;
}

function onLoad(){
    var sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
    add(sky);

    if(!ClientPrefs.lowQuality)
    {
        var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
        clouds.active = true;
        clouds.velocity.x = FlxG.random.float(5, 15);
        add(clouds);

        var mountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
        mountains.setGraphicSize(Std.int(1.2 * mountains.width));
        mountains.updateHitbox();
        add(mountains);

        var buildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.3, 0.3);
        buildings.setGraphicSize(Std.int(1.1 * buildings.width));
        buildings.updateHitbox();
        add(buildings);
    }

    var ruins:BGSprite = new BGSprite('tankRuins',-200,0,.35,.35);
    ruins.setGraphicSize(Std.int(1.1 * ruins.width));
    ruins.updateHitbox();
    add(ruins);

    if(!ClientPrefs.lowQuality)
    {
        var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
        add(smokeLeft);
        var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
        add(smokeRight);

        tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
        add(tankWatchtower);
    }

    tankGround = new BGSprite('tankRolling', 300, 300, 0.5, 0.5,['BG tank w lighting'], true);
    add(tankGround);

    tankmanRun = new FlxTypedGroup();
    add(tankmanRun);

    var ground:BGSprite = new BGSprite('tankGround', -420, -150);
    ground.setGraphicSize(Std.int(1.15 * ground.width));
    ground.updateHitbox();
    add(ground);
    moveTank();

    var tank0 = new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']);
    tank0.zIndex = 999;
    add(tank0);

    var tank2 = new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']);
    tank2.zIndex = 999;
    add(tank2);

    var tank4 = new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']);
    tank4.zIndex = 999;
    add(tank4);

    boppers = [tank0,tank2,tank4];

    if (!ClientPrefs.lowQuality)
    {
        var tank1 = new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']);
        tank1.zIndex = 999;
        add(tank1);
        boppers.push(tank1);

        var tank3 = new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']);
        tank3.zIndex = 999;
        add(tank3);
        boppers.push(tank3);

        var tank5 = new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']);
        tank5.zIndex = 999;
        add(tank5);
        boppers.push(tank5);
    }


    // foreground.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
    // if(!ClientPrefs.lowQuality) foreground.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
    // foreground.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
    // if(!ClientPrefs.lowQuality) foreground.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
    // foreground.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
    // if(!ClientPrefs.lowQuality) foreground.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));
    GameOverSubstate.resetVariables();
}

function onCreatePost(){
    if(curSong.toLowerCase() == 'stress') {
        GameOverSubstate.characterName = 'bf-holding-gf-dead';


        gf.skipDance = true;
        chart = Song.loadFromJson('picospeaker', 'stress', true);
        if(chart!=null){ 
            for(section in chart.notes){
                for(note in section.sectionNotes){
                    picoAnims.push({
                        time: note[0],
                        data: Math.floor(note[1]%4),
                        length: note[2]
                    });
                }
            }
        }
        TankmenBG.animationNotes = chart.notes;
        
        gf.playAnim("shoot1");

        if(!ClientPrefs.lowQuality)
        {
            var firstTank:TankmenBG = new TankmenBG(20, 500, true);
            firstTank.resetShit(20, 600, true);
            firstTank.strumTime = 10;
            tankmanRun.add(firstTank);

            for (i in 0...picoAnims.length)
            {
                if(FlxG.random.bool(16)) {
                    var tankBih = tankmanRun.recycle(TankmenBG);
                    tankBih.strumTime = picoAnims[i].time;
                    tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), picoAnims[i].data < 2);
                    tankmanRun.add(tankBih);
                }
            }
        }
    }
}

function onUpdate(elapsed){
    moveTank(elapsed);
    updatePicoChart();
}

function updatePicoChart(){
    for(anim in picoAnims){
        if(anim.time <= Conductor.songPosition){
            var animToPlay:String = anims[anim.data];
            gf.holdTimer = 0;
            gf.playAnim(animToPlay, true);
            var holdingTime = Conductor.songPosition - anim.time;
            if(anim.length == 0 || anim.length < holdingTime)
                picoAnims.remove(anim);
        }
    }
}

var tankX:Float = 400;
var tankSpeed:Float = FlxG.random.float(5, 7);
var tankAngle:Float = FlxG.random.int(-90, 45);

function moveTank(?elapsed:Float = 0)
{
    if(!inCutscene)
    {
        tankAngle += elapsed * tankSpeed;
        tankGround.angle = tankAngle - 90 + 15;
        tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
        tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
        // trace('hi!');
    }
}

function onBeatHit()
{
    tankWatchtower.dance();

    for (i in boppers)
    {
        if(i != null) i.dance();
    }
}

function deathAnimStart(volume){
    GameOverSubstate.instance.playingDeathSound = true;
}

function deathAnimStartPost(volume){
    FlxG.sound.music.volume = 0.2;
    var exclude:Array<Int> = [];
    //if(!ClientPrefs.cursing) exclude = [1, 3, 8, 13, 17, 21];

    FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, exclude)), 1, false, null, true, function() {
        if(!GameOverSubstate.instance.isEnding)
        {
            FlxG.sound.music.fadeIn(0.2, 1, 6);
        }
    });
}

var allowCountdown:Bool = !PlayState.isStoryMode;
function onStartCountdown(){
    if(!allowCountdown){
        tankIntro();
        return Function_Stop;
    }
}

function tankIntro(){

    var songName:String = curSong.toLowerCase();
    dadGroup.alpha = 0.00001;
    camHUD.visible = false;
    snapCamToPos(dad.x + 280, dad.y + 170, true);

    switch(songName){
        case 'ugh':
            var tankman = new AnimateSprite(415, 565, Paths.textureAtlas('cutscenes/Ugh'));
            tankman.anim.addBySymbol('Well', 'TANK TALK 1 P1', 0, 0, 24);
            tankman.anim.addBySymbol('Kill', 'TANK TALK 1 P2', 0, 0, 24);
            tankman.antialiasing = true;
            add(tankman);
            tankman.anim.play('Well');
            // tankman.anim.pause();

            // FlxG.sound.play(Paths.music('DISTORTO'));
            FlxG.sound.playMusic(Paths.music('DISTORTO'));
            FlxG.sound.play(Paths.sound('wellWellWell'));

            FlxG.camera.zoom *= 1.2;

            FlxTimer.wait(3, ()->{
                isCameraOnForcedPos = true;
                camFollow.x += 550;
                camFollow.y += 50;
            });

            FlxTimer.wait(4.5, ()->{
                boyfriend.playAnim('singUP', true);
                boyfriend.specialAnim = true;
                FlxG.sound.play(Paths.sound('bfBeep'));
            });

            FlxTimer.wait(6, ()->{
                camFollow.x -= 550;
                camFollow.y -= 50;

                tankman.anim.play('Kill');
                FlxG.sound.play(Paths.sound('killYou'));
            });

            FlxTimer.wait(12, ()->{ 
                tankman.visible = false;
                tankman.destroy();
                endScene();
            });
        case 'guns':
            var tankman = new AnimateSprite(415, 565, Paths.textureAtlas('cutscenes/Guns'));
            tankman.anim.addBySymbol('tight', 'TANK TALK 2', 0, 0, 24);
            tankman.antialiasing = true;
            add(tankman);

            tankman.anim.play('tight');
            FlxG.sound.play(Paths.sound('tankSong2'));
            FlxG.sound.playMusic(Paths.music('DISTORTO'));

            FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
            FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
            FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});

            FlxTimer.wait(4, ()->{
                gf.playAnim('sad', true);
                gf.animation.finishCallback = function(name:String)
                {
                    gf.playAnim('sad', true);
                };
            });

            tankman.anim.onComplete.add(()->{ 
                tankman.visible = false;
                tankman.destroy();
                endScene();
            });
        case 'stress':
            gfGroup.alpha = 0.00001;
            boyfriendGroup.alpha = 0.00001;

            var tankman = new AnimateSprite(415, 565, Paths.textureAtlas('cutscenes/Stress'));
            tankman.anim.addBySymbol('FUCK', 'TANK TALK 3 P1 UNCUT', 0, 0, 24);
            tankman.anim.addBySymbol('pico', 'TANK TALK 3 P2 UNCUT', 0, 0, 24);
            tankman.antialiasing = true;        
            stage.add(tankman);

            var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
            gfDance.antialiasing = ClientPrefs.globalAntialiasing;

            var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
            gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;

            if (!ClientPrefs.lowQuality)
            {
                gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
                gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
                gfDance.animation.play('dance', true);
                stage.add(gfDance);
            }

            gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
            gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
            gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
            gfCutscene.animation.play('dieBitch', true);
            gfCutscene.animation.pause();
            gfCutscene.alpha = 0;
            stage.add(gfCutscene);

            picoCutscene = new AnimateSprite(gf.x - 849, gf.y - 264, Paths.textureAtlas('cutscenes/stressPico'));
            picoCutscene.anim.addBySymbol('anim', 'Pico Badass', 0, 0, 24);
            picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
            picoCutscene.alpha = 0;
            stage.add(picoCutscene);

            var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
            boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;
            boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
            boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
            boyfriendCutscene.animation.play('idle', true);
            boyfriendCutscene.animation.curAnim.finish();
            stage.add(boyfriendCutscene);

            gfDance.zIndex = 1;
            gfCutscene.zIndex = 2;
            picoCutscene.zIndex = 3;
            boyfriendCutscene.zIndex = 5;
            gfGroup.zIndex = 6;
            tankman.zIndex = 7;
            dadGroup.zIndex = 8;
            boyfriendGroup.zIndex = 9;
            refreshZ();

            var stressScene = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
            FlxG.sound.list.add(stressScene);

            FlxG.sound.playMusic(Paths.music('klaskii-romper'), 0.2);
            FlxG.sound.music.fadeIn(2, 0.0125, 0.1);


            FlxTimer.wait(0.1, ()->{
                stressScene.play();
                tankman.anim.play('FUCK');
            });
            snapCamToPos(dad.x + 400, dad.y + 170);
            FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});

            FlxTimer.wait(15.2, ()->{
                FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
                FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});
                gfDance.visible = false;
                gfCutscene.alpha = 1;
                gfCutscene.animation.play('dieBitch', true);
                gfCutscene.animation.finishCallback = function(name:String)
                {
                    if(name == 'dieBitch') //Next part
                    {
                        gfCutscene.animation.play('getRektLmao', true);
                        gfCutscene.offset.set(224, 445);
                    }
                    else
                    {
                        gfCutscene.visible = false;
                        picoCutscene.alpha = 1;
                        picoCutscene.anim.play('anim');

                        boyfriendGroup.alpha = 1;
                        boyfriendCutscene.visible = false;
                        boyfriend.playAnim('bfCatch', true);
                        boyfriend.animation.finishCallback = function(name:String)
                        {
                            if(name != 'idle')
                            {
                                boyfriend.playAnim('idle', true);
                                boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
                            }
                        };

                        picoCutscene.anim.onComplete.add(()->{
                            picoCutscene.visible = false;
                            gfGroup.alpha = 1;
                        });
                        gfCutscene.animation.finishCallback = null;
                    }
                }
            });

            FlxTimer.wait(17.5, zoomBack);
            FlxTimer.wait(19.5, ()->{ tankman.anim.play('pico', true); });
            FlxTimer.wait(20, ()->{ camFollow.setPosition(dad.x + 500, dad.y + 170); });
            FlxTimer.wait(31.2, ()->{
                boyfriend.playAnim('singUPmiss', true);
                boyfriend.animation.finishCallback = function(name:String)
                {
                    if (name == 'singUPmiss')
                    {
                        boyfriend.playAnim('idle', true);
                        boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
                    }
                };

                camFollow.setPosition(boyfriend.x + 280, boyfriend.y + 200);
                cameraSpeed = 12;
                FlxTween.tween(FlxG.camera, {zoom: 2}, 0.25, {ease: FlxEase.elasticOut});
            });
            FlxTimer.wait(32.2, ()->{
                snapCamToPos(630, 425);
                FlxG.camera.zoom = 0.8;
            });

            FlxTimer.wait(35, ()->{
                for(i in [tankman, gfDance, gfCutscene, boyfriendCutscene]){
                    i.visible = false;
                    i.destroy();
                }
                endScene();
            });
    }
}


function endScene(){
    isCameraOnForcedPos = false;
    camZooming = true;
    dadGroup.alpha = 1;
    FlxG.sound.music.stop();
    camHUD.visible = true;
    allowCountdown = true;
    cameraSpeed = 1;
    startCountdown();
}

var calledTimes:Int = 0;
function zoomBack(){        
    var camPosX:Float = 630;
    var camPosY:Float = 425;
    camFollow.setPosition(camPosX, camPosY);
    FlxG.camera.zoom = 0.8;
    cameraSpeed = 1;

    calledTimes += 1;
}