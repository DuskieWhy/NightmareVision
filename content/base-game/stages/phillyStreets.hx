import openfl.filters.ShaderFilter;

import animate.FlxAnimateFrames;
import animate.FlxAnimate;

import flixel.addons.display.FlxTiledSprite;

var trafficLight:FlxSprite;
var lightStatus:Bool = true;
var cars:FlxSpriteGroup;
var cars2:FlxSpriteGroup;
var startIntensity:Float = 0;
var endIntensity:Float = 0.1;
var rainShader:FlxShader;
var rainTime:Float = 0;
var darken = [];
var skipCutscene = false;
var seenCutscene = false;

function onLoad()
{
	scrollingSky = new FlxTiledSprite(Paths.image('phillyStreets/phillySkybox'), 2922, 850, true, false);
	scrollingSky.setPosition(-1200, -900);
	scrollingSky.scrollFactor.set(0.1, 0.1);
	scrollingSky.scale.set(0.65, 0.65);
	add(scrollingSky);
	
	var skyline = new FlxSprite(-800, -800).loadGraphic(Paths.image('phillyStreets/phillySkyline'));
	skyline.scrollFactor.set(0.2, 0.2);
	add(skyline);
	
	var bgCity = new FlxSprite(250, -450).loadGraphic(Paths.image('phillyStreets/phillyForegroundCity'));
	bgCity.scrollFactor.set(0.45, 0.45);
	add(bgCity);
	
	var hLights = new FlxSprite(-800, -285).loadGraphic(Paths.image('phillyStreets/phillyHighwayLights'));
	add(hLights);
	
	var hLightsMap = new FlxSprite(-800, -285).loadGraphic(Paths.image('phillyStreets/phillyHighwayLights_lightmap'));
	hLightsMap.blend = BlendMode.ADD;
	add(hLightsMap);
	
	var highway = new FlxSprite(-800, -400).loadGraphic(Paths.image('phillyStreets/phillyHighway'));
	add(highway);
	
	var buildingFront = new FlxSprite(1050, -600).loadGraphic(Paths.image('phillyStreets/phillyConstruction'));
	buildingFront.scrollFactor.set(0.6, 0.6);
	buildingFront.scale.set(1.3, 1.3);
	buildingFront.updateHitbox();
	add(buildingFront);
	
	var smog = new FlxSprite(-600, -400).loadGraphic(Paths.image('phillyStreets/phillySmog'));
	add(smog);
	
	trafficLight = new FlxSprite(1200);
	trafficLight.frames = Paths.getSparrowAtlas('phillyStreets/phillyTraffic');
	trafficLight.animation.addByPrefix("redtogreen", "redtogreen", 24, false);
	trafficLight.animation.addByPrefix("greentored", "greentored", 24, false);
	trafficLight.animation.play('redtogreen');
	add(trafficLight);
	
	var lightmap = new FlxSprite(1200, -5).loadGraphic(Paths.image('phillyStreets/phillyTraffic_lightmap'));
	lightmap.blend = BlendMode.ADD;
	add(lightmap);
	
	cars = new FlxSpriteGroup();
	add(cars);
	cars2 = new FlxSpriteGroup();
	add(cars2);
	
	for (i in 0...4)
	{
		var car = new FlxSprite();
		car.frames = Paths.getSparrowAtlas('phillyStreets/phillyCars');
		car.animation.addByPrefix('car', 'car' + i, 24, true);
		car.animation.play('car');
		cars.add(car);
		
		var car = new FlxSprite();
		car.frames = Paths.getSparrowAtlas('phillyStreets/phillyCars');
		car.animation.addByPrefix('car', 'car' + i, 24, true);
		car.animation.play('car');
		car.flipX = true;
		cars2.add(car);
	}
	
	var ground = new FlxSprite().loadGraphic(Paths.image('phillyStreets/phillyForeground'));
	ground.screenCenter();
	add(ground);
	
	var spraycanPile = new FlxSprite(50, 420).loadGraphic(Paths.image('weekend1/SpraycanPile'));
	spraycanPile.zIndex = 5;
	add(spraycanPile);
	
	cutsceneCan = new FlxSprite();
	cutsceneCan.frames = Paths.getSparrowAtlas('weekend1/wked1_cutscene_1_can');
	cutsceneCan.animation.addByPrefix('forward', "can kick quick", 24, false);
	cutsceneCan.animation.addByPrefix('up', "can kicked up", 24, false);
	cutsceneCan.zIndex = 4;
	// cutsceneCan.animation.play('up');
	cutsceneCan.visible = false;
	cutsceneCan.setPosition(spraycanPile.x + 60, spraycanPile.y - 320);
	add(cutsceneCan);
	
	remove(cars);
	remove(cars2);
	for (i in stage.members)
	{
		i.x += 845;
		i.y += 630;
	}
	
	resetCar(true, true);
	driveCar(cars);
	
	darken = [scrollingSky, skyline, bgCity, hLights, hLightsMap, highway, smog, trafficLight, lightmap, ground];
}

