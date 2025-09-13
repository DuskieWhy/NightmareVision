function onUpdate(elapsed)
{
	camZooming = false;
}

var canTween = false;
var lastTurn = 'boyfriend';

function onMoveCamera(turn)
{
	if (PlayState.SONG.song.toLowerCase() != 'tutorial') return;
	
	if (lastTurn != turn) canTween = true;
	lastTurn = turn;
	
	if (canTween)
	{
		FlxTween.tween(FlxG.camera, {zoom: turn == 'dad' ? 1.3 : 1}, (Conductor.stepCrotchet / 1000) * 4, {ease: FlxEase.elasticInOut});
		canTween = false;
	}
}
