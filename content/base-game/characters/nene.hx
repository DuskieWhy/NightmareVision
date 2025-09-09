import funkin.objects.stageobjects.ABotVis;

var abotSpeaker:FlxAnimate;
var pupil:FlxAnimate;
var abotVis:ABotVis;

function onCreate()
{
	dadGroup.zIndex += 1;
	boyfriendGroup.zIndex += 1;
	gfGroup.zIndex += 1;
	
	aBot = new FlxSpriteGroup();
	aBot.setPosition(gf.x + 25, gf.y + 365);
	aBot.zIndex = gfGroup.zIndex - 1;
	// add(aBot);
	stage.add(aBot);
	refreshZ(stage);
	
	eyeWhites = new FlxSprite(-120, 200).makeGraphic(160, 60, FlxColor.WHITE);
	aBot.add(eyeWhites);
	
	stereoBG = new FlxSprite(-20, -20).loadGraphic(Paths.image('characters/abot/stereoBG'));
	aBot.add(stereoBG);
	
	pupil = new FlxAnimate(-125, 190);
	pupil.frames = FlxAnimateFrames.fromAnimate((Paths.textureAtlas('characters/abot/systemEyes')));
	pupil.anim.addBySymbol('left', 'abot eyes 2', 24, false);
	pupil.anim.addBySymbol('right', 'abot eyes', 24, false);
	pupil.anim.addBySymbolIndices('lookin left', 'a bot eyes lookin', [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17], 24, false);
	pupil.anim.addBySymbolIndices('lookin right', 'a bot eyes lookin', [22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35], 24, false);
	pupil.anim.play('lookin right');
	aBot.add(pupil);
	
	abotSpeaker = new FlxAnimate(-175, -50);
	abotSpeaker.frames = FlxAnimateFrames.fromAnimate((Paths.textureAtlas('characters/abot/abotSystem')));
	abotSpeaker.anim.addBySymbol('sys', 'Abot System', 24, false);
	abotSpeaker.anim.play('sys');
	
	abotVis = new ABotVis(FlxG.sound.music, false);
	abotVis.x += 30;
	abotVis.y += 35;
	aBot.add(abotVis);
	abotVis.snd = FlxG.sound.music;
	abotVis.initAnalyzer();
	aBot.add(abotSpeaker);
}

function onSongStart() {}

function onDestroy()
{
	abotVis.dumpSound();
}

function onEndSong()
{
	abotVis.dumpSound();
}

var left = true;

function onBeatHit()
{
	if (abotSpeaker != null) abotSpeaker.anim.play('sys', true);
}

var prevSec = PlayState.SONG.notes[0];

function onSectionHit()
{
	if (pupil != null)
	{
		var sec = PlayState.SONG.notes[curSection];
		if (curSection > 0) prevSec = PlayState.SONG.notes[curSection - 1];
		if (sec.mustHitSection != prevSec.mustHitSection) pupil.anim.play('lookin ' + (sec.mustHitSection ? 'right' : 'left'));
	}
}