function onCreatePost()
{
	switch (PlayState.SONG.song.toLowerCase())
	{
		case 'darnell':
			startIntensity = 0;
			endIntensity = 0.1;
		case 'lit-up':
			startIntensity = 0.1;
			endIntensity = 0.2;
		case '2hot':
			startIntensity = 0.2;
			endIntensity = 0.4;
	}
	
	rainShader = newShader('rain');
	rainShader.setFloatArray('uScreenResolution', [FlxG.width, FlxG.height]);
	rainShader.setFloat('uTime', 0);
	rainShader.setFloat('uScale', FlxG.height / 300);
	rainShader.setFloat('uIntensity', startIntensity);
	
	camGame.filters = [new ShaderFilter(rainShader) /*, new ShaderFilter(rain2)*/];
}

var neneTimer = 0;

function onUpdate(elapsed)
{
	if (scrollingSky != null) scrollingSky.scrollX -= FlxG.elapsed * 22;
	
	rainTime += elapsed;
	rainTime++;
	
	var remappedIntensityValue:Float = FlxMath.remapToRange(Conductor.songPosition, 0, FlxG.sound.music.length, startIntensity, endIntensity);
	
	rainShader.setFloatArray('uCameraBounds', [
		camGame.scroll.x + camGame.viewMarginX,
		camGame.scroll.y + camGame.viewMarginY,
		camGame.scroll.x + camGame.viewMarginX + camGame.width,
		camGame.scroll.y + camGame.viewMarginY + camGame.height
	]);
	rainShader.setFloat('uTime', rainTime);
	rainShader.setFloat('uIntensity', remappedIntensityValue);
	
	if (!skipCutscene && !seenCutscene)
	{
		neneTimer += elapsed;
		if (neneTimer >= 0.6)
		{
			neneTimer = 0;
			gf.dance();
		}
	}
}

function resetCar(left:Bool, right:Bool)
{
	if (left)
	{
		for (i in cars.members)
		{
			FlxTween.cancelTweensOf(i);
			i.setPosition(1200, 818);
			i.angle = 0;
		}
	}
	
	if (right)
	{
		for (i in cars2.members)
		{
			FlxTween.cancelTweensOf(i);
			i.setPosition(1200, 818);
			i.angle = 0;
		}
	}
}

function driveCarLights(group:FlxSpriteGroup)
{
	var variant:Int = FlxG.random.int(0, 3);
	
	var sprite = group.members[variant];
	
	FlxTween.cancelTweensOf(sprite);
	var extraOffset = [0, 0];
	var duration:Float = 2;
	
	switch (variant)
	{
		case 1:
			duration = FlxG.random.float(1, 1.7);
		case 2:
			extraOffset = [20, -15];
			duration = FlxG.random.float(0.9, 1.5);
		case 3:
			extraOffset = [30, 50];
			duration = FlxG.random.float(1.5, 2.5);
		case 4:
			extraOffset = [10, 60];
			duration = FlxG.random.float(1.5, 2.5);
	}
	var rotations:Array<Int> = [-7, -5];
	var offset:Array<Float> = [306.6, 168.3];
	sprite.offset.set(extraOffset[0], extraOffset[1]);
	
	var path:Array<FlxPoint> = [
		FlxPoint.get(1500 - offset[0] - 20, 1049 - offset[1] - 20),
		FlxPoint.get(1770 - offset[0] - 80, 994 - offset[1] + 10),
		FlxPoint.get(1950 - offset[0] - 80, 980 - offset[1] + 15)
	];
	
	FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.cubeOut});
	FlxTween.quadPath(sprite, path, duration, true,
		{
			ease: FlxEase.cubeOut
		});
}

