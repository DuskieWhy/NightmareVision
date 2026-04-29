package funkin.states;

import funkin.data.SongMetaData;

import haxe.Timer;
import haxe.ds.Vector;

import openfl.events.KeyboardEvent;

import flixel.util.FlxDestroyUtil;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.util.helpers.FlxBounds;
import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.util.FlxStringUtil;

import funkin.objects.Character;
import funkin.backend.Difficulty;
import funkin.game.RatingInfo;
import funkin.objects.note.*;
import funkin.objects.note.Note.EventNote;
import funkin.game.huds.BaseHUD;
import funkin.scripts.*;
import funkin.data.Song;
import funkin.data.StageData;
import funkin.game.Rating;
import funkin.objects.*;
import funkin.data.*;
import funkin.states.*;
import funkin.states.substates.*;
import funkin.states.editors.*;
import funkin.game.modchart.*;
import funkin.game.StoryMeta;
import funkin.game.Countdown;
import funkin.input.InputSystem;
import funkin.input.InputEvent;
import funkin.audio.SyncedFlxSoundGroup;
#if VIDEOS_ALLOWED
import funkin.video.FunkinVideoSprite;
#end

class PlayState extends MusicBeatState
{
	public static var meta:Null<SongMetaData> = null; // bad?
	
	public static var SONG:Null<Song> = null;
	
	public static var storyMeta:StoryMeta = new StoryMeta();
	
	public static var isStoryMode:Bool = false;
	
	/**
	 * Static reference to the state. used for other classes to reference
	 */
	public static var instance:Null<PlayState> = null;
	
	public static var ratingStuff:Array<RatingInfo> = [
		new RatingInfo('You Suck!', 0.2),
		new RatingInfo('Shit', 0.4),
		new RatingInfo('Bad', 0.5),
		new RatingInfo('Bruh', 0.6),
		new RatingInfo('Meh', 0.69),
		new RatingInfo('Nice', 0.7),
		new RatingInfo('Good', 0.8),
		new RatingInfo('Great', 0.9),
		new RatingInfo('Great', 0.9),
		new RatingInfo('Sick!', 1),
		new RatingInfo('Perfect!!', 1),
	];
	
	/**
	 * Helper function to ready PlayState for conveniently.
	 * 
	 * will return null if done successfully. Otherwise, the exception will be returned.
	 */
	public static function prepareForWeek(songs:Array<String>, difficulty:Int = 1, isStoryMode:Bool = false):Null<haxe.Exception>
	{
		try
		{
			PlayState.SONG = Chart.fromSong(songs[0], difficulty);
			PlayState.storyMeta.playlist = songs;
			PlayState.storyMeta.difficulty = difficulty;
			PlayState.isStoryMode = isStoryMode;
			return null;
		}
		catch (e)
		{
			// Logger.log('Failed to prepare for song.\nException $e', ERROR);
			return e;
		}
	}
	
	/**
	 * Helper function to ready PlayState for conveniently.
	 * 
	 * will return null if done successfully. Otherwise, the exception will be returned.
	 */
	public static function prepareForSong(songName:String, difficulty:Int = 1, isStoryMode:Bool = false):Null<haxe.Exception>
	{
		try
		{
			PlayState.SONG = Chart.fromSong(songName, difficulty);
			PlayState.storyMeta.difficulty = difficulty;
			PlayState.isStoryMode = isStoryMode;
			
			return null;
		}
		catch (e)
		{
			// Logger.log('Failed to prepare for song.\nException $e', ERROR);
			return e;
		}
	}
	
	/**
	 * Multiplier to the game speed
	 */
	public var playbackRate(default, set):Float = 1;
	
	function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if (generatedMusic) audio.pitch = playbackRate;
		
		FlxG.animationTimeScale = value;
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * value;
		
