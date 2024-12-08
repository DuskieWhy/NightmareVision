package funkin.states.substates;

import funkin.objects.video.FunkinVideoSprite;
import funkin.backend.MusicBeatSubstate;
import funkin.states.*;
import flixel.FlxG;

class GameOverVideoSubstate extends MusicBeatSubstate
{
	public static var video:FunkinVideoSprite;
	public static var instance:GameOverVideoSubstate;

	override function create()
	{
		instance = this;
		PlayState.instance.callOnScripts('onGameOverStart', []);

		super.create();
	}

	public function new(name:String)
	{
		super();

		PlayState.instance.setOnScripts('inGameOver', true);

		Conductor.songPosition = 0;

		video = new FunkinVideoSprite(0, 0, true, true);
		video.addCallback('onFormat', () -> {
			video.setGraphicSize(0, FlxG.height);
			video.updateHitbox();
			video.screenCenter();
			video.antialiasing = ClientPrefs.globalAntialiasing;
			video.cameras = [PlayState.instance.camOther];
		});
		video.addCallback('onEnd', () -> {
			FlxG.resetState();
		});
		video.load(Paths.video(name));
		video.play();
		add(video);
	}

	override function update(elapsed:Float)
	{
		PlayState.instance.callOnScripts('onUpdate', [elapsed]);
		PlayState.instance.callOnHScripts('update', [elapsed]);
		super.update(elapsed);

		PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);

		if (controls.ACCEPT)
		{
			PlayState.instance.callOnScripts('onGameOverConfirm', [true]);
			FlxG.resetState();
		}

		if (controls.BACK)
		{
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;

			FlxG.switchState(() -> PlayState.isStoryMode ? new StoryMenuState() : new FreeplayState());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.instance.callOnScripts('onGameOverConfirm', [false]);
		}
	}
}