function driveCar(group:FlxSpriteGroup)
{
	var variant:Int = FlxG.random.int(0, 3);
	
	var sprite = group.members[variant];
	var reverse = group == cars2;
	var extraOffset = [0, 0];
	var duration:Float = 2;
	// set different values of speed for the car types (and the offset)
	switch (variant)
	{
		case 1:
			duration = FlxG.random.float(1, 1.7);
		case 2:
			extraOffset = [20, -15];
			duration = FlxG.random.float(0.6, 1.2);
		case 3:
			extraOffset = [30, 50];
			duration = FlxG.random.float(1.5, 2.5);
		case 4:
			extraOffset = [10, 60];
			duration = FlxG.random.float(1.5, 2.5);
	}
	// random arbitrary values for getting the cars in place
	// could just add them to the points but im LAZY!!!!!!
	var offset:Array<Float> = [306.6, 168.3];
	sprite.offset.set(extraOffset[0], extraOffset[1]);
	// start/end rotation
	var rotations:Array<Int> = [-8, 18];
	// the path to move the car on
	var path:Array<FlxPoint> = [
		FlxPoint.get(1570 - offset[0], 1049 - offset[1] - 30),
		FlxPoint.get(2400 - offset[0], 980 - offset[1] - 50),
		FlxPoint.get(3102 - offset[0], 1187 - offset[1] + 40)
	];
	
	FlxTween.angle(sprite, rotations[0], rotations[1], duration, {type: reverse ? 16 : null});
	FlxTween.quadPath(sprite, path, duration, true,
		{
			ease: null,
			type: reverse ? 16 : null
		});
}

