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

    foreground.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
    if(!ClientPrefs.lowQuality) foreground.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
    foreground.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
    if(!ClientPrefs.lowQuality) foreground.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
    foreground.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
    if(!ClientPrefs.lowQuality) foreground.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));
    GameOverSubstate.resetVariables();
}

function onCreatePost(){
    if(game.curSong.toLowerCase() == 'stress') {
        GameOverSubstate.characterName = 'bf-holding-gf-dead';


        game.gf.skipDance = true;
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
        
        game.gf.playAnim("shoot1");

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
    if(!game.inCutscene)
    {
        tankAngle += elapsed * tankSpeed;
        tankGround.angle = tankAngle - 90 + 15;
        tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
        tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
        // trace('hi!');
    }
}

function onBeatHit(){
    tankWatchtower.dance();
    for(obj in foreground){ if(obj != null) obj.dance(); }
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

// var allowCountdown:Bool = false;
// function onStartCountdown(){
//     if(!allowCountdown){
//         tankIntro();
//         return Function_Stop;
//     }
// }

// function tankIntro(){
//     var cutsceneHandler:CutsceneHandler = new CutsceneHandler();

//     var songName:String = game.curSong.toLowerCase();
//     trace(songName);
//     game.dadGroup.alpha = 0.00001;
//     game.camHUD.visible = false;
//     //inCutscene = true; //this would stop the camera movement, oops

//     var tankman:FlxSprite = new FlxSprite(-20, 320);
//     tankman.frames = Paths.getSparrowAtlas('cutscenes/stress');
//     tankman.antialiasing = ClientPrefs.globalAntialiasing;
//     addBehindDad(tankman);
//     cutsceneHandler.push(tankman);

    // var tankman2:FlxSprite = new FlxSprite(16, 312);
    // tankman2.antialiasing = ClientPrefs.globalAntialiasing;
    // tankman2.alpha = 0.000001;
    // cutsceneHandler.push(tankman2);
    // var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
    // gfDance.antialiasing = ClientPrefs.globalAntialiasing;
    // cutsceneHandler.push(gfDance);
    // var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
    // gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;
    // cutsceneHandler.push(gfCutscene);
    // var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
    // picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
    // cutsceneHandler.push(picoCutscene);
    // var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
    // boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;
    // cutsceneHandler.push(boyfriendCutscene);

    // cutsceneHandler.finishCallback = function(){
    //     trace('no');
    // }

    // cutsceneHandler.finishCallback = function()
    // {
    //     var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
    //     FlxG.sound.music.fadeOut(timeForStuff);
    //     FlxTween.tween(FlxG.camera, {zoom: game.defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
    //     game.moveCamera(true);
    //     game.startCountdown();

    //     game.dadGroup.alpha = 1;
    //     game.camHUD.visible = true;
    //     game.boyfriend.animation.finishCallback = null;
    //     game.gf.animation.finishCallback = null;
    //     game.gf.dance();
    // };

    // game.camFollow.set(dad.x + 280, dad.y + 170);
    // switch(songName)
    // {
    //     case 'ugh':
    //         cutsceneHandler.endTime = 12;
    //         cutsceneHandler.music = 'DISTORTO';
    //         game.precacheList.set('wellWellWell', 'sound');
    //         game.precacheList.set('killYou', 'sound');
    //         game.precacheList.set('bfBeep', 'sound');

    //         var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell'));
    //         FlxG.sound.list.add(wellWellWell);

    //         tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
    //         tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
    //         tankman.animation.play('wellWell', true);
    //         FlxG.camera.zoom *= 1.2;

    //         // Well well well, what do we got here?
    //         cutsceneHandler.timer(0.1, function()
    //         {
    //             wellWellWell.play(true);
    //         });

    //         // Move camera to BF
    //         cutsceneHandler.timer(3, function()
    //         {
    //             game.camFollow.x += 750;
    //             game.camFollow.y += 100;
    //         });

    //         // Beep!
    //         cutsceneHandler.timer(4.5, function()
    //         {
    //             game.boyfriend.playAnim('singUP', true);
    //             game.boyfriend.specialAnim = true;
    //             FlxG.sound.play(Paths.sound('bfBeep'));
    //         });

    //         // Move camera to Tankman
    //         cutsceneHandler.timer(6, function()
    //         {
    //             game.camFollow.x -= 750;
    //             game.camFollow.y -= 100;

    //             // We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
    //             tankman.animation.play('killYou', true);
    //             FlxG.sound.play(Paths.sound('killYou'));
    //         });

        // case 'guns':
        //     cutsceneHandler.endTime = 11.5;
        //     cutsceneHandler.music = 'DISTORTO';
        //     tankman.x += 40;
        //     tankman.y += 10;
        //     precacheList.set('tankSong2', 'sound');

        //     var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2'));
        //     FlxG.sound.list.add(tightBars);

        //     tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
        //     tankman.animation.play('tightBars', true);
        //     game.boyfriend.animation.curAnim.finish();

        //     cutsceneHandler.onStart = function()
        //     {
        //         tightBars.play(true);
        //         FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
        //         FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
        //         FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
        //     };

        //     cutsceneHandler.timer(4, function()
        //     {
        //         game.gf.playAnim('sad', true);
        //         game.gf.animation.finishCallback = function(name:String)
        //         {
        //             game.gf.playAnim('sad', true);
        //         };
        //     });

        // case 'stress':
        //     cutsceneHandler.endTime = 35.5;
        //     tankman.x -= 54;
        //     tankman.y -= 14;
        //     game.gfGroup.alpha = 0.00001;
        //     game.boyfriendGroup.alpha = 0.00001;
        //     game.camFollow.set(dad.x + 400, dad.y + 170);
        //     FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
        //     foregroundSprites.forEach(function(spr:BGSprite)
        //     {
        //         spr.y += 100;
        //     });
        //     game.precacheList.set('stressCutscene', 'sound');

        //     tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
        //     addBehindDad(tankman2);

        //     if (!ClientPrefs.lowQuality)
        //     {
        //         gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
        //         gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
        //         gfDance.animation.play('dance', true);
        //         addBehindGF(gfDance);
        //     }

        //     gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
        //     gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
        //     gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
        //     gfCutscene.animation.play('dieBitch', true);
        //     gfCutscene.animation.pause();
        //     addBehindGF(gfCutscene);
        //     if (!ClientPrefs.lowQuality)
        //     {
        //         gfCutscene.alpha = 0.00001;
        //     }

        //     picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
        //     picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
        //     addBehindGF(picoCutscene);
        //     picoCutscene.alpha = 0.00001;

        //     boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
        //     boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
        //     boyfriendCutscene.animation.play('idle', true);
        //     boyfriendCutscene.animation.curAnim.finish();
        //     addBehindBF(boyfriendCutscene);

        //     var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
        //     FlxG.sound.list.add(cutsceneSnd);

        //     tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
        //     tankman.animation.play('godEffingDamnIt', true);

        //     var calledTimes:Int = 0;
        //     var zoomBack:Void->Void = function()
        //     {
        //         var camPosX:Float = 630;
        //         var camPosY:Float = 425;
        //         game.camFollow.set(camPosX, camPosY);
        //         game.camFollowPos.setPosition(camPosX, camPosY);
        //         FlxG.camera.zoom = 0.8;
        //         cameraSpeed = 1;

        //         calledTimes++;
        //         if (calledTimes > 1)
        //         {
        //             foregroundSprites.forEach(function(spr:BGSprite)
        //             {
        //                 spr.y -= 100;
        //             });
        //         }
        //     }

        //     cutsceneHandler.onStart = function()
        //     {
        //         cutsceneSnd.play(true);
        //     };

        //     cutsceneHandler.timer(15.2, function()
        //     {
        //         FlxTween.tween(game.camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
        //         FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

        //         gfDance.visible = false;
        //         gfCutscene.alpha = 1;
        //         gfCutscene.animation.play('dieBitch', true);
        //         gfCutscene.animation.finishCallback = function(name:String)
        //         {
        //             if(name == 'dieBitch') //Next part
        //             {
        //                 gfCutscene.animation.play('getRektLmao', true);
        //                 gfCutscene.offset.set(224, 445);
        //             }
        //             else
        //             {
        //                 gfCutscene.visible = false;
        //                 picoCutscene.alpha = 1;
        //                 picoCutscene.animation.play('anim', true);

        //                 boyfriendGroup.alpha = 1;
        //                 boyfriendCutscene.visible = false;
        //                 boyfriend.playAnim('bfCatch', true);
        //                 boyfriend.animation.finishCallback = function(name:String)
        //                 {
        //                     if(name != 'idle')
        //                     {
        //                         game.boyfriend.playAnim('idle', true);
        //                         game.boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
        //                     }
        //                 };

        //                 picoCutscene.animation.finishCallback = function(name:String)
        //                 {
        //                     picoCutscene.visible = false;
        //                     game.gfGroup.alpha = 1;
        //                     picoCutscene.animation.finishCallback = null;
        //                 };
        //                 gfCutscene.animation.finishCallback = null;
        //             }
        //         };
        //     });

        //     cutsceneHandler.timer(17.5, function()
        //     {
        //         zoomBack();
        //     });

        //     cutsceneHandler.timer(19.5, function()
        //     {
        //         tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
        //         tankman2.animation.play('lookWhoItIs', true);
        //         tankman2.alpha = 1;
        //         tankman.visible = false;
        //     });

        //     cutsceneHandler.timer(20, function()
        //     {
        //         game.camFollow.set(dad.x + 500, dad.y + 170);
        //     });

        //     cutsceneHandler.timer(31.2, function()
        //     {
        //         game.boyfriend.playAnim('singUPmiss', true);
        //         game.boyfriend.animation.finishCallback = function(name:String)
        //         {
        //             if (name == 'singUPmiss')
        //             {
        //                 game.boyfriend.playAnim('idle', true);
        //                 game.boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
        //             }
        //         };

        //         game.camFollow.set(game.boyfriend.x + 280, game.boyfriend.y + 200);
        //         cameraSpeed = 12;
        //         FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
        //     });

        //     cutsceneHandler.timer(32.2, function()
        //     {
        //         zoomBack();
        //     });
    // }
// }