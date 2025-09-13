import openfl.filters.ShaderFilter;

var startIntensity:Float = 0.6;
var endIntensity:Float = 0.8 ;
var rainShader:FlxShader;
var rainTime:Float = 0;

function onLoad(){
    var fuck = new FlxSprite().loadGraphic(Paths.image('weekend1/bgConcept'));
    fuck.scale.set(0.6, 0.6);
    fuck.updateHitbox();
    fuck.screenCenter();
    fuck.x += 550;
    // fuck.y -= 75;
    add(fuck);
    // trace('fckckdscljdslkfjds');

    var black = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
    black.scrollFactor.set();
    black.screenCenter();
    black.alpha = 0.4;
    black.zIndex = 4;
    add(black);
}

function onCreatePost(){
    snapCamToPos(getCharacterCameraPos(dad).x - 100, getCharacterCameraPos(dad).y - 175, true);
    modManager.setValue("alpha", 1, 1);
    modManager.setValue("opponentSwap", 0.5);

    rainShader = newShader('rain');
	rainShader.setFloatArray('uScreenResolution', [FlxG.width, FlxG.height]);
	rainShader.setFloat('uTime', 0);
	rainShader.setFloat('uScale', FlxG.height / 300);
	rainShader.setFloat('uIntensity', startIntensity);
	
	camGame.filters = [new ShaderFilter(rainShader) /*, new ShaderFilter(rain2)*/];

    boyfriendGroup.zIndex = 2000;
    dadGroup.zIndex = 3000;
    playHUD.visible = false;
}

function onUpdate(elapsed){
    rainTime += elapsed;
	
	var remappedIntensityValue:Float = FlxMath.remapToRange(Conductor.songPosition, 0, FlxG.sound.music.length, startIntensity, endIntensity);
	
	rainShader.setFloatArray('uCameraBounds', [
		camGame.scroll.x + camGame.viewMarginX,
		camGame.scroll.y + camGame.viewMarginY,
		camGame.scroll.x + camGame.viewMarginX + camGame.width,
		camGame.scroll.y + camGame.viewMarginY + camGame.height
	]);
	rainShader.setFloat('uTime', rainTime);
	rainShader.setFloat('uIntensity', remappedIntensityValue);
	
}