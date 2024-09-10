
import funkin.objects.stageobjects.BackgroundDancer;
import funkin.objects.BGSprite;

var grpLimoDancers:Array<BackgroundDancer> = [];
var grpLimoParticles:Array<BGSprite> = [];
var limo:BGSprite;
var limoMetalPole:BGSprite;
var limoLight:BGSprite;
var limoCorpse:BGSprite;
var limoCorpseTwo:BGSprite;
var bgLimo:BGSprite;
var fastCar:BGSprite;

var limoSpeed:Float = 0;
var limoKillingState:Int = 0;
function onLoad(){
    var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
    add(skyBG);

    if(!ClientPrefs.lowQuality) {
        limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
        add(limoMetalPole);

        bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
        add(bgLimo);

        // limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
        // add(limoCorpse);

        // limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
        // add(limoCorpseTwo);

        for (i in 0...5)
        {
            var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 170, bgLimo.y - 400);
            dancer.scrollFactor.set(0.4, 0.4);
            add(dancer);
            grpLimoDancers.push(dancer);
        }

        limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
        add(limoLight);

        //PRECACHE BLOOD
        var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
        particle.alpha = 0.01;
        add(particle);
        grpLimoParticles.push(particle);
        // resetLimoKill();
    }

    limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

    fastCar = new BGSprite('limo/fastCarLol', -300, 160);
    fastCar.active = true;
    limoKillingState = 0;
}

function resetLimoKill():Void
{
    if(curStage == 'limo') {
        limoMetalPole.x = -500;
        limoMetalPole.visible = false;
        limoLight.x = -500;
        limoLight.visible = false;
        limoCorpse.x = -500;
        limoCorpse.visible = false;
        limoCorpseTwo.x = -500;
        limoCorpseTwo.visible = false;
    }
}

function killHenchmen():Void
{
    if(!ClientPrefs.lowQuality) {
        if(limoKillingState < 1) {
            limoMetalPole.x = -400;
            limoMetalPole.visible = true;
            limoLight.visible = true;
            limoCorpse.visible = false;
            limoCorpseTwo.visible = false;
            limoKillingState = 1;
        }
    }
}

function resetFastCar():Void
{
    fastCar.x = -12600;
    fastCar.y = FlxG.random.int(140, 250);
    fastCar.velocity.x = 0;
    fastCarCanDrive = true;
}

var carTimer:FlxTimer;
function fastCarDrive()
{
    //trace('Car drive');
    FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

    fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
    fastCarCanDrive = false;
    carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
    {
        resetFastCar();
        carTimer = null;
    });
}

function onCreatePost(){
    game.addBehindBF(limo);
    game.addBehindGF(fastCar);
    resetFastCar();
}

function onUpdate(elapsed){
    if(!ClientPrefs.lowQuality) {
        for(spr in grpLimoParticles){
            if(spr.animation.curAnim.finished) {
                spr.kill();
                grpLimoParticles.remove(spr);
                spr.destroy();
            }
        }
        switch(limoKillingState) {
            case 1:
                limoMetalPole.x += 5000 * elapsed;
                limoLight.x = limoMetalPole.x - 180;
                limoCorpse.x = limoLight.x - 50;
                limoCorpseTwo.x = limoLight.x + 35;

                var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
                for (i in 0...dancers.length) {
                    if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170) {
                        switch(i) {
                            case 0 | 3:
                                if(i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

                                var diffStr:String = i == 3 ? ' 2 ' : ' ';
                                var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
                                add(particle);
                                grpLimoParticles.push(particle);
                                var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
                                add(particle);
                                grpLimoParticles.push(particle);
                                var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
                                add(particle);
                                grpLimoParticles.push(particle);

                                var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
                                particle.flipX = true;
                                particle.angle = -57.5;
                                add(particle);
                                grpLimoParticles.push(particle);
                            case 1:
                                limoCorpse.visible = true;
                            case 2:
                                limoCorpseTwo.visible = true;
                        } //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
                        dancers[i].x += FlxG.width * 2;
                    }
                }

                if(limoMetalPole.x > FlxG.width * 2) {
                    resetLimoKill();
                    limoSpeed = 800;
                    limoKillingState = 2;
                }

            case 2:
                limoSpeed -= 4000 * elapsed;
                bgLimo.x -= limoSpeed * elapsed;
                if(bgLimo.x > FlxG.width * 1.5) {
                    limoSpeed = 3000;
                    limoKillingState = 3;
                }

            case 3:
                limoSpeed -= 2000 * elapsed;
                if(limoSpeed < 1000) limoSpeed = 1000;

                bgLimo.x -= limoSpeed * elapsed;
                if(bgLimo.x < -275) {
                    limoKillingState = 4;
                    limoSpeed = 800;
                }

            case 4:
                bgLimo.x = FlxMath.lerp(bgLimo.x, -150, FlxMath.bound(elapsed * 9, 0, 1));
                if(Math.round(bgLimo.x) == -150) {
                    bgLimo.x = -150;
                    limoKillingState = 0;
                }
        }

        if(limoKillingState > 2) {
            for(i in 0...grpLimoDancers.length){
                grpLimoDancers[i].x = (370 * i) + bgLimo.x + 280;
            }
        }

        FlxG.watch.addQuick("Limo Speed", limoSpeed);
    }
}

function onCountdownTick(){
    if(!ClientPrefs.lowQuality) {
        for(dancer in grpLimoDancers){
            dancer.dance();
        }
    }
}

function onBeatHit(){
    if(!ClientPrefs.lowQuality) {
        for(dancer in grpLimoDancers){
            dancer.dance();
        }
    }
    if(FlxG.random.bool(10) && fastCarCanDrive) fastCarDrive();
}

function onEvent(event, value1, value2){
    if(value1 == 'Kill Henchmen') killHenchmen();
}