function onStartCountdown()
{
	if (!skipCutscene && !seenCutscene)
	{
		switch (PlayState.SONG.song.toLowerCase())
		{
			case 'darnell':
				FunkinSound.playMusic(Paths.music('darnellCanCutscene/darnellCanCutscene'));
				snapCamToPos(getCharacterCameraPos(boyfriend).x + 100, getCharacterCameraPos(boyfriend).y + 105, true);
				
				playHUD.visible = false;
				camGame.visible = false;
				cameraSpeed = 5;
				camGame.zoom = 1.3;
				dad.canDance = false;
				boyfriend.canDance = false;
				boyfriend.playAnim('intro1', true);
				
				FlxTimer.wait(0.5, () -> {
					camGame.flash(FlxColor.BLACK, 3);
					camGame.visible = true;
					FlxTween.tween(camGame, {zoom: 0.75}, 5, {ease: FlxEase.quadInOut});
				});
				
				FlxTimer.wait(2, () -> {
					FlxTween.tween(camFollow, {x: getCharacterCameraPos(dad).x + 350, y: getCharacterCameraPos(dad).y}, 2.5, {ease: FlxEase.quadInOut});
				});
				
				FlxTimer.wait(5, () -> {
					dad.playAnim('lightCan', true);
					FlxG.sound.play(Paths.sound('Darnell_Lighter'));
					FlxTween.tween(camFollow, {x: getCharacterCameraPos(dad).x + 150}, 0.5, {ease: FlxEase.quadInOut});
					FlxTween.tween(camGame, {zoom: 0.9}, 0.625, {ease: FlxEase.quadInOut});
				});
				
				FlxTimer.wait(6, () -> {
					boyfriend.playAnim('cock', true);
					FlxG.sound.play(Paths.sound('Gun_Prep'));
					FlxTween.tween(camFollow, {x: getCharacterCameraPos(dad).x + 500, y: getCharacterCameraPos(dad).y}, 0.4, {ease: FlxEase.quadInOut});
				});
				
				FlxTimer.wait(6.4, () -> {
					dad.playAnim('kickCan', true);
					FlxG.sound.play(Paths.sound('Kick_Can_UP'));
					cutsceneCan.animation.play('up');
					cutsceneCan.visible = true;
					FlxTween.tween(camFollow, {x: getCharacterCameraPos(dad).x + 350, y: getCharacterCameraPos(dad).y}, 0.5, {ease: FlxEase.quadInOut});
				});
				
				FlxTimer.wait(6.9, () -> {
					dad.playAnim('kneeCan', true);
					FlxG.sound.play(Paths.sound('Kick_Can_FORWARD'));
					cutsceneCan.animation.play('forward');
					FlxTween.tween(camGame, {zoom: 0.7}, 0.325, {ease: FlxEase.quadInOut});
				});
				
				FlxTimer.wait(7.1, () -> {
					boyfriend.playAnim('intro2', true);
					FlxG.sound.play(Paths.sound('shot' + FlxG.random.int(1, 4)));
					FlxTween.tween(camFollow, {x: getCharacterCameraPos(dad).x + 100, y: getCharacterCameraPos(dad).y - 25}, 2.5, {ease: FlxEase.quadInOut});
					cutsceneCan.visible = false;
					cutsceneSpraycan();
					
					for (i in darken)
						FlxTween.color(i, 1, 0xFF3F3F3F, FlxColor.WHITE);
				});
				
				FlxTimer.wait(7.9, () -> {
					dad.playAnim('laughCutscene', true);
					FlxG.sound.play(Paths.sound('cutscene/darnell_laugh'), 0.6);
				});
				
				FlxTimer.wait(8.2, () -> {
					seenCutscene = true;
					
					gf.canDance = false;
					gf.playAnim('laughCutscene', true);
					FlxG.sound.play(Paths.sound('cutscene/nene_laugh'), 0.6);
				});
				
				FlxTimer.wait(10, () -> {
					FlxTween.tween(camGame, {zoom: 0.77}, 2, {ease: FlxEase.sineInOut});
					FlxTween.tween(camFollow, {x: getCharacterCameraPos(dad).x, y: getCharacterCameraPos(dad).y}, 2,
						{
							ease: FlxEase.sineInOut,
							onComplete: () -> {
								isCameraOnForcedPos = false;
							}
						});
					FlxG.sound.music.stop();
					cameraSpeed = 1;
					
					playHUD.visible = true;
					for (i in [playHUD.healthBar, playHUD.iconP1, playHUD.iconP2, playHUD.scoreTxt])
					{
						var ogPos = i.y;
						i.y += (ClientPrefs.downScroll ? -250 : 250);
						FlxTween.tween(i, {y: ogPos}, 1, {ease: FlxEase.quintOut, startDelay: 1});
					}
					
					dad.canDance = true;
					boyfriend.canDance = true;
					gf.canDance = true;
					startCountdown();
				});
			default:
				// has no cutscene
				seenCutscene = true;
				startCountdown();
		}
		return Function_Stop;
	}
}

// to do: add the spraycan stuff to 2hot and use this with it
function explodeSpraycan()
{
	var explosion = new FlxSprite(800);
	explosion.frames = Paths.getSparrowAtlas('weekend1/spraypaintExplosionEZ');
	explosion.animation.addByPrefix("idle", "explosion round 1 short0", 24, false);
	explosion.animation.play("idle");
	explosion.animation.finishCallback = () -> {
		explosion.kill();
	}
	stage.add(explosion);
	explosion.zIndex = 999;
	refreshZ(stage);
}

function cutsceneSpraycan()
{
	var explosion = new FlxSprite(1000, 200);
	explosion.frames = Paths.getSparrowAtlas('weekend1/SpraypaintExplosion');
	explosion.animation.addByPrefix("idle", "Explosion 1 movie", 24, false);
	explosion.animation.play("idle");
	explosion.animation.finishCallback = () -> {
		explosion.kill();
	}
	stage.add(explosion);
	explosion.zIndex = 999;
	refreshZ(stage);
}