		playbackRate = value;
		#else
		playbackRate = 1;
		#end
		return playbackRate;
	}
	
	public var volumeMult(default, set):Float = 1;
	
	function set_volumeMult(value:Float):Float
	{
		volumeMult = value;
		
		audio.volume *= volumeMult;
		
		return volumeMult;
	}
	
	public var arrowSkins:Array<String> = [];
	
	public var modManager:ModManager;
	public var modifiersRegistered:Bool = false;
	public var generatedFields:Bool = false;
	
	var speedChanges:Array<SpeedEvent> = [{}];
	
	public var currentSV:SpeedEvent = {};
	
	public var noteRows:Array<Array<Array<Note>>> = [[], []];
	
	public var variables:Map<String, Dynamic> = new Map();
	
	/**
	 * Disables automatic camera movements if enabled.
	 */
	public var isCameraOnForcedPos:Bool = false;
	
	public var cameraLerping:Bool = true;
	
	/**
	 * Container of all boyfriend's used in the state
	 * 
	 * Exists for the `Change Character` event.
	 */
	public var boyfriendGroup:CharacterGroup;
	
	/**
	 * Container of all dad's used in the state
	 * 
	 * Exists for the `Change Character` event.
	 */
	public var dadGroup:CharacterGroup;
	
	/**
	 * Container of all gf's used in the state
	 * 
	 * Exists for the `Change Character` event.
	 */
	public var gfGroup:CharacterGroup;
	
	/**
		Reference to the current dad
	**/
	public var dad:Character;
	
	/**
		Reference to the current girlfriend
	**/
	public var gf:Character;
	
	/**
		Reference to the current boyfriend
	**/
	public var boyfriend:Character;
	
	/**
		Reference to the player stage X position
	**/
	public var BF_X:Float = 770;
	
	/**
		Reference to the player stage Y position
	**/
	public var BF_Y:Float = 100;
	
	/**
		Reference to the opponent stage X position
	**/
	public var DAD_X:Float = 100;
	
	/**
		Reference to the opponent stage Y position
	**/
	public var DAD_Y:Float = 100;
	
	/**
		Reference to the girlfriend stage X position
	**/
	public var GF_X:Float = 400;
	
	/**
		Reference to the girlfriend stage Y position
	**/
	public var GF_Y:Float = 130;
	
	public var gfSpeed(default, set):Int = 1;
	
	function set_gfSpeed(value:Int)
	{
		if (gfGroup == null || gf == null) return gfSpeed = value;
		
		gf.danceEveryNumBeats *= value;
		
		return gfSpeed = value;
	}
	
	/**
	 * A container of where all sprites placed
	 */
	public var stage:Stage;
	
	public var songSpeedTween:Null<FlxTween> = null;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;
	
	public var spawnTime:Float = 3000;
	
	public var holdSubdivisions:Int = 1;
	
	/**
	 * Specialized container for song audio
	 */
	public var audio:PlayableSong;
	
	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];
	
	/**
	 * Target the game camera follows
	 */
	var camFollow:FlxObject;
	
	/**
	 * Previous cameras target. used in story mode for a more seamless transition
	 */
	static var prevCamFollow:Null<FlxObject> = null;
	
	/**
	 * List of FlxCameras that follow camFollow
	**/
	public var followingCams:Array<FlxCamera> = [];
	
	/**
	 * Container of all strumlines in use
	 */
	public var playFields:Null<FlxTypedGroup<PlayField>> = null;
	
	/**
	 * The oppononents Strum field
	 */
	public var opponentStrums(get, never):Null<PlayField>;
	
	function get_opponentStrums()
	{
		for (i in playFields?.members)
			if (i.ID == 1) return i;
		return playFields?.members[1];
	}
	
	/**
	 * The players Strum field
	 */
	public var playerStrums(get, never):Null<PlayField>;
	
	function get_playerStrums()
	{
		for (i in playFields?.members)
			if (i.ID == 0) return i;
		return playFields?.members[0];
	}
	
	// i dont understand the need to change the ids tbh
	function getFieldFromID(id:Int):Null<PlayField>
	{
		for (i in playFields?.members)
			if (i.ID == id) return i;
		return playFields?.members[id];
	}
	
	@:isVar public var strumLineNotes(get, null):Array<StrumNote>;
	
	@:noCompletion function get_strumLineNotes()
	{
		final notes:Array<StrumNote> = [];
		if (playFields != null && playFields.length != 0)
		{
			for (field in playFields.members)
			{
				for (sturm in field.members)
					notes.push(sturm);
			}
		}
		return notes;
	}
	
	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	
	var curSong:String = "";
	
	/**
	 * The minimum and max bound that health can be within
	 */
	public var healthBounds:FlxBounds<Float> = new FlxBounds(0.0, 2.0);
	
	@:isVar public var health(default, set):Float = 1;
	
	@:noCompletion function set_health(value:Float):Float
	{
		health = value;
		callHUDFunc(hud -> hud.onHealthChange(value));
		return value;
	}
	
	var songPercent:Float = 0;
	
	public var combo:Int = 0;
	public var ratingsData:Array<Rating> = [
		new Rating('sick'),
		new Rating('good'),
		new Rating('bad'),
		new Rating('shit')
	];
	
	public var epics:Int = 0;
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	
	var generatedMusic:Bool = false;
	
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	
	var updateTime:Bool = true;
	
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;
	public static var startOnTime:Float = 0;
	
	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled(default, set):Bool = false;
	public var practiceMode:Bool = false;
	
	public var botplayTxt:FlxText;
	
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;
	
	public var defaultScoreAddition:Bool = true;
	
	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;
	
	public var defaultCamZoomAdd:Float = 0;
	
	/**
	 * Default camera zoom the game will attempt to return to.
	 * 
	 * set via the Stage json
	 */
	public var defaultCamZoom:Float = 1.05;
	
	/**
	 * Default `camHUD` zoom the game will attempt to return to.
	 */
	public var defaultHudZoom:Float = 1;
	
	public var beatsPerZoom:Int = 4;
	
	public var inCutscene:Bool = false;
	public var ingameCutscene:Bool = false;
	
	public var genNotesBeforeCountdown:Bool = true;
	
	public var skipCountdown:Bool = false;
	public var countdownSounds:Bool = true;
	public var countdownDelay:Float = 0;
	
	/**
	 * The length of the music track in miliseconds
	 * 
	 * Used for discord RPC and the time bar.
	 * 
	 * Can be manually changed.
	 */
	var songLength:Float = 0;
	
	public var boyfriendCameraOffset:Array<Float> = [0, 0];
	public var opponentCameraOffset:Array<Float> = [0, 0];
	public var girlfriendCameraOffset:Array<Float> = [0, 0];
	
	/**
	 * The shown difficulty in the discord RPC.
	 * 
	 * Can be manually changed.
	 */
	var rpcDifficulty:String = '';
	
	/**
	 * The shown description in the discord RPC.
	 * 
	 * Can be manually changed.
	 */
	var rpcDescription:String = '';
	
	/**
	 * The shown paused Description in the discord RPC.
	 * 
	 * Can be manually changed.
	 */
	var rpcPausedDescription:String = '';
	
	/**
	 * The shown song name in the discord RPC.
	 * 
	 * Can be manually changed.
	 */
	var rpcSongName:String = '';
	
	/**
	 * Variable that determines whether PlayState will automatically handle Discord RPC.
	 *
	 * Useful for if you want custom Discord RPC messages and PlayState gets in the way.
	**/
	public var automatedDiscord:Bool = true;
	
	/**
	 * Group of general scripts.
	 */
	public var scripts:ScriptGroup;
	
	/**
	 * Group of note type scripts. these have some special functions for their use
	 */
	public var noteTypeScripts:ScriptGroup;
	
	/**
	 * Group of event scripts. these have some special functions for their use
	 */
	public var eventScripts:ScriptGroup;
	
	public var introSoundsSuffix:String = '';
	
	// Debug buttons
	var debugKeysChart:Array<FlxKey>;
	var debugKeysCharacter:Array<FlxKey>;
	
	// public var controlHoldArray:Array<Dynamic>;
	
	/**
	 * once set to a target, the camera will only follow them.
	 */
	public var camCurTarget:Null<Character> = null;
	
	public var playHUD:Null<BaseHUD> = null;
	
	public var countdownPrefix:String = Paths.COUNTDOWN_PREFIX;
	
	/**
	 * Called when the Song should start
	 * 
	 * Change this to set custom behavior
	 * 
	 * Generally though your custom callback Should end with `startCountdown` to start the song
	 */
	public var songStartCallback:Null<Void->Void> = null;
	
	/**
	 * Called when the Song should end
	 * 
	 * Change this to set custom behavior
	 */
	public var songEndCallback:Null<Void->Void> = null;
	
	@:noCompletion public function set_cpuControlled(val:Bool):Bool
	{
		if (playFields != null && playFields.members.length != 0)
		{
			for (field in playFields.members)
			{
				if (field.isPlayer) field.autoPlayed = val;
			}
		}
		return (cpuControlled = val);
	}
	
	function applyStageData(file:Null<StageFile>):Void
	{
		if (file == null) return;
		
		defaultCamZoom = file.defaultZoom;
		FlxG.camera.zoom = file.defaultZoom;
		
		BF_X = file.boyfriend[0];
		BF_Y = file.boyfriend[1];
		
		GF_X = file.girlfriend[0];
		GF_Y = file.girlfriend[1];
		
		DAD_X = file.opponent[0];
		DAD_Y = file.opponent[1];
		
		if (file.camera_speed != null) cameraSpeed = file.camera_speed;
		
		boyfriendCameraOffset = file.camera_boyfriend ?? [0, 0];
		
		opponentCameraOffset = file.camera_opponent ?? [0, 0];
		
		girlfriendCameraOffset = file.camera_girlfriend ?? [0, 0];
		
		boyfriendGroup ??= new CharacterGroup(BF_X, BF_Y, BF);
		dadGroup ??= new CharacterGroup(DAD_X, DAD_Y, DAD);
		gfGroup ??= new CharacterGroup(GF_X, GF_Y, GF);
		
		boyfriendGroup.zIndex = file.bfZIndex ?? 0;
		dadGroup.zIndex = file.dadZIndex ?? 0;
		gfGroup.zIndex = file.gfZIndex ?? 0;
	}
	
	// null checking
	function callHUDFunc(hud:BaseHUD->Void):Void if (playHUD != null) hud(playHUD);
	
	var input:InputSystem;
	
	override public function create():Void
	{
		FlxG.sound.music?.stop();
		
		FunkinAssets.cache.clearStoredMemory();
		
		funkin.backend.DebugDisplay.addPlugin(() -> 'curStep: $curStep • curBeat: $curBeat • curSection: $curSection');
		
		skipCountdown = false;
		countdownSounds = true;
		
		instance = this;
		
		GameOverSubstate.resetVariables();
		
		scripts = new ScriptGroup(this);
		eventScripts = new ScriptGroup(this);
		noteTypeScripts = new ScriptGroup(this);
		
		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; // Reset to default
		
		songStartCallback = startCountdown;
		songEndCallback = endSong;
		
		// If u have kutty enabled
		if (ClientPrefs.useEpicRankings) ratingsData.unshift(new Rating('epic'));
		
		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		
		camGame = new FlxCameraEx();
		camHUD = new FlxCameraEx();
		camOther = new FlxCameraEx();
		
		camHUD.bgColor = 0x0;
		camOther.bgColor = 0x0;
		
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		
		persistentUpdate = true;
		persistentDraw = true;
		
		SONG ??= Chart.fromPath(Paths.json('test/test'));
		
		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;
		
		arrowSkins = SONG.arrowSkins;
		
		// set up rpc stuff
		rpcDifficulty = '(' + Difficulty.getCurrentDifficultyString() + ')';
		rpcDescription = isStoryMode == true ? 'Story Mode:' : 'Freeplay:';
		rpcPausedDescription = 'Paused - ' + rpcDescription;
		rpcSongName = SONG.song;
		
		scripts.set('isStoryMode', isStoryMode);
		
		if (SONG.stage == null || SONG.stage.length == 0) SONG.stage = 'stage';
		
		stage = new Stage(SONG.stage);
		scripts.set('stage', stage);
		applyStageData(stage.stageData);
		
		stage.buildStage();
		
		if (stage.runScript(scripts))
		{
			scripts.addScript(stage.script);
			
			Logger.log('script: ' + stage.script.name + ' intialized');
		}
		
		if (scripts.call("onAddSpriteGroups", []) != ScriptConstants.STOP_FUNC)
		{
			add(stage);
			stage.add(gfGroup);
			stage.add(dadGroup);
			stage.add(boyfriendGroup);
		}
		
		inline function addSongScripts(directory)
		{
			for (file in Paths.listAllFilesInDirectory(directory).filter(path -> FunkinScript.isHxFile(path)))
			{
				final scriptPath = FunkinScript.getPath(file);
				
				initFunkinScript(file);
			}
		}
		addSongScripts('scripts');
		
		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1) SONG.gfVersion = gfVersion = 'gf';
		
		if (!stage.stageData.hide_girlfriend)
		{
			gf = new Character(gfVersion);
			gf.scrollFactor.set(0.95, 0.95);
			
			gfGroup.addChar(gf);
			gfGroup.parent = gf;
			startCharacterScript(gf.curCharacter, gf);
			
			scripts.set('gf', gf);
			scripts.set('gfGroup', gfGroup);
		}
		
		dad = new Character(SONG.player2);
		startCharacterScript(dad.curCharacter, dad);
		dadGroup.addChar(dad);
		dadGroup.parent = dad;
		
		boyfriend = new Character(SONG.player1, true);
		startCharacterScript(boyfriend.curCharacter, boyfriend);
		boyfriendGroup.addChar(boyfriend);
		boyfriendGroup.parent = boyfriend;
		
		scripts.set('dad', dad);
		scripts.set('dadGroup', dadGroup);
		
		scripts.set('boyfriend', boyfriend);
		scripts.set('boyfriendGroup', boyfriendGroup);
		
		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}
		else
		{
			camPos.set(opponentCameraOffset[0], opponentCameraOffset[1]);
			camPos.x += dad.getGraphicMidpoint().x + dad.cameraPosition[0];
			camPos.y += dad.getGraphicMidpoint().y + dad.cameraPosition[1];
		}
		
		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			if (gf != null) gf.visible = false;
		}
		
		Conductor.songPosition = -5000;
		
		playFields = new FlxTypedGroup<PlayField>();
		
		notes = new FlxTypedGroup<Note>();
		
		if (ClientPrefs.underlayType == 'Screen Dim')
		{
			screenDim = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			screenDim.alpha = ClientPrefs.underlayOpacity;
			screenDim.scrollFactor.set();
			screenDim.camera = camHUD;
			add(screenDim);
		}
		
		playHUD = new funkin.game.huds.PsychHUD(this);
		add(playHUD);
		playHUD.cameras = [camHUD];
		
		meta = SongMeta.getFromSong();
		
		modManager = new ModManager(this);
		
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();
		
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		
		add(camFollow);
		
		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();
		
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
		botplayTxt = new FlxText(400, 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.DEFAULT_FONT, 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		if (ClientPrefs.downScroll) botplayTxt.y = FlxG.height - botplayTxt.height - 55;
		add(botplayTxt);
		
		notes.cameras = [camHUD];
		playFields.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		
		addSongScripts('songs/${Paths.sanitize(SONG.song)}/');
		addSongScripts('songs/${Paths.sanitize(SONG.song)}/scripts/');
		
		scripts.call('preNoteGeneration', []);
		
		if (genNotesBeforeCountdown) generatePlayfields();
		generateSong(SONG.song);
		
		#if FLX_DEBUG
		FlxG.watch.addFunction('Conductor: ', () -> Conductor.songPosition);
		FlxG.watch.addFunction('SongTime: ', () -> FlxStringUtil.formatTime(Conductor.songPosition / 1000)
			+ ' / '
			+ FlxStringUtil.formatTime(audio.songLength / 1000));
			
		FlxG.watch.addFunction('curSec: ', () -> curSection);
		FlxG.watch.addFunction('curBeat: ', () -> curBeat);
		FlxG.watch.addFunction('curStep: ', () -> curStep);
		#end
		
		moveCameraSection();
		
		noteTypeMap?.clear();
		noteTypeMap = null;
		
		audio?.stop();
		
		startingSong = true;
		
		if (songStartCallback == null)
		{
			FlxG.log.error('songStartCallback is null! using default callback.');
			songStartCallback = startCountdown;
		}
		
		songStartCallback();
		
		RecalculateRating();
		updateScoreBar();
		
		if (ClientPrefs.hitsoundVolume > 0) Paths.sound('hitsound');
		Paths.sound('missnote1');
		Paths.sound('missnote2');
		Paths.sound('missnote3');
		
		if (PauseSubState.songName != null) Paths.music(PauseSubState.songName);
		else Paths.music(Paths.sanitize('breakfast'));
		
		// Updating Discord Rich Presence.
		resetDiscordRPC();
		
		input = new InputSystem(controls);
		input.addEventListener(InputEvent.INPUT_PRESSED, onInputPress);
		input.addEventListener(InputEvent.INPUT_RELEASED, onInputRelease);
		
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		
		scripts.call('onCreatePost', []);
		
		callHUDFunc(hud -> hud.cachePopUpScore());
		
		super.create();
		
		FunkinAssets.cache.clearUnusedMemory();
		
		refreshZ(stage);
	}
	
	function set_songSpeed(value:Float):Float
	{
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrotchet, 350 / songSpeed * playbackRate);
		return value;
	}
	
	public function addCharacterToList(newCharacter:String, type:Int):Void
	{
		final group = switch (type)
		{
			case 1:
				dadGroup;
			case 2:
				(gf != null) ? gfGroup : dadGroup;
			default:
				boyfriendGroup;
		}
		final newCharacter = group.addToList(newCharacter);
		startCharacterScript(newCharacter.curCharacter, newCharacter);
	}
	
	function startCharacterScript(name:String, char:Character):Void
	{
		var hscriptPath = FunkinScript.getPath('data/characters/$name');
		if (!FunkinAssets.exists(hscriptPath, TEXT)) hscriptPath = FunkinScript.getPath('characters/$name');
		
		if (FunkinAssets.exists(hscriptPath, TEXT))
		{
			var script = initFunkinScript(hscriptPath);
			
			script.set('parent', char);
		}
	}
	
	/**
	 * Creates a new `FunkinScript` from filepath and calls `onLoad`. Returns `null` if it couldnt be found
	 * @param name sets a custom name to the script
	 */
	public function initFunkinScript(filePath:String, ?name:String):Null<FunkinScript>
	{
		if (scripts.exists(name ?? filePath)) return null;
		
		var script:FunkinScript = FunkinScript.fromFile(filePath, name, scripts.scriptShareables);
		if (script.__garbage)
		{
			script = FlxDestroyUtil.destroy(script);
			return null;
		}
		Logger.log('script: ' + filePath + ' intialized');
		if (script.exists('onLoad')) script.call('onLoad');
		scripts.addScript(script);
		return script;
	}
	
	public var skipArrowStartTween:Bool = false;
	
	var splashLayering:Array<Dynamic> = [];
	
	public var screenDim:Null<FlxSprite>; // this doesnt need to be apart of playstate
	
	public function generatePlayfields()
	{
		if (generatedFields) return;
		
		if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;
		
		for (lane in 0...SONG.lanes)
		{
			final character = (lane == 1 ? dad : boyfriend);
			final isPlayer = (lane != 1);
			
			final auto = (lane != 0 || cpuControlled);
			
			var strums = new PlayField(0, 0, SONG.keys, character, isPlayer, auto, lane, arrowSkins[lane]);
			// strums.scale = NoteUtil.getSkinFromID(lane).scale;
			scripts.call('preReceptorGeneration', [strums, lane]);
			strums.generateReceptors();
			strums.fadeIn(isStoryMode || skipArrowStartTween);
			strums.ID = lane;
			
			playFields.add(strums);
			
			strums.onNoteHit.add((note, field) -> {
				if (field.ID == 1) camZooming = true;
				
				if (field.playerControls || (!audio.splitVocals && !audio.trackSwap)) audio.hit();
				
				if (field.playerControls && field.showRatings && !note.isSustainNote)
				{
					combo += 1;
					if (combo > 9999) combo = 9999;
					popUpScore(note);
				}
			});
			
			inline function actualMiss()
			{
				if (combo > 5 && gf != null && gf.animOffsets.exists('sad')) gf.playAnimForDuration('sad', 1, true);
				combo = 0;
				audio.miss();
				
				if (instakillOnMiss) doDeathCheck(true);
				
				songMisses++;
				if (!practiceMode) songScore -= 10;
				
				totalPlayed++;
				RecalculateRating(true);
			}
			
			strums.onNoteMiss.add((note, field) -> {
				if (!note.canMiss && field.playerControls && !note.blockHit) actualMiss();
			});
			strums.onMissPress.add((key) -> {
				actualMiss();
			});
			
			strums.showRatings = true;
			strums.noteSplashes = (lane == 0);
			
			final splashGrp = strums.splashLayer;
			splashGrp.camera = camHUD;
			splashLayering.push(splashGrp);
			
			if (lane == 1)
			{
				if (!ClientPrefs.opponentStrums) strums.baseAlpha = 0;
				else if (ClientPrefs.middleScroll) strums.baseAlpha = 0.35;
			}
		}
		
		// this broke a lot so im adding it back sorry data
		scripts.set('playerStrums', playerStrums);
		scripts.set('opponentStrums', opponentStrums);
		
		modManager.receptors = [for (i in playFields) i.members];
		
		modManager.lanes = SONG.lanes;
		modManager.keys = SONG.keys;
		
		generatedFields = true;
		scripts.call('postReceptorGeneration');
		
		modManager.registerEssentialModifiers();
		modManager.registerDefaultModifiers();
		modManager.registerScriptedModifiers();
		modifiersRegistered = true;
		
		scripts.call('postModifierRegister');
	}
	
	var startTimer:FlxTimer = null;
	var finishTimer:FlxTimer = null;
	
	public var countdownReady:Null<FlxSprite> = null;
	public var countdownSet:Null<FlxSprite> = null;
	public var countdownGo:Null<FlxSprite> = null;
	
	public function startCountdown():Void
	{
		if (startedCountdown)
		{
			scripts.call('onStartCountdown', []);
			return;
		}
		
		inCutscene = false;
		
		final ret:Dynamic = scripts.call('onStartCountdown', []);
		
		if (ret != ScriptConstants.STOP_FUNC)
		{
			// if its not 0 we can assume this was manually triggered
			if (!genNotesBeforeCountdown) generatePlayfields();
			
			new FlxTimer().start(countdownDelay, (t:FlxTimer) -> {
				startedCountdown = true;
				Conductor.songPosition = 0;
				Conductor.songPosition -= Conductor.crotchet * 5;
				scripts.call('onCountdownStarted', []);
				
				var swagCounter:Int = 0;
				
				if (startOnTime < 0) startOnTime = 0;
				
				if (startOnTime > 0)
				{
					clearNotesBefore(startOnTime);
					setSongTime(startOnTime - 350);
					return;
				}
				else if (skipCountdown)
				{
					setSongTime(0);
					return;
				}
				
				startTimer = new FlxTimer().start((Conductor.crotchet / 1000) / playbackRate, function(tmr:FlxTimer) {
					handleBoppers(tmr.loopsLeft);
					
					var introAlts:Array<String> = ['ready', 'set', 'go'];
					var antialias:Bool = ClientPrefs.globalAntialiasing;
					
					switch (swagCounter)
					{
						case 0:
							if (countdownSounds) FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						case 1:
							countdownReady = makeCountdownSprite(introAlts[0]);
							insert(members.indexOf(notes), countdownReady);
							
							if (countdownSounds) FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						case 2:
							countdownSet = makeCountdownSprite(introAlts[1]);
							insert(members.indexOf(notes), countdownSet);
							
							if (countdownSounds) FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						case 3:
							countdownGo = makeCountdownSprite(introAlts[2]);
							
							insert(members.indexOf(notes), countdownGo);
							
							if (countdownSounds) FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
							
						case 4:
					}
					
					scripts.call('onCountdownTick', [swagCounter]);
					
					swagCounter += 1;
				}, 5);
			});
		}
	}
	
	function makeCountdownSprite(path:String):FlxSprite
	{
		final pref = countdownPrefix != Paths.COUNTDOWN_PREFIX ? countdownPrefix : Paths.COUNTDOWN_PREFIX;
		
		final spr = new FlxSprite().loadGraphic(Paths.image(pref + path));
		spr.scrollFactor.set();
		spr.updateHitbox();
		
		spr.screenCenter();
		spr.antialiasing = ClientPrefs.globalAntialiasing;
		
		spr.cameras = [camHUD];
		
		FlxTween.tween(spr, {alpha: 0}, Conductor.crotchet / 1000 / playbackRate,
			{
				ease: FlxEase.cubeInOut,
				onComplete: function(twn:FlxTween) {
					remove(spr, true);
					spr.destroy();
				}
			});
		return spr;
	}
	
	inline function disposeNote(note:Note):Void
	{
		if (note.exists)
		{
			note.garbage = true;
			
			notes.remove(note, true);
			note.destroy();
		}
	}
	
	public function clearNotesBefore(time:Float):Void
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				
				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}
		
		i = notes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				
				disposeNote(daNote);
			}
			--i;
		}
	}
	
	public function setSongTime(time:Float):Void
	{
		if (time < 0) time = 0;
		
		audio.pause();
		audio.time = time;
		#if FLX_PITCH audio.pitch = playbackRate; #end
		audio.play();
		
		audio.hit();
		
		Conductor.songPosition = time;
		songTime = time;
	}
	
	var songTime:Float = 0;
	
	function startSong():Void
	{
		startingSong = false;
		
		audio.inst.onComplete = finishSong.bind(false);
		
		#if FLX_PITCH
		audio.pitch = playbackRate;
		#end
		
		if (startOnTime > 0) setSongTime(startOnTime - 500);
		startOnTime = 0;
		
		if (paused) audio.pause();
		
		songLength = audio.songLength;
		
		audio.volume = 1 * volumeMult;
		audio.play();
		
		// Updating Discord Rich Presence (with Time Left)
		if (automatedDiscord) DiscordClient.changePresence(rpcDescription, rpcSongName + ' ' + rpcDifficulty, null, true, songLength);
		
		scripts.set('songLength', songLength);
		scripts.call('onSongStart', []);
		callHUDFunc(hud -> hud.onSongStart());
	}
	
	var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	var eventsPushed:Array<String> = [];
	var noteTypesPushed:Array<String> = [];
	
	var _parsedEvents:Null<Array<EventNote>> = null;
	
	/**
	 * returns all events from both the loaded chart and events json
	 * 
	 * these are not sorted
	 */
	function getEventsDirect():Array<EventNote>
	{
		if (_parsedEvents != null) return _parsedEvents;
		
		final events:Array<EventNote> = [];
		
		final songName:String = Paths.sanitize(SONG.song);
		
		var file:String = Paths.json('$songName/charts/events');
		if (!FunkinAssets.exists(file)) file = Paths.json('$songName/data/events');
		
		inline function makeEv(time:Float, ev:String, v1:String, v2:String)
		{
			final ev:EventNote =
				{
					strumTime: time + ClientPrefs.noteOffset,
					event: ev,
					value1: v1,
					value2: v2
				};
				
			var isCopy:Bool = false;
			
			for (event in events)
			{
				if (FlxMath.equal(event.strumTime, ev.strumTime) && event.event == ev.event && event.value1 == ev.value1 && event.value2 == ev.value2)
				{
					isCopy = true;
					
					break;
				}
			}
			
			if (!isCopy) events.push(ev);
		}
		
		if (FunkinAssets.exists(file))
		{
			final eventsData:Array<Dynamic> = Chart.fromPath(file).events;
			
			for (event in eventsData) // Event Notes
			{
				for (i in 0...event[1].length)
				{
					makeEv(event[0], event[1][i][0], event[1][i][1], event[1][i][2]);
				}
			}
		}
		
		for (event in SONG.events) // Event Notes
		{
			for (i in 0...event[1].length)
				makeEv(event[0], event[1][i][0], event[1][i][1], event[1][i][2]);
		}
		
		return (_parsedEvents = events);
	}
	
	function generateSong(dataPath:String):Void
	{
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype', 'multiplicative');
		
		songSpeed = SONG.speed;
		
		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}
		
		final songData = SONG;
		Conductor.bpm = songData.bpm;
		
		curSong = songData.song;
		
		audio = new PlayableSong();
		audio.populate(SONG);
		audio.hit();
		add(audio);
		
		#if FLX_PITCH
		audio.pitch = playbackRate;
		#end
		
		audio.volume = 0;
		
		audio.play();
		audio.pause();
		
		scripts.set('vocals', audio);
		scripts.set('inst', audio.inst);
		
		add(playFields);
		add(notes);
		
		for (i in splashLayering)
			add(i);
			
		final noteData:Array<SongSection> = songData.notes;
		
		// loads note types
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var type:Dynamic = songNotes[3];
				if (!Std.isOfType(type, String)) type = OLDChartEditorState.noteTypeList[type];
				
				if (!noteTypeMap.exists(type)) noteTypeMap.set(type, true);
			}
		}
		
		for (type in noteTypeMap.keys())
		{
			if (!noteTypesPushed.contains(type))
			{
				var baseScriptFile = 'data/notetypes/$type';
				if (!FunkinAssets.exists(FunkinScript.getPath(baseScriptFile), TEXT)) baseScriptFile = 'notetypes/$type';
				
				final scriptFile = FunkinScript.getPath(baseScriptFile);
				
				if (FunkinAssets.exists(scriptFile, TEXT)) noteTypeScripts.addScript(initFunkinScript(scriptFile, type));
				
				noteTypesPushed.push(type);
			}
		}
		
		var events = getEventsDirect();
		
		var lastPlayfieldNotes:Array<Array<Note>> = [for (i in 0...songData.lanes) [for (i in 0...songData.keys) null]];
		noteRows = [for (i in 0...songData.lanes) []];
		
		#if debug
		var cpuTime = Sys.time();
		#end
		
		var holdCrotchet:Float = Math.max(Conductor.stepCrotchet / holdSubdivisions, 10);
		
		for (section in noteData)
		{
			if (section.changeBPM) holdCrotchet = (15000 / section.bpm / holdSubdivisions);
			
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % SONG.keys);
				var playfield:Int = 0;
				
				playfield = Std.int(songNotes[1] / SONG.keys);
				
				if (playfield < 0) // legacy event notes
				{
					events.push(
						{
							strumTime: daStrumTime + ClientPrefs.noteOffset,
							event: songNotes[2],
							value1: songNotes[3],
							value2: songNotes[4]
						});
						
					continue;
				}
				
				if (playfield >= SONG.lanes) continue;
				
				var realTime = daStrumTime - ClientPrefs.noteOffset,
					last:Note = lastPlayfieldNotes[playfield][daNoteData];
				if (last != null && Math.abs(realTime - last.strumTime) <= 3) continue;
				
				var oldNote:Note = null;
				
				var type:Dynamic = songNotes[3];
				if (!Std.isOfType(type, String)) type = OLDChartEditorState.noteTypeList[type];
				
				// TODO: maybe make a checkNoteType n shit but idfk im lazy
				// or maybe make a "Transform Notes" event which'll make notes which don't change texture change into the specified one
				
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, playfield);
				swagNote.row = Conductor.secsToRow(daStrumTime);
				swagNote.mustPress = (playfield == 0);
				swagNote.sustainLength = songNotes[2];
				
				var rowArray = noteRows[playfield];
				rowArray[swagNote.row] ??= [];
				rowArray[swagNote.row].push(swagNote);
				
				lastPlayfieldNotes[playfield][daNoteData] = swagNote;
				
				swagNote.lane = playfield;
				
				swagNote.gfNote = ((section.gfSection == swagNote.mustPress) && (songNotes[1] < SONG.keys));
				
				swagNote.noteType = type;
				
				if ((section?.altAnim ?? false) && (type == '' || type == null)) swagNote.noteType = 'Alt Animation';
				
				swagNote.scrollFactor.set();
				
				var susLength:Float = swagNote.sustainLength;
				
				susLength = (susLength / holdCrotchet);
				swagNote.ID = unspawnNotes.length;
				unspawnNotes.push(swagNote);
				
				callNoteTypeScript(swagNote.noteType, 'setupNote', [swagNote]);
				
				// floored but rounded????
				final flooredSusLength = Math.round(susLength);
				
				if (flooredSusLength <= 0) continue;
				
				for (susNote in 0...flooredSusLength + 1)
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					
					var sustainNote:Note = new Note(daStrumTime + (holdCrotchet * susNote), daNoteData, oldNote, true, false, playfield);
					sustainNote.visualLength = (getNoteInitialTime(sustainNote.strumTime + holdCrotchet) - sustainNote.visualTime);
					sustainNote.sustainLength = holdCrotchet;
					sustainNote.mustPress = (playfield == 0);
					sustainNote.gfNote = swagNote.gfNote;
					sustainNote.noteType = swagNote.noteType;
					
					if (!swagNote.hitCausesMiss && !swagNote.canMiss) sustainNote.blockHit = true; // stops you from holding a note without key pressing first
					if (!sustainNote.alive) break;
					
					sustainNote.ID = unspawnNotes.length;
					sustainNote.scrollFactor.set();
					sustainNote.lane = swagNote.lane;
					swagNote.tail.push(sustainNote);
					sustainNote.parent = swagNote;
					
					unspawnNotes.push(sustainNote);
					
					callNoteTypeScript(sustainNote.noteType, 'setupNote', [sustainNote]);
				}
			}
		}
		
		for (event in events)
		{
			final eventName = event.event;
			
			if (!eventsPushed.contains(eventName))
			{
				var baseScriptFile:String = 'data/events/$eventName';
				if (!FunkinAssets.exists(FunkinScript.getPath(baseScriptFile), TEXT)) baseScriptFile = 'events/$eventName';
				
				final scriptFile = FunkinScript.getPath(baseScriptFile);
				
				if (FunkinAssets.exists(scriptFile, TEXT)) eventScripts.addScript(initFunkinScript(scriptFile, eventName));
				
				firstEventPush(event);
				
				eventsPushed.push(eventName);
			}
			
			event.strumTime -= eventNoteEarlyTrigger(event);
			eventNotes.push(event);
			eventPushed(event);
		}
		
		// No need to sort if there's a single one or none at all
		if (eventNotes.length > 1) eventNotes.sort(SortUtil.sortByTime);
		
		speedChanges.sort(SortUtil.svSort);
		
		#if debug
		trace('loading chart took: ' + (Sys.time() - cpuTime));
		#end
		
		lastPlayfieldNotes = null;
		
		unspawnNotes.sort(SortUtil.sortByStrumTime);
		
		checkEventNote();
		generatedMusic = true;
	}
	
	public function getNoteInitialTime(time:Float):Float
	{
		return getTimeFromSV(time, getSV(time));
	}
	
	public inline function getTimeFromSV(time:Float, event:SpeedEvent):Float return event.position
		+ (modManager.getBaseVisPosD(time - event.songTime, 1) * event.speed);
		
	public function getSV(time:Float):SpeedEvent
	{
		var event:SpeedEvent = {};
		
		for (shit in speedChanges)
		{
			if (shit.startTime <= time && shit.startTime >= event.startTime)
			{
				if (shit.startSpeed == null) shit.startSpeed = event.speed;
				event = shit;
			}
		}
		
		return event;
	}
	
	public inline function getVisualPosition() return getTimeFromSV(Conductor.songPosition, currentSV);
	
	function eventPushed(event:EventNote):Void
	{
		switch (event.event)
		{
			case 'Mult SV' | 'Constant SV':
				var speed:Float = 1;
				if (event.event == 'Constant SV')
				{
					var b = Std.parseFloat(event.value1);
					speed = Math.isNaN(b) ? songSpeed : (songSpeed / b);
				}
				else
				{
					speed = Std.parseFloat(event.value1);
					if (Math.isNaN(speed)) speed = 1;
				}
				
				speedChanges.sort(SortUtil.svSort);
				speedChanges.push(
					{
						position: getNoteInitialTime(event.strumTime),
						songTime: event.strumTime,
						startTime: event.strumTime,
						speed: speed
					});
			case 'Change Noteskin':
				var fieldID:Int = 0;
				switch (event.value2.toLowerCase())
				{
					case 'dad' | 'opponent' | '1':
						fieldID = 1;
					default:
						fieldID = Std.parseInt(event.value1);
						if (Math.isNaN(fieldID)) fieldID = 0;
				}
				
				var skin = new NoteSkin(event.value1, SONG.keys, fieldID);
				
				// load the skin so game no lag when change le skin
				Paths.getAtlasFrames(skin.noteTexture);
				Paths.getAtlasFrames(skin.splashTexture);
				Paths.getAtlasFrames(skin.sustainSplashTexture);
				
				skin = FlxDestroyUtil.destroy(skin);
			case 'Change Character':
				var charType:Int = 0;
				switch (event.value1.toLowerCase())
				{
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if (Math.isNaN(charType)) charType = 0;
				}
				
				addCharacterToList(event.value2, charType);
			default:
				callEventScript(event.event, 'onPush', [event]);
		}
		scripts.call('onEventPush', [event]);
	}
	
	function firstEventPush(event:EventNote):Void
	{
		switch (event.event)
		{
			default:
				callEventScript(event.event, 'onFirstPush', [event]);
		}
	}
	
	function eventNoteEarlyTrigger(event:EventNote):Float
	{
		var returnValue:Dynamic = scripts.call('eventEarlyTrigger', [event.event, event.value1, event.value2]);
		if (returnValue != ScriptConstants.CONTINUE_FUNC) return returnValue;
		
		returnValue = callEventScript(event.event, 'offsetStrumTime', [event]);
		if (returnValue != ScriptConstants.CONTINUE_FUNC) return returnValue;
		
		switch (event.event)
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		
		return 0;
	}
	
	override function openSubState(SubState:FlxSubState):Void
	{
		if (paused)
		{
			if (audio != null) audio.pause();
			
			FlxTimer.globalManager.forEach((i:FlxTimer) -> if (!i.finished) i.active = false);
			FlxTween.globalManager.forEach((i:FlxTween) -> if (!i.finished) i.active = false);
			
			#if VIDEOS_ALLOWED
			FunkinVideoSprite.forEachAlive((video) -> if (video.tiedToGame) video.pause());
			#end
			
			for (field in playFields?.members)
			{
				if (field.inControl && field.playerControls)
				{
					for (strum in field.members)
					{
						if (strum.animation.curAnim?.name != 'static')
						{
							strum.playAnim('static');
							strum.resetAnim = 0;
						}
					}
				}
			}
		}
		scripts.call('onSubstateOpen', []);
		super.openSubState(SubState);
	}
	
	override function closeSubState():Void
	{
		if (paused)
		{
			if (audio.inst != null && !startingSong) resyncVocals();
			
			FlxTimer.globalManager.forEach((i:FlxTimer) -> if (!i.finished) i.active = true);
			FlxTween.globalManager.forEach((i:FlxTween) -> if (!i.finished) i.active = true);
			
			#if VIDEOS_ALLOWED
			FunkinVideoSprite.forEachAlive((video) -> if (video.tiedToGame) video.resume());
			#end
			
			paused = false;
			scripts.call('onResume', []);
			
			resetDiscordRPC(startTimer != null && startTimer.finished);
		}
		scripts.call('onSubstateClose', []);
		super.closeSubState();
	}
	
	override public function onFocus():Void
	{
		if (!isDead && !paused) resetDiscordRPC(Conductor.songPosition > 0.0);
		
		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		if (!isDead && !paused) resetDiscordRPC(false);
		
		super.onFocusLost();
	}
	
	/**
	 * Sets the Discord RPC to display the default in song descriptions.
	 * @param showTime if showTime, the RPC will show the current song progress.
	 */
	inline function resetDiscordRPC(showTime:Bool = false)
	{
		if (!automatedDiscord) return;
		
		if (!showTime) DiscordClient.changePresence(rpcDescription, rpcSongName + ' ' + rpcDifficulty);
		else DiscordClient.changePresence(rpcDescription, rpcSongName + ' ' + rpcDifficulty, null, true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
	}
	
	function resyncVocals():Void
	{
		if (finishTimer != null) return;
		
		audio.pitch = playbackRate;
		audio.volume = 1 * volumeMult;
		audio.pause();
		audio.time = audio.inst.time;
		Conductor.songPosition = audio.inst.time;
		#if FLX_PITCH audio.pitch = playbackRate; #end
		audio.play();
	}
	
	public var canAccessEditors:Bool = true;
	
	public var paused:Bool = false;
	public var canReset:Bool = true;
	
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	
	override public function update(elapsed:Float):Void
	{
		if (cameraLerping && !inCutscene)
		{
			final lerpRate = 0.04 * cameraSpeed * playbackRate;
			FlxG.camera.followLerp = lerpRate;
		}
		
		if (generatedMusic && !endingSong && !isCameraOnForcedPos) moveCameraSection();
		
		scripts.call('onUpdate', [elapsed]);
		
		super.update(elapsed);
		input.update();
		
		if (controls.PAUSE && startedCountdown && canPause)
		{
			if (scripts.call('onPause', []) != ScriptConstants.STOP_FUNC) openPauseMenu();
		}
		
		if (canAccessEditors && !endingSong && !inCutscene)
		{
			if (FlxG.keys.anyJustPressed(debugKeysChart)) openChartEditor();
			
			if (FlxG.keys.anyJustPressed(debugKeysCharacter)) openCharacterEditor();
		}
		
		if (healthBounds.max > healthBounds.min && health > healthBounds.max) health = healthBounds.max;
		else if (healthBounds.min > healthBounds.max && healthBounds.max > health) health = healthBounds.max;
		
		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
				if (Conductor.songPosition >= 0) startSong();
			}
		}
		else
		{
			var deltaTime:Float = elapsed * 1000 * playbackRate;
			if (audio.time == Conductor.lastSongPos) Conductor.songPosition += deltaTime;
			else
			{
				if (Math.abs(audio.time - Conductor.songPosition) >= deltaTime) Conductor.songPosition = audio.time;
				else Conductor.songPosition += deltaTime;
				
				Conductor.lastSongPos = audio.time;
			}
		}
		
		currentSV = getSV(Conductor.songPosition);
		Conductor.visualPosition = getVisualPosition();
		
		checkEventNote();
		
		if (camZooming)
		{
			FlxG.camera.zoom = MathUtil.decayLerp(FlxG.camera.zoom, defaultCamZoom + defaultCamZoomAdd, 6.25 * camZoomingDecay, elapsed);
			camHUD.zoom = MathUtil.decayLerp(camHUD.zoom, defaultHudZoom, 6.25 * camZoomingDecay, elapsed);
		}
		
		if (!ClientPrefs.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong) health = 0;
		
		doDeathCheck();
		
		if (modifiersRegistered)
		{
			modManager.updateTimeline(curDecStep);
			modManager.update(elapsed);
		}
		
		final spawnOffset:Float = (spawnTime * playbackRate / (songSpeed < 1 ? songSpeed : 1));
		
		while (unspawnNotes.length > 0 && (unspawnNotes[0].strumTime - Conductor.songPosition) < spawnOffset)
		{
			final dunceNote:Note = unspawnNotes.shift();
			
			var doSpawn:Bool = (callNoteTypeScript(dunceNote.noteType, 'spawnNote', [dunceNote]) != ScriptConstants.STOP_FUNC);
			if (doSpawn) doSpawn = (scripts.call('onSpawnNote', [dunceNote], false, [dunceNote.noteType]) != ScriptConstants.STOP_FUNC);
			
			final expectedPlayfield:Null<PlayField> = (doSpawn ? (getFieldFromID(dunceNote.lane) ?? dunceNote.parent?.playField) : null);
			
			if (expectedPlayfield == null)
			{
				for (note in dunceNote.tail)
				{
					unspawnNotes.remove(note);
					note.destroy();
				}
				
				dunceNote.destroy();
				
				continue;
			}
			
			expectedPlayfield.addNote(dunceNote);
			notes.insert(0, dunceNote);
			dunceNote.spawned = true;
			
			var ret:Dynamic = callNoteTypeScript(dunceNote.noteType, 'postSpawnNote', [dunceNote]);
			if (ret != ScriptConstants.STOP_FUNC) scripts.call('onSpawnNotePost', [dunceNote], false, [dunceNote.noteType]);
		}
		
		var tempVector = funkin.backend.math.Vector3.get();
		
		final canUpdateModchart:Bool = (modifiersRegistered && playFields != null);
		
		inline function modchart(obj:Dynamic, id:Int, offsets:haxe.ds.Vector<FlxPoint>)
		{
			final pos = modManager.getPos(0, 0, 0, curDecBeat, obj.noteData, id, obj, tempVector);
			final offsets = (offsets != null ? offsets[obj.noteData] : null);
			
			modManager.updateObject(curDecBeat, obj, pos, id);
			
			obj.spriteOffset.set(offsets?.x, offsets?.y);
			
			return pos;
		}
		
		if (canUpdateModchart)
		{
			for (playField in playFields)
			{
				final id = playField.ID, skin = playField._skin;
				
				playField.forEachAlive(function(strum) modchart(strum, id, skin.receptorOffsets));
			}
		}
		
		if (generatedMusic)
		{
			if (!inCutscene)
			{
				if (!cpuControlled) keyShit();
				else if (boyfriend.holdTimer > Conductor.stepCrotchet * 0.0011 * boyfriend.singDuration
					&& boyfriend.getAnimName().startsWith('sing')
					&& !boyfriend.getAnimName().endsWith('miss')) boyfriend.dance(boyfriend.forceDance);
			}
			
			var i:Int = notes.length;
			while (--i >= 0)
			{
				var daNote = notes.members[i];
				
				final field = daNote.playField;
				
				if (field.inControl && field.autoPlayed)
				{
					if (!daNote.wasGoodHit && !daNote.ignoreNote && daNote.strumTime <= Conductor.songPosition) field.onNoteHit.dispatch(daNote, field);
				}
				
				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
				{
					daNote.garbage = true;
					if (daNote.playField != null && daNote.playField.playerControls && !daNote.playField.autoPlayed && !daNote.ignoreNote
						&& !daNote.canMiss && !endingSong && !daNote.wasGoodHit && field.playerControls && !field.autoPlayed) field.onNoteMiss.dispatch(daNote, field);
				}
				
				if (daNote.garbage)
				{
					disposeNote(daNote);
					
					continue;
				}
				
				if (!canUpdateModchart || !daNote.exists) continue; // ok modchart stuff
				
				final _skin = NoteUtil.getSkinFromID(daNote.player);
				
				final visPos = ((daNote.visualTime - Conductor.visualPosition) * songSpeed);
				final diff = (daNote.strumTime - Conductor.songPosition);
				
				final pos = modManager.getPos(daNote.strumTime, visPos, diff, curDecBeat, daNote.noteData, daNote.lane, daNote, tempVector);
				
				modManager.updateObject(curDecBeat, daNote, pos, daNote.lane);
				
				daNote.spriteOffset.x = (_skin.noteOffsets[daNote.noteData].x + daNote.offsetX);
				daNote.spriteOffset.y = (_skin.noteOffsets[daNote.noteData].y + daNote.offsetY);
				
				if (daNote.isSustainNote)
				{
					final futureSongPos = Conductor.getBeat(Conductor.songPosition + daNote.sustainLength);
					
					final visPos = ((daNote.visualTime + daNote.visualLength - Conductor.visualPosition) * songSpeed);
					final diff = (daNote.strumTime + daNote.sustainLength - Conductor.songPosition);
					
					var nextPos = modManager.getPos(daNote.strumTime + daNote.sustainLength, visPos, diff, Conductor.getBeat(futureSongPos), daNote.noteData, daNote.lane, daNote);
					
					final rad = Math.atan2(nextPos.y - pos.y, nextPos.x - pos.x);
					
					final deg = (rad * 180 / Math.PI);
					
					daNote.angle = (deg - 90);
					
					if (daNote.wasGoodHit && daNote.parent?.sustainSplash != null && field.trackSustainSplashes) daNote.parent.sustainSplash.angle = daNote.angle;
					
					daNote.spriteOffset.x += _skin.sustainOffsets[daNote.noteData].x;
					daNote.spriteOffset.y += _skin.sustainOffsets[daNote.noteData].y;
					if (daNote.isSustainEnd)
					{
						daNote.spriteOffset.x += _skin.susEndOffsets[daNote.noteData].x;
						daNote.spriteOffset.y += _skin.susEndOffsets[daNote.noteData].y;
					}
					else
					{
						final dist:Float = Math.sqrt(Math.pow(pos.y - nextPos.y, 2) + Math.pow(pos.x - nextPos.x, 2));
						
						daNote.scale.y = daNote.baseScale.y = (dist / (daNote.frameHeight - (daNote.antialiasing ? 1 : 0)));
					}
					
					daNote.clip(daNote.playField.members[daNote.noteData]);
					
					nextPos.put();
				}
			}
		}
		
		if (canUpdateModchart)
		{
			for (playField in playFields)
			{
				final id = playField.ID, skin = playField._skin;
				
				playField.grpSusSplashes.forEachAlive(function(splash) modchart(splash, id, skin.sustainSplashOffsets));
				
				if (playField.trackNoteSplashes) playField.grpNoteSplashes.forEachAlive(function(splash) modchart(splash, id, skin.splashOffsets));
			}
		}
		
		tempVector.put();
		
		for (i in followingCams)
		{
			i.zoom = FlxG.camera.zoom;
			i.scroll.copyFrom(FlxG.camera.scroll);
		}
		
		if (#if debug true || #end chartingMode || ClientPrefs.inDevMode)
		{
			if (!endingSong && !startingSong)
			{
				if (FlxG.keys.justPressed.ONE)
				{
					KillNotes();
					audio.inst.onComplete();
				}
				if (FlxG.keys.justPressed.TWO)
				{
					setSongTime(Conductor.songPosition + 10000);
					clearNotesBefore(Conductor.songPosition);
				}
			}
			if (FlxG.keys.justPressed.SIX)
			{
				cpuControlled = !cpuControlled;
				botplayTxt.visible = !botplayTxt.visible;
			}
		}
		
		if (ClientPrefs.underlayType == 'Screen Dim' && screenDim != null)
		{
			screenDim.scale.set(FlxG.width * camHUD.zoom, FlxG.height * camHUD.zoom);
			screenDim.updateHitbox();
			screenDim.screenCenter();
		}
		
		scripts.call('onUpdatePost', [elapsed]);
	}
	
	function openPauseMenu():Void
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;
		
		if (audio.inst != null) audio.pause();
		openSubState(new PauseSubState());
		
		if (automatedDiscord) DiscordClient.changePresence(rpcPausedDescription, 'Paused');
	}
	
	function openChartEditor():Void
	{
		FlxG.camera.followLerp = 0;
		
		persistentUpdate = false;
		paused = true;
		CoolUtil.cancelMusicFadeTween();
		
		ChartEditorState.song = SONG;
		FlxG.switchState(FlxG.keys.pressed.SHIFT ? ChartEditorState.new : OLDChartEditorState.new);
		chartingMode = true;
		
		if (automatedDiscord) DiscordClient.changePresence('Chart Editor');
	}
	
	function openCharacterEditor():Void
	{
		FlxG.camera.followLerp = 0;
		
		persistentUpdate = false;
		paused = true;
		CoolUtil.cancelMusicFadeTween();
		
		FlxG.switchState(() -> new CharacterEditorState(SONG.player2, true));
		
		if (automatedDiscord) DiscordClient.changePresence("Character Editor", null, null, true);
	}
	
	public function updateScoreBar(miss:Bool = false):Void
	{
		if (scripts.call('onUpdateScore',
			[miss]) != ScriptConstants.STOP_FUNC) callHUDFunc(hud -> hud.onUpdateScore(songScore, funkin.utils.MathUtil.floorDecimal(ratingPercent * 100, 2), songMisses, miss));
	}
	
	public var isDead:Bool = false;
	
	function doDeathCheck(?skipHealthCheck:Bool = false):Bool
	{
		if ((skipHealthCheck && instakillOnMiss) || ((healthBounds.max > healthBounds.min && health <= healthBounds.min) || (healthBounds.min > healthBounds.max && health >= healthBounds.min)) && !practiceMode && !isDead)
		{
			final ret:Dynamic = scripts.call('onGameOver', []);
			if (ret != ScriptConstants.STOP_FUNC)
			{
				final char = playerStrums.owner;
				
				char.stunned = true;
				deathCounter++;
				
				paused = true;
				
				audio.stop();
				
				persistentUpdate = false;
				persistentDraw = false;
				
				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();
				
				openSubState(new GameOverSubstate(char));
				
				// Game Over doesn't get his own variable because it's only used here
				if (automatedDiscord) DiscordClient.changePresence("Game Over - " + rpcDescription, rpcSongName);
				
				isDead = true;
				
				return true;
			}
		}
		return false;
	}
	
	public function checkEventNote():Void
	{
		while (eventNotes.length > 0)
		{
			final leStrumTime:Float = eventNotes[0].strumTime;
			
			if (Conductor.songPosition < leStrumTime) break;
			
			final value1:String = eventNotes[0].value1 ?? '';
			final value2:String = eventNotes[0].value2 ?? '';
			
			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}
	
	function changeCharacter(name:String, charType:Int):Void
	{
		switch (charType)
		{
			case 0:
				boyfriend = boyfriendGroup.change(name);
			case 1:
				dad = dadGroup.change(name);
			case 2:
				gf = gfGroup.change(name);
				gf.danceEveryNumBeats *= gfSpeed;
		}
		
		scripts.set('boyfriend', boyfriend);
		scripts.set('boyfriendGroup', boyfriendGroup);
		
		scripts.set('dad', dad);
		scripts.set('dadGroup', dadGroup);
		
		scripts.set('gf', gf);
		scripts.set('gfGroup', gfGroup);
		
		callHUDFunc(hud -> hud.onCharacterChange());
	}
	
	public function triggerEventNote(eventName:String, value1:String, value2:String):Void
	{
		switch (eventName)
		{
			case 'Hey!':
				var value:Int = 2;
				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}
				
				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0) time = 0.6;
				
				if (value != 0)
				{
					if (dad.curCharacter.startsWith('gf'))
					{ // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnimForDuration('cheer', time);
						dad.specialAnim = true;
					}
					else if (gf != null)
					{
						gf.playAnimForDuration('cheer', time);
						gf.specialAnim = true;
					}
				}
				if (value != 1)
				{
					boyfriend.playAnimForDuration('hey', time);
					boyfriend.specialAnim = true;
				}
				
			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;
			case 'Add Camera Zoom':
				if (ClientPrefs.camZooms && FlxG.camera.zoom < 1.35)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom)) camZoom = 0.015;
					if (Math.isNaN(hudZoom)) hudZoom = 0.03;
					
					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}
				
			case 'Camera Zoom':
				FlxTween.cancelTweensOf(FlxG.camera, ['zoom']);
				
				var val1:Float = Std.parseFloat(value1);
				if (Math.isNaN(val1)) val1 = 1;
				
				var targetZoom = defaultCamZoom * val1;
				if (value2 != '')
				{
					var split = value2.split(',');
					var duration:Float = 0;
					var leEase:String = 'linear';
					if (split[0] != null) duration = Std.parseFloat(split[0].trim());
					if (split[1] != null) leEase = split[1].trim();
					if (Math.isNaN(duration)) duration = 0;
					
					if (duration > 0) FlxTween.tween(FlxG.camera, {zoom: targetZoom}, duration, {ease: FlxEase.circOut});
					else FlxG.camera.zoom = targetZoom;
				}
				defaultCamZoom = targetZoom;
				scripts.set('defaultCamZoom', defaultCamZoom);
				
			case 'HUD Fade':
				FlxTween.cancelTweensOf(camHUD, ['alpha']);
				
				var leAlpha:Float = Std.parseFloat(value1);
				if (Math.isNaN(leAlpha)) leAlpha = 1;
				
				var duration:Float = Std.parseFloat(value2);
				if (Math.isNaN(duration)) duration = 1;
				
				if (duration > 0) FlxTween.tween(camHUD, {alpha: leAlpha}, duration);
				else camHUD.alpha = leAlpha;
			case 'Camera Fade':
				FlxTween.cancelTweensOf(camGame, ['alpha']);
				
				var leAlpha:Float = Std.parseFloat(value1);
				if (Math.isNaN(leAlpha)) leAlpha = 1;
				
				var duration:Float = Std.parseFloat(value2);
				if (Math.isNaN(duration)) duration = 1;
				
				if (duration > 0) FlxTween.tween(camGame, {alpha: leAlpha}, duration);
				else camGame.alpha = leAlpha;
				
			case 'Play Animation':
				var char:Character = dad;
				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if (Math.isNaN(val2)) val2 = 0;
						
						switch (val2)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				
				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}
				
			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1)) val1 = 0;
				if (Math.isNaN(val2)) val2 = 0;
				
				isCameraOnForcedPos = false;
				if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
				{
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}
				
			case 'Alt Idle Animation':
				var char:Character = dad;
				switch (value1.toLowerCase())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val)) val = 0;
						
						switch (val)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				
				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}
				
			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null) duration = Std.parseFloat(split[0].trim());
					if (split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration)) duration = 0;
					if (Math.isNaN(intensity)) intensity = 0;
					
					if (duration > 0 && intensity != 0) targetsArray[i].shake(intensity, duration);
				}
			case 'Change Noteskin':
				var fieldID:Int = 0;
				switch (value2.toLowerCase())
				{
					case 'dad' | 'opponent' | '1':
						fieldID = 1;
					default:
						fieldID = Std.parseInt(value2);
						if (Math.isNaN(fieldID)) fieldID = 0;
				}
				
				var skin = new NoteSkin(value1, SONG.keys, fieldID);
				skin.ID = fieldID;
				
				getFieldFromID(fieldID).changeSkin(skin);
			// final field = getFieldFromID(ID)
			
			case 'Change Character':
				var charType:Int = 0;
				switch (value1)
				{
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
				}
				
				var curChar:Character = boyfriend;
				switch (charType)
				{
					case 2:
						curChar = gf;
					case 1:
						curChar = dad;
					case 0:
						curChar = boyfriend;
				}
				
				var newCharacter:String = value2;
				var anim:String = '';
				var frame:Int = 0;
				if (newCharacter.startsWith(curChar.curCharacter) || curChar.curCharacter.startsWith(newCharacter))
				{
					if (!curChar.isAnimNull())
					{
						anim = curChar.getAnimName();
						frame = curChar.animCurFrame;
					}
				}
				
				changeCharacter(value2, charType);
				if (anim != '')
				{
					var char:Character = boyfriend;
					switch (charType)
					{
						case 2:
							char = gf;
						case 1:
							char = dad;
						case 0:
							char = boyfriend;
					}
					
					if (!char.isAnimNull())
					{
						char.playAnim(anim, true);
						char.animCurFrame = frame;
					}
				}
			case 'Change Scroll Speed':
				if (songSpeedType == "constant") return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1)) val1 = 1;
				if (Math.isNaN(val2)) val2 = 0;
				
				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;
				
				if (val2 <= 0) songSpeed = newValue;
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate,
						{
							ease: FlxEase.linear,
							onComplete: function(twn:FlxTween) {
								songSpeedTween = null;
							}
						});
				}
				
			case 'Set Cam Zoom':
				defaultCamZoom = Std.parseFloat(value1);
				
			case 'Set Cam Pos':
				var split:Array<String> = value1.split(',');
				var xPos:Float = Std.parseFloat(split[0].trim());
				var yPos:Float = Std.parseFloat(split[1].trim());
				if (Math.isNaN(xPos)) xPos = 0;
				if (Math.isNaN(yPos)) yPos = 0;
				switch (value2)
				{
					case 'bf' | 'boyfriend':
						boyfriendCameraOffset[0] = xPos;
						boyfriendCameraOffset[1] = yPos;
					case 'gf' | 'girlfriend':
						girlfriendCameraOffset[0] = xPos;
						girlfriendCameraOffset[1] = yPos;
					case 'dad' | 'opponent':
						opponentCameraOffset[0] = xPos;
						opponentCameraOffset[1] = yPos;
				}
				
			case 'Set Property':
				try
				{
					var props:Array<String> = value1.split('.');
					if (props.length > 1) Reflect.setProperty(ReflectUtil.getPropertyLoop(props, true), props[props.length - 1], value2);
					else Reflect.setProperty(this, value1, value2);
				}
				catch (e)
				{
					Logger.log('Event [Set Property] failed Exception: ${e.toString()}', ERROR);
				}
		}
		
		scripts.call('onEvent', [eventName, value1, value2]);
		
		callEventScript(eventName, 'onTrigger', [value1, value2]);
	}
	
	function moveCameraSection():Void
	{
		if (SONG.notes[curSection] == null) return;
		
		if (gf != null && SONG.notes[curSection].gfSection)
		{
			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			
			if (ClientPrefs.camFollowsCharacters)
			{
				final displacement = gf.getSingDisplacement();
				
				camFollow.x += displacement.x;
				camFollow.y += displacement.y;
				
				displacement.putWeak();
			}
			
			scripts.call('onMoveCamera', ['gf']);
			scripts.set('whosTurn', 'gf');
			return;
		}
		
		var isDad = !SONG.notes[curSection].mustHitSection;
		moveCamera(isDad);
		scripts.call('onMoveCamera', [isDad ? 'dad' : 'boyfriend']);
	}
	
	public function getCharacterCameraPos(char:Null<Character>):FlxPoint
	{
		if (char == null) return FlxPoint.weak();
		
		final desiredPos = char.getMidpoint();
		
		final offsets = char.isPlayer ? boyfriendCameraOffset : opponentCameraOffset;
		
		desiredPos.y += -100 + char.cameraPosition[1] + offsets[1];
		
		if (char.isPlayer)
		{
			desiredPos.x -= 100 + char.cameraPosition[0];
		}
		else
		{
			desiredPos.x += 100 + char.cameraPosition[0];
		}
		
		desiredPos.x += offsets[0];
		
		return desiredPos;
	}
	
	public function moveCamera(isDad:Bool):Void
	{
		var desiredPos:Null<FlxPoint> = null;
		var curCharacter:Null<Character> = null;
		
		if (opponentStrums != null && playerStrums != null) curCharacter = isDad ? opponentStrums.owner : playerStrums.owner;
		else curCharacter = isDad ? dad : boyfriend;
		
		if (camCurTarget != null) curCharacter = camCurTarget;
		
		desiredPos = getCharacterCameraPos(curCharacter);
		
		camFollow.x = desiredPos.x;
		camFollow.y = desiredPos.y;
		
		if (ClientPrefs.camFollowsCharacters)
		{
			final displacement = curCharacter.getSingDisplacement();
			
			camFollow.x += displacement.x;
			camFollow.y += displacement.y;
			
			displacement.putWeak();
		}
		
		desiredPos.put();
		
		scripts.set('whosTurn', isDad ? 'dad' : 'boyfriend');
	}
	
	/**
	 * 'Snaps the camera to a position.'
	 * @param lockPosition 'if true, locks the camera position after snapping.'
	 */
	function snapCamToPos(x:Float = 0, y:Float = 0, lockPosition:Bool = false):Void
	{
		camFollow.setPosition(x, y);
		FlxG.camera.snapToTarget();
		if (lockPosition) isCameraOnForcedPos = true;
	}
	
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		
		audio.volume = 0;
		audio.stop();
		audio.stopInst();
		
		if (songEndCallback == null)
		{
			FlxG.log.error('songEndCallback is null! using default callback.');
			songEndCallback = endSong;
		}
		
		if (ClientPrefs.noteOffset <= 0 || ignoreNoteOffset)
		{
			songEndCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				songEndCallback();
			});
		}
	}
	
	public var transitioning = false;
	
	public function endSong():Void
	{
		// Should kill you if you tried to cheat
		if (!startingSong)
		{
			notes.forEach(function(daNote:Note) {
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes)
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset) health -= 0.05 * healthLoss;
				
			if (doDeathCheck()) return;
		}
		
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;
		
		deathCounter = 0;
		seenCutscene = false;
		
		final ret:Dynamic = scripts.call('onEndSong', []);
		
		if (ret != ScriptConstants.STOP_FUNC && !transitioning)
		{
			playbackRate = 1;
			var percent:Float = ratingPercent;
			if (Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyMeta.difficulty, percent);
			
			if (chartingMode)
			{
				openChartEditor();
				return;
			}
			
			if (isStoryMode)
			{
				storyMeta.score += songScore;
				storyMeta.misses += songMisses;
				
				storyMeta.playlist.remove(storyMeta.playlist[0]);
				
				if (storyMeta.playlist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					FlxG.sound.music.volume = 1;
					
					CoolUtil.cancelMusicFadeTween();
					FlxG.switchState(() -> new StoryMenuState());
					
					if (!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false))
					{
						if (WeekData.weeksList[storyMeta.curWeek] != null)
						{
							StoryMenuState.weekCompleted.set(WeekData.weeksList[storyMeta.curWeek], true);
							
							Highscore.saveWeekScore(WeekData.getWeekFileName(), storyMeta.score, storyMeta.difficulty);
							
							FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
							FlxG.save.flush();
						}
					}
					changedDifficulty = false;
				}
				else
				{
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					
					prevCamFollow = camFollow;
					
					final difficulty:String = Difficulty.getDifficultyFilePath();
					final songLowercase = Paths.sanitize(storyMeta.playlist[0].toLowerCase());
					
					trace('LOADING: ' + Paths.sanitize(storyMeta.playlist[0]) + difficulty);
					
					PlayState.SONG = Chart.fromSong(songLowercase, PlayState.storyMeta.difficulty);
					
					FlxG.sound.music.stop();
					
					CoolUtil.cancelMusicFadeTween();
					FlxG.switchState(PlayState.new);
				}
			}
			else
			{
				CoolUtil.cancelMusicFadeTween();
				FlxG.switchState(() -> new FreeplayState());
				
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				FlxG.sound.music.volume = 1;
				
				changedDifficulty = false;
			}
			transitioning = true;
		}
		
		audio.stop();
		audio.stopInst();
	}
	
	public function KillNotes():Void
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;
			
			disposeNote(daNote);
		}
		unspawnNotes = [];
		eventNotes = [];
	}
	
	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	
	public var showCombo:Bool = true;
	public var showRating:Bool = true;
	
	function popUpScore(note:Note = null):Void
	{
		if (note.hitCausesMiss || note.canMiss) return;
		
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		
		audio.playerVolume = 1 * volumeMult;
		
		// tryna do MS based judgment due to popular demand
		var daRating:Rating = Rating.judgeNote(note, noteDiff / playbackRate);
		var judgeScore:Int = daRating.score;
		
		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if (!note.ratingDisabled) daRating.increase();
		note.rating = daRating.name;
		
		var field:PlayField = note.playField;
		
		if (!practiceMode && !cpuControlled && !(field?.autoPlayed ?? false))
		{
			if (defaultScoreAddition) songScore += judgeScore;
			if (!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}
		callHUDFunc(hud -> hud.popUpScore(daRating, combo, note)); // only pushing the image bc is anyone ever gonna need anything else???
	}
	
	function onInputPress(event:InputEvent):Void
	{
		if (cpuControlled || paused || !startedCountdown) return;
		
		var key:Int = event.noteData;
		
		var prevTime:Float = Conductor.songPosition;
		if (audio.inst?.playing) Conductor.songPosition = @:privateAccess audio.inst._channel.position;
		// subtract latency
		Conductor.songPosition -= lime.system.System.getTimer() - event.timer;
		
		if (generatedMusic && !endingSong)
		{
			var anyInput:Bool = false;
			var ghostTapped:Bool = true;
			
			for (field in playFields.members)
			{
				if (!field.canInput()) continue;
				
				anyInput = true;
				
				var topNote:Note = null; // we only need the top most note !
				
				for (note in field.getTapNotes(key))
				{
					final higherPriority:Bool = (topNote == null || note.hitPriority > topNote.hitPriority);
					if (higherPriority || (!higherPriority && note.strumTime < topNote.strumTime)) topNote = note;
				}
				
				if (topNote != null)
				{
					field.onNoteHit.dispatch(topNote, field);
					
					ghostTapped = false;
				}
				else if (field.playAnims)
				{
					var strum = field.members[key];
					
					if (strum != null)
					{
						strum.playAnim('pressed');
						strum.resetAnim = 0;
					}
				}
			}
			
			if (ghostTapped && anyInput)
			{
				scripts.call('onGhostTap', [key]);
				
				if (!ClientPrefs.ghostTapping)
				{
					for (field in playFields.members)
					{
						if (field.canInput()) field.onMissPress.dispatch(key);
					}
					
					scripts.call('noteMissPress', [key]);
				}
			}
		}
		
		Conductor.songPosition = prevTime;
		
		scripts.call('onKeyPress', [key]);
		scripts.call('onInputPress', [key]);
	}
	
	function onInputRelease(event:InputEvent):Void
	{
		var key:Int = event.noteData;
		
		if (startedCountdown && !paused)
		{
			for (field in playFields.members)
			{
				if (!field.canInput()) continue;
				
				var spr:StrumNote = field.members[key];
				if (spr != null)
				{
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			}
			scripts.call('onKeyRelease', [key]);
			scripts.call('onInputRelease', [key]);
		}
	}
	
	// Hold notes
	function keyShit():Void
	{
		// HOLDING
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			
			notes.forEachAlive(function(daNote:Note) {
				// hold note functions
				if (!daNote.playField.autoPlayed && daNote.playField.inControl && daNote.playField.playerControls)
				{
					if (daNote.isSustainNote
						&& !daNote.blockHit
						&& (input.inputPressed(daNote.noteData) || (daNote.wasGoodHit && daNote.parent.coyoteProgress < 1))
						&& Conductor.songPosition >= daNote.strumTime
						&& !daNote.tooLate
						&& !daNote.wasGoodHit)
					{
						daNote.parent.coyoteProgress = 0;
						daNote.playField.onNoteHit.dispatch(daNote, daNote.playField);
					}
				}
				
				// hold note drop
				if (!daNote.playField.autoPlayed && daNote.playField.inControl && daNote.playField.playerControls)
				{
					if (daNote.isSustainNote
						&& !daNote.blockHit
						&& !daNote.ignoreNote
						&& !input.inputPressed(daNote.noteData)
						&& !endingSong
						&& !daNote.wasGoodHit)
					{
						if (daNote.tooLate)
						{
							daNote.playField.onNoteMiss.dispatch(daNote, daNote.playField);
							
							combo = 0; // Repeat the miss code unconditionally because the actualMiss signal callback comes after the function that makes notes unable to miss
							audio.miss();
							
							if (instakillOnMiss) doDeathCheck(true);
							
							songMisses++;
							if (!practiceMode) songScore -= 10;
							
							totalPlayed++;
							RecalculateRating(true);
						};
						else daNote.parent.coyoteProgress += FlxG.elapsed / 0.45;
					}
				}
			});
			
			if (boyfriend.holdTimer > Conductor.stepCrotchet * 0.0011 * boyfriend.singDuration
				&& boyfriend.getAnimName().startsWith('sing')
				&& !boyfriend.getAnimName().endsWith('miss')) boyfriend.dance(boyfriend.forceDance);
		}
		
		// TO DO: Find a better way to handle controller inputs, this should work for now
	}
	
	@:inheritDoc
	override function refreshZ(?group:FlxTypedGroup<FlxBasic>)
	{
		group ??= stage;
		group.sort(SortUtil.sortByZ, flixel.util.FlxSort.ASCENDING);
	}
	
	override function destroy()
	{
		instance = null;
		
		scripts.call('onDestroy', [], true);
		
		scripts = FlxDestroyUtil.destroy(scripts);
		eventScripts = FlxDestroyUtil.destroy(eventScripts);
		noteTypeScripts = FlxDestroyUtil.destroy(noteTypeScripts);
		
		input.destroy();
		input = FlxDestroyUtil.destroy(input);
		
		modManager = FlxDestroyUtil.destroy(modManager);
		
		FlxDestroyUtil.destroyArray(NoteUtil.noteskins);
		NoteUtil.noteskins.resize(0);
		
		super.destroy();
	}
	
	override function stepHit()
	{
		super.stepHit();
		
		final maxToleratedOffset:Float = 20 * playbackRate;
		
		if (audio.inst != null)
		{
			if (Math.abs(audio.inst.time - (Conductor.songPosition - Conductor.offset)) > maxToleratedOffset
				|| (SONG.needsVoices && audio.getDesyncDifference(Math.abs(Conductor.songPosition - Conductor.offset)) > maxToleratedOffset)) resyncVocals();
		}
		
		if (curStep == lastStepHit) return;
		
		lastStepHit = curStep;
		scripts.set('curStep', curStep);
		
		scripts.call('onStepHit');
		
		callHUDFunc(hud -> hud.stepHit());
	}
	
	var lastStepHit:Int = -1;
	var lastBeatHit:Int = -1;
	var lastSection:Int = -1;
	
	override function beatHit()
	{
		super.beatHit();
		
		if (lastBeatHit >= curBeat) return;
		
		if (generatedMusic) notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		
		handleBoppers(curBeat);
		
		if (beatsPerZoom == 0) beatsPerZoom = 4;
		
		if (camZooming && ClientPrefs.camZooms && curBeat % beatsPerZoom == 0)
		{
			FlxG.camera.zoom += 0.015 * camZoomingMult;
			camHUD.zoom += 0.03 * camZoomingMult;
		}
		
		lastBeatHit = curBeat;
		
		scripts.set('curBeat', curBeat);
		scripts.call('onBeatHit');
		callHUDFunc(hud -> hud.beatHit());
	}
	
	// rework this
	public function handleBoppers(beat:Int)
	{
		gf?.onBeatHit(beat);
		boyfriend?.onBeatHit(beat);
		dad?.onBeatHit(beat);
	}
	
	override function sectionHit():Void
	{
		if (SONG.notes[curSection] != null)
		{
			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				scripts.set('curBpm', Conductor.bpm);
				scripts.set('crotchet', Conductor.crotchet);
				scripts.set('stepCrotchet', Conductor.stepCrotchet);
			}
			scripts.set('mustHitSection', SONG.notes[curSection].mustHitSection);
			scripts.set('altAnim', SONG.notes[curSection].altAnim);
			scripts.set('gfSection', SONG.notes[curSection].gfSection);
		}
		
		super.sectionHit();
		
		scripts.set('curSection', curSection);
		scripts.call('onSectionHit');
		callHUDFunc(hud -> hud.sectionHit());
	}
	
	/**
	 * Attempts to call a function on a event script by event name
	 */
	public function callEventScript(scriptName:String, func:String, args:Array<Dynamic>):Dynamic
	{
		if (!eventScripts.exists(scriptName)) return ScriptConstants.CONTINUE_FUNC;
		
		final script = eventScripts.getScript(scriptName);
		
		return callScript(script, func, args);
	}
	
	/**
	 * Attempts to call a function on a note script by note type
	 */
	public function callNoteTypeScript(noteType:String, func:String, args:Array<Dynamic>):Dynamic
	{
		if (!noteTypeScripts.exists(noteType)) return ScriptConstants.CONTINUE_FUNC;
		
		final script = noteTypeScripts.getScript(noteType);
		
		return callScript(script, func, args);
	}
	
	/**
	 * calls a function directly on a script if it exists
	 */
	public function callScript(script:FunkinScript, event:String, args:Array<Dynamic>):Dynamic
	{
		if (!script.exists(event)) return ScriptConstants.CONTINUE_FUNC;
		
		var ret:Dynamic = script.call(event, args)?.returnValue;
		
		return ret ?? ScriptConstants.CONTINUE_FUNC;
	}
	
	public var ratingName:String = '?';
	public var ratingPercent:Float = 0.0;
	public var ratingFC:String = '';
	
	public function RecalculateRating(badHit:Bool = false)
	{
		final ret:Dynamic = scripts.call('onRecalculateRating', []);
		if (ret != ScriptConstants.STOP_FUNC)
		{
			if (totalPlayed < 1) // Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				
				// Rating Name
				if (ratingPercent >= 1) ratingName = ratingStuff[ratingStuff.length - 1].name; // Uses last string
				else
				{
					for (i in 0...ratingStuff.length - 1)
					{
						if (ratingPercent < ratingStuff[i].percent)
						{
							ratingName = ratingStuff[i].name;
							break;
						}
					}
				}
			}
			
			updateRatingFC();
		}
		
		updateScoreBar(badHit);
	}
	
	// so you can override this in HScript
	// e.g: PlayState.instance.updateRatingFC = function() { ... }
	public dynamic function updateRatingFC()
	{
		// Rating FC
		ratingFC = "";
		if (epics > 0) ratingFC = "KFC"; // kentucky fried chiken
		if (sicks > 0) ratingFC = "SFC";
		if (goods > 0) ratingFC = "GFC";
		if (bads > 0 || shits > 0) ratingFC = "FC";
		if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
		else if (songMisses >= 10) ratingFC = "Clear";
	}
}
