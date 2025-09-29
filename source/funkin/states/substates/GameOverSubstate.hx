package funkin.states.substates;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

import funkin.backend.MusicBeatSubstate;
import funkin.states.PlayState;
import funkin.objects.Character;

/**
 * The substate that goes over the game whenever the player dies.
 */
class GameOverSubstate extends MusicBeatSubstate
{
	/**
	 * Static reference to the substate. Used for scripting purposes.
	 */
	public static var instance:Null<GameOverSubstate> = null;
	
	/**
	 * The name of the game over character to use.
	 */
	public static var characterName:Null<String> = null;
	
	/**
	 * The sound effect to be played on death.
	 */
	public static var deathSoundName:Null<String> = null;
	
	/**
	 * The music to be played in the game over.
	 */
	public static var loopSoundName:Null<String> = null;
	
	/**
	 * The sound effect to be played when the gameover is finished.
	 */
	public static var endSoundName:Null<String> = null;
	
	/**
	 * The game over character.
	 */
	public var boyfriend:Null<Character> = null;
	
	/**
	 * The object the camera will follow. Placed on the midpoint of `boyfriend`.
	 */
	var camFollow:FlxObject;
	
	/**
	 * Flag that is true when the intro of `boyfriend`'s death animation is finished.
	 */
	var startedDeath:Bool = false;
	
	/**
	 * Resets gameover character values
	 */
	public static function resetVariables()
	{
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
	}
	
	override function create()
	{
		instance = this;
		
		PlayState.instance?.scripts.set('inGameOver', true);
		PlayState.instance?.scripts.call('onGameOverStart', []);
		
		Conductor.songPosition = 0;
		
		if (boyfriend == null)
		{
			boyfriend = new Character(PlayState.instance.boyfriend.getScreenPosition()
				.x, PlayState.instance.boyfriend.getScreenPosition().y, characterName, true);
			boyfriend.x += boyfriend.positionArray[0] - PlayState.instance.boyfriend.positionArray[0];
			boyfriend.y += boyfriend.positionArray[1] - PlayState.instance.boyfriend.positionArray[1];
		}
		boyfriend.skipDance = true;
		add(boyfriend);
		
		camFollow = new FlxObject(boyfriend.getMidpoint()
			.x - boyfriend.cameraPosition[0] - 100, boyfriend.getMidpoint().y + boyfriend.cameraPosition[1] - 100);
			
		if (deathSoundName != null) FlxG.sound.play(Paths.sound(deathSoundName));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;
		
		boyfriend.playAnim('firstDeath');
		
		FlxG.camera.follow(camFollow, LOCKON, 0);
		
		super.create();
		
		PlayState.instance?.scripts.call('onGameOverPost', []);
	}
	
	public function new(?character:Character)
	{
		super();
		
		if (character != null)
		{
			characterName = character.gameoverCharacter ?? characterName;
			
			endSoundName = character.gameoverConfirmDeathSound ?? endSoundName;
			
			deathSoundName = character.gameoverInitialDeathSound ?? deathSoundName;
			
			loopSoundName = character.gameoverLoopDeathSound ?? loopSoundName;
		}
		
		// characterName = character ?? characterName;
		// reuse the og bf if its the same one
		if (PlayState.instance.boyfriend != null && PlayState.instance.boyfriend.curCharacter == characterName)
		{
			boyfriend = PlayState.instance.boyfriend;
		}
	}
	
	override function update(elapsed:Float)
	{
		PlayState.instance?.scripts.call('onUpdate', [elapsed]);
		super.update(elapsed);
		
		if (controls.ACCEPT)
		{
			endBullshit();
		}
		
		if (controls.BACK)
		{
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			
			FlxG.switchState(() -> PlayState.isStoryMode ? new StoryMenuState() : new FreeplayState());
			
			FunkinSound.playMusic(Paths.music('freakyMenu'));
			PlayState.instance?.scripts.call('onGameOverConfirm', [false]);
		}
		
		if (boyfriend.getAnimName() == 'firstDeath' && boyfriend.isAnimFinished() && startedDeath)
		{
			boyfriend.playAnim('deathLoop');
		}
		
		if (boyfriend.getAnimName() == 'firstDeath')
		{
			if (boyfriend.animCurFrame >= 12)
			{
				FlxG.camera.followLerp = 0.02;
			}
			
			if (boyfriend.isAnimFinished())
			{
				coolStartDeath();
				startedDeath = true;
			}
		}
		
		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
		
		PlayState.instance?.scripts.call('onUpdatePost', [elapsed]);
	}
	
	/**
	 *	Triggers the game over music after the intro.
	 * @param volume 
	 */
	function coolStartDeath(?volume:Float = 1):Void
	{
		if (loopSoundName != null) FunkinSound.playMusic(Paths.music(loopSoundName), volume);
		
		PlayState.instance?.scripts.call('deathAnimStart', [volume]);
	}
	
	/**
	 * Flag to prevent spamming of `endBullshit`
	 */
	var isEnding:Bool = false;
	
	/**
	 *	Finishes the game over and restarts the game.
	 */
	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			boyfriend.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			if (endSoundName != null) FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer) {
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function() {
					FlxG.resetState();
				});
			});
			PlayState.instance?.scripts.call('onGameOverConfirm', [true]);
		}
	}
	
	override function destroy()
	{
		instance = null;
		super.destroy();
	}
}
