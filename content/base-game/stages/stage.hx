import funkin.data.Conductor;

function onLoad() 
{
    var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image("stageback"));
	add(bg); 

    var stageFront:FlxSprite = new FlxSprite(-600, 600).loadGraphic(Paths.image("stagefront"));
    add(stageFront);

    var stageCurtains:FlxSprite = new FlxSprite(-600, -300).loadGraphic(Paths.image("stagecurtains"));
    add(stageCurtains);
    stageCurtains.zIndex = 9999;
}

function onUpdate(elapsed){
    if(dad.curCharacter == 'gf') camZooming = false;
}

var t = false;
var t2 = 'boyfriend';
function onMoveCamera(turn){
    if(PlayState.SONG.song.toLowerCase() != 'tutorial') return;

    if(t2 != turn) t = true;
    t2 = turn;

    if(t){
        FlxTween.tween(FlxG.camera, {zoom: turn == 'dad' ? 1.3 : 1}, (Conductor.stepCrotchet / 1000) * 4, {ease: FlxEase.elasticInOut});
        t = false;
    }

}