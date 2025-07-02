package funkin.states;

import flixel.group.FlxContainer.FlxTypedContainer;

import haxe.ds.Vector;

import openfl.utils.Assets as OpenFlAssets;
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
import flixel.util.FlxSignal;
import flixel.util.FlxSave;

import funkin.objects.character.CharacterBuilder;
import funkin.objects.character.Character;
import funkin.backend.Difficulty;
import funkin.game.RatingInfo;
import funkin.objects.Note.EventNote;
import funkin.scripts.FunkinScript.ScriptType;
import funkin.game.huds.BaseHUD;
import funkin.scripts.*;
import funkin.scripts.FunkinLua;
import funkin.data.Song.SwagSong;
import funkin.data.Song.SwagSection;
import funkin.data.StageData;
import funkin.objects.DialogueBoxPsych;
import funkin.game.Rating;
import funkin.objects.*;
import funkin.data.*;
import funkin.states.*;
import funkin.states.substates.*;
import funkin.states.editors.*;
import funkin.scripts.FunkinLua.ModchartSprite;
import funkin.game.modchart.*;
import funkin.backend.SyncedFlxSoundGroup;
#if VIDEOS_ALLOWED
import funkin.video.FunkinVideoSprite;
#end

class PlayState extends MusicBeatState
{
	public var modManager:ModManager;
	
	var speedChanges:Array<SpeedEvent> = [{}];
	
	public var currentSV:SpeedEvent = {};
	
	var noteRows:Array<Array<Array<Note>>> = [[], []];
	
	public static var meta:Metadata = null;
	
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;
	public static var arrowSkin:String = '';
	public static var noteSplashSkin:String = '';
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
	
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartObjects:Map<String, FlxSprite> = new Map<String, FlxSprite>();
	
	public var variables:Map<String, Dynamic> = new Map();
	
	public var isCameraOnForcedPos:Bool = false;
	
	public var boyfriendMap:Map<String, Character> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	
	/**
	 * Container of all boyfriend's used in the state
	 * 
	 * Exists for the `Change Character` event.
	 */
	public var boyfriendGroup:FlxSpriteGroup;
	
	/**
	 * Container of all dad's used in the state
	 * 
	 * Exists for the `Change Character` event.
	 */
	public var dadGroup:FlxSpriteGroup;
	
	/**
	 * Container of all gf's used in the state
	 * 
	 * Exists for the `Change Character` event.
	 */
	public var gfGroup:FlxSpriteGroup;
	
	/**
		Reference to the current dad
	**/
	public var dad:Character;
	
	/**
		Reference to the current girlfriend
	**/
	public var gf:Character;
	
	/**
		Reference to the current girlfriend
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
	
	/**
		Girlfriend's dance rate. 
	**/
	public var gfSpeed:Int = 1;
	
	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;
	
	public static var curStage:String = 'stage';
	
	public var stage:Stage;
	
	public var doof:DialogueBox;
	
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	
	public var spawnTime:Float = 3000;
	
	/**
	 * Specialized container for character vocals
	 */
	public var vocals:VocalGroup;
	
	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];
	
	var strumLine:FlxSprite;
	
	/**
	 * Target the game camera follows
	 */
	var camFollow:FlxObject;
	
	/**
	 * Previous cameras target. used in story mode for more of a seamless transition
	 */
	static var prevCamFollow:FlxObject;
	
	/**
	 * List of FlxCameras that follow camFollow
	**/
	public var followingCams:Array<FlxCamera> = [];
	
	/**
	 * Container of all strumlines in use
	 */
	public var playFields:FlxTypedGroup<PlayField>;
	
	/**
	 * The oppononents Strum field
	 */
	public var opponentStrums:PlayField;
	
	/**
	 * The players Strum field
	 */
	public var playerStrums:PlayField;
	
	public var extraFields:Array<PlayField> = [];
	
	@:isVar public var strumLineNotes(get, null):Array<StrumNote>;
	
	@:noCompletion function get_strumLineNotes()
	{
		var notes:Array<StrumNote> = [];
		if (playFields != null && playFields.length > 0)
		{
			for (field in playFields.members)
			{
				for (sturm in field.members)
					notes.push(sturm);
			}
		}
		return notes;
	}
	
	/**
	 * The container that all notesplashes are held in
	 */
	public var grpNoteSplashes:FlxTypedContainer<NoteSplash>;
	
	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	
	var curSong:String = "";
	
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
	
	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;
	
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;
	
	public var defaultScoreAddition:Bool = true;
	
	var stageData:StageFile;
	
	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;
	
	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	
	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;
	
	public var defaultCamZoomAdd:Float = 0;
	public var defaultCamZoom:Float = 1.05;
	public var defaultHudZoom:Float = 1;
	public var beatsPerZoom:Int = 4;
	
	var totalBeat:Int = 0;
	var totalShake:Int = 0;
	var timeBeat:Float = 1;
	var gameZ:Float = 0.015;
	var hudZ:Float = 0.03;
	var gameShake:Float = 0.003;
	var hudShake:Float = 0.003;
	var shakeTime:Bool = false;
	
	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	
	public var inCutscene:Bool = false;
	public var ingameCutscene:Bool = false;
	
	public var skipCountdown:Bool = false;
	public var countdownSounds:Bool = true;
	public var countdownDelay:Float = 0;
	
	var songLength:Float = 0;
	
	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;
	
	#if DISCORD_ALLOWED
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end
	
	// Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;
	
	// Script shit
	public static var instance:Null<PlayState> = null;
	
	public var luaArray:Array<FunkinLua> = [];
	public var funkyScripts:Array<FunkinScript> = [];
	public var hscriptArray:Array<FunkinIris> = []; // will be replaced with hscriptgroups eventually
	
	public var notetypeScripts:Map<String, FunkinScript> = []; // custom notetypes for scriptVer '1'
	public var eventScripts:Map<String, FunkinScript> = []; // custom events for scriptVer '1'
	
	public static var noteSkin:funkin.data.NoteSkinHelper;
	
	// might make this a map ngl
	public var script_NOTEOffsets:Vector<FlxPoint>;
	public var script_STRUMOffsets:Vector<FlxPoint>;
	public var script_SUSTAINOffsets:Vector<FlxPoint>;
	public var script_SUSTAINENDOffsets:Vector<FlxPoint>;
	public var script_SPLASHOffsets:Vector<FlxPoint>;
	
	public var introSoundsSuffix:String = '';
	
	// Debug buttons
	var debugKeysChart:Array<FlxKey>;
	var debugKeysCharacter:Array<FlxKey>;
	
	// Less laggy controls
	public var keysArray:Array<Dynamic>;
	
	// public var controlHoldArray:Array<Dynamic>;
	public var camCurTarget:Character = null;
	
	public var playHUD:BaseHUD = null;
	
	public var soundMode:String = ''; // crude setup but its done quick. essentially make this = "SWAP" in the case the vocals ALSO contain the inst. it will mute the inst track when vocals play and vice versa
	
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
	
	@:noCompletion public function set_cpuControlled(val:Bool)
	{
		if (playFields != null && playFields.members.length > 0)
		{
			for (field in playFields.members)
			{
				if (field.isPlayer) field.autoPlayed = val;
			}
		}
		return (cpuControlled = val);
	}
	
	function setStageData(stageData:StageFile)
	{
		defaultCamZoom = stageData.defaultZoom;
		FlxG.camera.zoom = stageData.defaultZoom;
		// for(c in followingCams) c.zoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];
		
		if (stageData.camera_speed != null) cameraSpeed = stageData.camera_speed;
		
		boyfriendCameraOffset = stageData.camera_boyfriend ?? [0, 0];
		
		opponentCameraOffset = stageData.camera_opponent ?? [0, 0];
		
		girlfriendCameraOffset = stageData.camera_girlfriend ?? [0, 0];
		
		if (boyfriendGroup == null) boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		else
		{
			boyfriendGroup.x = BF_X;
			boyfriendGroup.y = BF_Y;
		}
		if (dadGroup == null) dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		else
		{
			dadGroup.x = DAD_X;
			dadGroup.y = DAD_Y;
		}
		
		if (gfGroup == null) gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		else
		{
			gfGroup.x = GF_X;
			gfGroup.y = GF_Y;
		}
	}
	
	// null checking
	function callHUDFunc(f:BaseHUD->Void) if (playHUD != null) f(playHUD);
	
	override public function create()
	{
		FunkinAssets.cache.clearStoredMemory();
		
		skipCountdown = false;
		countdownSounds = true;
		
		// for lua
		instance = this;
		
		GameOverSubstate.resetVariables();
		
		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; // Reset to default
		
		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];
		
		songStartCallback = startCountdown;
		songEndCallback = endSong;
		
		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}
		
		// If u have epics enabled
		if (ClientPrefs.useEpicRankings)
		{
			ratingsData.unshift(new Rating('epic'));
		}
		
		FlxG.sound.music?.stop();
		
		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		
		camHUD.bgColor = 0x0;
		camOther.bgColor = 0x0;
		
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		
		// followingCams.push(FlxG.camera);
		
		setOnScripts('this', this);
		setOnScripts('camGame', camGame);
		setOnScripts('camHUD', camHUD);
		
		grpNoteSplashes = new FlxTypedContainer<NoteSplash>();
		
		persistentUpdate = true;
		persistentDraw = true;
		
		if (SONG == null) SONG = Song.loadFromJson('tutorial');
		
		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;
		
		arrowSkin = SONG.arrowSkin;
		
		initNoteSkinning();
		
		#if DISCORD_ALLOWED
		storyDifficultyText = Difficulty.difficulties[storyDifficulty];
		
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode) // fix this again
		{
			// detailsText = "";
		}
		else
		{
			// detailsText = "";
		}
		
		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end
		
		setOnScripts('isStoryMode', isStoryMode);
		
		var songName:String = Paths.formatToSongPath(SONG.song);
		
		if (SONG.stage == null || SONG.stage.length == 0) SONG.stage = 'stage';
		curStage = SONG.stage;
		
		stage = new Stage(curStage);
		stageData = stage.stageData;
		setStageData(stageData); // change to setter
		setOnScripts('stage', stage);
		
		// STAGE SCRIPTS
		stage.buildStage();
		
		if (stage.curStageScript != null)
		{
			switch (stage.curStageScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast stage.curStageScript);
					
				case LUA:
					#if LUA_ALLOWED
					luaArray.push(cast stage.curStageScript);
					#end
			}
			funkyScripts.push(stage.curStageScript);
			trace(stage.curStageScript.scriptName);
		}
		
		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}
		
		if (callOnHScripts("onAddSpriteGroups", []) != Globals.Function_Stop)
		{
			add(stage);
			stage.add(gfGroup);
			stage.add(dadGroup);
			stage.add(boyfriendGroup);
		}
		
		setOnHScripts('camGame', camGame);
		setOnHScripts('camHUD', camHUD);
		setOnHScripts('camOther', camOther);
		
		// "GLOBAL" SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPrimaryPath('scripts/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0) foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/scripts/'));
		
		for (mod in Mods.globalMods)
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.H_EXTS)
							{
								if (file.endsWith('.$ext'))
								{
									var script = initFunkinIris(folder + file);
									if (script != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1) SONG.gfVersion = gfVersion = 'gf';
		
		if (!stageData.hide_girlfriend)
		{
			gf = CharacterBuilder.fromName(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterScript(gf.curCharacter, gf);
			
			setOnScripts('gf', gf);
			setOnScripts('gfGroup', gfGroup);
		}
		
		dad = CharacterBuilder.fromName(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScript(dad.curCharacter, dad);
		dadMap.set(dad.curCharacter, dad);
		
		boyfriend = CharacterBuilder.fromName(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScript(boyfriend.curCharacter, boyfriend);
		boyfriendMap.set(boyfriend.curCharacter, boyfriend);
		
		setOnScripts('dad', dad);
		setOnScripts('dadGroup', dadGroup);
		
		setOnScripts('boyfriend', boyfriend);
		setOnScripts('boyfriendGroup', boyfriendGroup);
		
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
		
		var file:String = Paths.json(songName + '/dialogue'); // Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}
		
		final vanillaText:String = songName + '/' + songName + 'Dialogue';
		var file:String = Paths.txt(vanillaText); // Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogue = CoolUtil.coolTextFile(file);
		}
		#if MODS_ALLOWED
		file = Paths.modFolders('${Mods.currentModDirectory}/data/${vanillaText}.txt');
		if (file != null)
		{
			dialogue = CoolUtil.coolTextFile(file);
		}
		#end
		doof = new DialogueBox(false, dialogue);
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;
		
		Conductor.songPosition = -5000;
		
		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(4, 4, FlxColor.TRANSPARENT);
		strumLine.visible = false;
		strumLine.scrollFactor.set();
		
		// temp
		updateTime = true;
		
		playFields = new FlxTypedGroup<PlayField>();
		add(playFields);
		add(grpNoteSplashes);
		
		playHUD = new funkin.game.huds.PsychHUD(this);
		insert(members.indexOf(playFields), playHUD); // Data told me to do this
		playHUD.cameras = [camHUD];
		
		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;
		
		meta = Metadata.getSong();
		
		generateSong(SONG.song);
		modManager = new ModManager(this);
		setOnHScripts("modManager", modManager);
		
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;
		
		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		add(strumLine);
		
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
		
		FlxG.fixedTimestep = false;
		moveCameraSection();
		
		botplayTxt = new FlxText(400, 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		if (ClientPrefs.downScroll) botplayTxt.y = FlxG.height - botplayTxt.height - 55;
		add(botplayTxt);
		
		playFields.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		doof.cameras = [camOther];
		
		setOnScripts('playFields', playFields);
		setOnScripts('grpNoteSplashes', grpNoteSplashes);
		setOnScripts('notes', notes);
		
		setOnScripts('botplayTxt', botplayTxt);
		
		setOnScripts('doof', doof);
		
		callOnLuas('onCreate', []);
		
		startingSong = true;
		
		// SONG SPECIFIC SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPrimaryPath('songs/' + Paths.formatToSongPath(SONG.song) + '/'),];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('songs/' + Paths.formatToSongPath(SONG.song) + '/'));
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0) foldersToCheck.insert(0,
			Paths.mods(Mods.currentModDirectory + '/songs/' + Paths.formatToSongPath(SONG.song) + '/'));
			
		for (mod in Mods.globalMods)
			foldersToCheck.insert(0, Paths.mods(mod + '/songs/' + Paths.formatToSongPath(SONG.song) + '/')); // using push instead of insert because these should run after everything else
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.H_EXTS)
							{
								if (file.endsWith('.$ext'))
								{
									var sc = initFunkinIris(folder + file);
									if (sc != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		if (songStartCallback == null)
		{
			FlxG.log.error('songStartCallback is null! using default callback.');
			songStartCallback = startCountdown;
		}
		
		songStartCallback();
		
		RecalculateRating();
		updateScoreBar();
		
		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.hitsoundVolume > 0) Paths.sound('hitsound');
		Paths.sound('missnote1');
		Paths.sound('missnote2');
		Paths.sound('missnote3');
		
		if (PauseSubState.songName != null)
		{
			Paths.music(PauseSubState.songName);
		}
		else if (ClientPrefs.pauseMusic != 'None')
		{
			Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic));
		}
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, FlxG.random.getObject(DiscordClient.discordPresences), null);
		#end
		
		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		
		callOnScripts('onCreatePost', []);
		
		super.create();
		
		FunkinAssets.cache.clearUnusedMemory();
		
		refreshZ(stage);
	}
	
	function noteskinLoading(skin:String = 'default')
	{
		if (FileSystem.exists(Paths.modsNoteskin(skin))) noteSkin = new NoteSkinHelper(Paths.modsNoteskin(skin));
		else if (FileSystem.exists(Paths.noteskin(skin))) noteSkin = new NoteSkinHelper(Paths.noteskin(skin));
		
		arrowSkin = skin;
		
		noteSkin ??= new NoteSkinHelper(Paths.noteskin('default'));
	}
	
	function initNoteSkinning()
	{
		script_NOTEOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINENDOffsets = new Vector<FlxPoint>(SONG.keys);
		script_STRUMOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SPLASHOffsets = new Vector<FlxPoint>(SONG.keys);
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i] = new FlxPoint();
			script_STRUMOffsets[i] = new FlxPoint();
			script_SUSTAINOffsets[i] = new FlxPoint();
			script_SUSTAINENDOffsets[i] = new FlxPoint();
			script_SPLASHOffsets[i] = new FlxPoint();
		}
		
		var skin = SONG.arrowSkin;
		if (skin == '' || skin == 'null' || skin == null) skin = 'default';
		
		noteskinLoading(skin);
		
		trace('Quants turned on: ${ClientPrefs.noteSkin.contains('Quant')}');
		trace('HAS quants: ${noteSkin.data.hasQuants}');
		
		if (ClientPrefs.noteSkin.contains('Quant') && noteSkin.data.hasQuants) noteskinLoading('QUANT$skin');
		
		NoteSkinHelper.setNoteHelpers(noteSkin, SONG.keys);
		
		// trace(noteSkin.data);
		
		arrowSkin = noteSkin.data.globalSkin;
		NoteSkinHelper.arrowSkins = [noteSkin.data.playerSkin, noteSkin.data.opponentSkin];
		if (SONG.lanes > 2)
		{
			for (i in 2...SONG.lanes)
			{
				NoteSkinHelper.arrowSkins.push(noteSkin.data.extraSkin);
			}
		}
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i].x = noteSkin.data.noteAnimations[i][0].offsets[0];
			script_NOTEOffsets[i].y = noteSkin.data.noteAnimations[i][0].offsets[1];
			
			script_SUSTAINOffsets[i].x = noteSkin.data.noteAnimations[i][1].offsets[0];
			script_SUSTAINOffsets[i].y = noteSkin.data.noteAnimations[i][1].offsets[1];
			
			script_SUSTAINENDOffsets[i].x = noteSkin.data.noteAnimations[i][2].offsets[0];
			script_SUSTAINENDOffsets[i].y = noteSkin.data.noteAnimations[i][2].offsets[1];
			script_SUSTAINENDOffsets[i].y *= (ClientPrefs.downScroll ? -1 : 1);
			
			// trace('Sus: ${script_SUSTAINOffsets[i].y} | End: ${script_SUSTAINENDOffsets[i].y}');
			
			script_SPLASHOffsets[i].x = noteSkin.data.noteSplashAnimations[i].offsets[0];
			script_SPLASHOffsets[i].y = noteSkin.data.noteSplashAnimations[i].offsets[1];
		}
		
		noteSplashSkin = noteSkin.data.noteSplashSkin;
	}
	
	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes)
				note.resizeByRatio(ratio);
			for (note in unspawnNotes)
				note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}
	
	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Character = CharacterBuilder.fromName(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScript(newBoyfriend.curCharacter, newBoyfriend);
				}
				
			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = CharacterBuilder.fromName(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScript(newDad.curCharacter, newDad);
				}
				
			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = CharacterBuilder.fromName(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScript(newGf.curCharacter, newGf);
				}
		}
	}
	
	function startCharacterScript(name:String, char:Character)
	{
		final luaPath = Paths.getPath('characters/$name.lua', TEXT, null, true);
		final hscriptPath = FunkinIris.getPath('characters/$name');
		
		if (FunkinAssets.exists(luaPath, TEXT))
		{
			for (lua in luaArray)
			{
				if (lua.scriptName == luaPath) return;
			}
			var lua:FunkinLua = new FunkinLua(luaPath);
			luaArray.push(lua);
			funkyScripts.push(lua);
		}
		else if (FunkinAssets.exists(hscriptPath, TEXT))
		{
			initFunkinIris(hscriptPath);
		}
	}
	
	function initFunkinIris(filePath:String, ?name:String)
	{
		for (i in hscriptArray)
		{
			if (i.scriptName == filePath) return null; // script is already in dont add it twice
		}
		
		var script:FunkinIris = FunkinIris.fromFile(filePath);
		if (script.__garbage)
		{
			script = FlxDestroyUtil.destroy(script);
			return null;
		}
		script.call('onCreate');
		hscriptArray.push(script);
		funkyScripts.push(script);
		return script;
	}
	
	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		if (modchartObjects.exists(tag)) return modchartObjects.get(tag);
		if (modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		return null;
	}
	
	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}
	
	public function startVideo(name:String):Void
	{
		#if VIDEOS_ALLOWED
		final fileName = Paths.video(name);
		
		if (FunkinAssets.exists(fileName, BINARY))
		{
			inCutscene = true;
			var bg = new flixel.system.FlxBGSprite();
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);
			
			var vid = new FlxVideo();
			FlxG.addChildBelowMouse(vid);
			vid.onEndReached.add(() -> {
				remove(bg);
				startAndEnd();
				
				FlxG.removeChild(vid);
				vid.dispose();
			});
			vid.load(fileName);
			vid.play();
			return;
		}
		else
		{
			FlxG.log.warn('Couldnt find video file: ' + fileName);
			startAndEnd();
		}
		#else
		startAndEnd();
		#end
	}
	
	inline function startAndEnd()
	{
		endingSong ? endSong() : startCountdown();
	}
	
	var dialogueCount:Int = 0;
	
	public var psychDialogue:DialogueBoxPsych;
	
	// You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null) return;
		
		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;
			
			Paths.sound('dialogue');
			Paths.sound('dialogueClose');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if (endingSong)
			{
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			}
			else
			{
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if (endingSong)
			{
				endSong();
			}
			else
			{
				startCountdown();
			}
		}
	}
	
	var startTimer:FlxTimer = null;
	var finishTimer:FlxTimer = null;
	
	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	
	public function startCountdown():Void
	{
		if (startedCountdown)
		{
			callOnScripts('onStartCountdown', []);
			return;
		}
		
		inCutscene = false;
		
		final ret:Dynamic = callOnScripts('onStartCountdown', []);
		
		if (ret != Globals.Function_Stop)
		{
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;
			
			for (lane in 0...SONG.lanes)
			{
				if (lane == 0)
				{
					playerStrums = new PlayField(ClientPrefs.middleScroll ? (FlxG.width / 2) : FlxG.width / 2
						+ (FlxG.width / 4), strumLine.y, SONG.keys, boyfriend, true, cpuControlled, lane);
					playerStrums.noteHitCallback.add(goodNoteHit);
					playerStrums.noteMissCallback.add(noteMiss);
					playerStrums.playerControls = true;
					// playerStrums.autoPlayed = false;
					callOnScripts('preReceptorGeneration', [playerStrums, lane]);
					playerStrums.generateReceptors();
					playerStrums.fadeIn(isStoryMode || skipArrowStartTween);
					playFields.add(playerStrums);
					
					continue;
				}
				else if (lane == 1)
				{
					opponentStrums = new PlayField(ClientPrefs.middleScroll ? (FlxG.width / 2) : (FlxG.width / 2 - (FlxG.width / 4)), strumLine.y, SONG.keys, dad, false, true, 1);
					opponentStrums.noteHitCallback.add(opponentNoteHit);
					if (!ClientPrefs.opponentStrums) opponentStrums.baseAlpha = 0;
					else if (ClientPrefs.middleScroll) opponentStrums.baseAlpha = 0.35;
					opponentStrums.offsetReceptors = ClientPrefs.middleScroll;
					opponentStrums.playerControls = false;
					opponentStrums.autoPlayed = true;
					
					callOnScripts('preReceptorGeneration', [opponentStrums, lane]);
					opponentStrums.generateReceptors();
					opponentStrums.fadeIn(isStoryMode || skipArrowStartTween);
					playFields.add(opponentStrums);
					
					continue;
				}
				
				var strum:PlayField = new PlayField((FlxG.width / 2), strumLine.y, SONG.keys, boyfriend, true, cpuControlled, lane);
				callOnScripts('preReceptorGeneration', [strum, lane]);
				strum.noteHitCallback.add(extraNoteHit);
				strum.playerControls = false;
				strum.autoPlayed = true;
				strum.ID = lane;
				strum.generateReceptors();
				strum.fadeIn(isStoryMode || skipArrowStartTween);
				extraFields.push(strum);
			}
			
			if (extraFields.length != 0) for (extra in extraFields)
				playFields.add(extra);
				
			setOnHScripts('playerStrums', playerStrums);
			setOnHScripts('opponentStrums', opponentStrums);
			setOnHScripts('playFields', playFields);
			
			callOnScripts('postReceptorGeneration', [isStoryMode || skipArrowStartTween]); // incase you wanna do anything JUST after
			
			for (i in 0...playerStrums.length)
			{
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length)
			{
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
			}
			
			modManager.receptors = [playerStrums.members, opponentStrums.members];
			
			if (extraFields.length != 0) for (e in extraFields)
				modManager.receptors.push(e.members);
				
			modManager.lanes = SONG.lanes;
			
			callOnHScripts('preModifierRegister', []);
			modManager.registerEssentialModifiers();
			modManager.registerDefaultModifiers();
			callOnHScripts('postModifierRegister', []);
			
			new FlxTimer().start(countdownDelay, (t:FlxTimer) -> {
				startedCountdown = true;
				Conductor.songPosition = 0;
				Conductor.songPosition -= Conductor.crotchet * 5;
				setOnLuas('startedCountdown', true);
				callOnScripts('onCountdownStarted', []);
				
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
				
				startTimer = new FlxTimer().start((Conductor.crotchet / 1000), function(tmr:FlxTimer) {
					handleBoppers(tmr.loopsLeft);
					
					var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
					introAssets.set('default', ['ready', 'set', 'go']);
					introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);
					
					var introAlts:Array<String> = introAssets.get('default');
					var antialias:Bool = ClientPrefs.globalAntialiasing;
					if (isPixelStage)
					{
						introAlts = introAssets.get('pixel');
						antialias = false;
					}
					
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
					
					callOnScripts('onCountdownTick', [swagCounter]);
					
					swagCounter += 1;
				}, 5);
			});
		}
	}
	
	function makeCountdownSprite(path:String)
	{
		var spr = new FlxSprite().loadGraphic(Paths.image(path));
		spr.scrollFactor.set();
		spr.updateHitbox();
		
		if (PlayState.isPixelStage) spr.setGraphicSize(Std.int(spr.width * daPixelZoom));
		spr.screenCenter();
		spr.antialiasing = isPixelStage ? false : ClientPrefs.globalAntialiasing;
		
		spr.cameras = [camHUD];
		
		FlxTween.tween(spr, {alpha: 0}, Conductor.crotchet / 1000,
			{
				ease: FlxEase.cubeInOut,
				onComplete: function(twn:FlxTween) {
					remove(spr);
					spr.destroy();
				}
			});
		return spr;
	}
	
	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	
	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	
	public function addBehindDad(obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}
	
	inline function disposeNote(note:Note)
	{
		if (modchartObjects.exists('note${note.ID}')) modchartObjects.remove('note${note.ID}');
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}
	
	public function clearNotesBefore(time:Float)
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
				
				if (modchartObjects.exists('note${daNote.ID}')) modchartObjects.remove('note${daNote.ID}');
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
	
	public function setSongTime(time:Float)
	{
		if (time < 0) time = 0;
		
		FlxG.sound.music.pause();
		vocals.pause();
		
		FlxG.sound.music.time = time;
		FlxG.sound.music.play();
		
		vocals.time = time;
		vocals.play();
		Conductor.songPosition = time;
		songTime = time;
	}
	
	function startNextDialogue()
	{
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}
	
	function skipDialogue()
	{
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}
	
	var previousFrameTime:Int = 0;
	var songTime:Float = 0;
	
	function startSong():Void
	{
		startingSong = false;
		
		previousFrameTime = FlxG.game.ticks;
		
		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = finishSong.bind(false);
		vocals.play();
		vocals.volume = 1;
		
		FlxG.sound.music.volume = soundMode == "SWAP" ? 0 : 1;
		
		if (startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;
		
		if (paused)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}
		
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, FlxG.random.getObject(DiscordClient.discordPresences), null, true, songLength);
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart', []);
		callHUDFunc(hud -> hud.onSongStart());
	}
	
	var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	
	function shouldPush(event:EventNote)
	{
		switch (event.event)
		{
			default:
				final returnValue:Dynamic = callEventScript(event.event, 'shouldPush', [event], [event.value1, event.value2]) == Globals.Function_Continue;
				return returnValue;
		}
		return true;
	}
	
	function getEvents()
	{
		var songData = SONG;
		var events:Array<EventNote> = [];
		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		
		if (FunkinAssets.exists(file))
		{
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) // Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote =
						{
							strumTime: newEventNote[0] + ClientPrefs.noteOffset,
							event: newEventNote[1],
							value1: newEventNote[2],
							value2: newEventNote[3]
						};
					if (!shouldPush(subEvent)) continue;
					events.push(subEvent);
				}
			}
		}
		
		for (event in songData.events) // Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote =
					{
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
				if (!shouldPush(subEvent)) continue;
				events.push(subEvent);
			}
		}
		
		return events;
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
		
		var songData = SONG;
		Conductor.bpm = songData.bpm;
		
		curSong = songData.song;
		
		Paths.inst(PlayState.SONG.song);
		
		vocals = new VocalGroup();
		add(vocals);
		
		if (SONG.needsVoices)
		{
			final playerSound = Paths.voices(PlayState.SONG.song, 'player', false) ?? Paths.voices(PlayState.SONG.song, null, false);
			if (playerSound != null)
			{
				vocals.addPlayerVocals(new FlxSound().loadEmbedded(playerSound));
			}
			
			final opponentSound = Paths.voices(PlayState.SONG.song, 'opp', false);
			if (opponentSound != null)
			{
				vocals.addOpponentVocals(new FlxSound().loadEmbedded(opponentSound));
			}
		}
		
		vocals.volume = 0;
		FlxG.sound.music.volume = 0;
		
		setOnHScripts('vocals', vocals);
		setOnHScripts('inst', FlxG.sound.music);
		
		notes = new FlxTypedGroup<Note>();
		add(notes);
		
		var noteData:Array<SwagSection>;
		
		// NEW SHIT
		noteData = songData.notes;
		
		var playerCounter:Int = 0;
		
		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		
		// loads note types
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var type:Dynamic = songNotes[3];
				if (!Std.isOfType(type, String)) type = ChartingState.noteTypeList[type];
				
				if (!noteTypeMap.exists(type))
				{
					firstNotePush(type);
					noteTypeMap.set(type, true);
				}
			}
		}
		
		for (notetype in noteTypeMap.keys())
		{
			var doPush:Bool = false;
			var baseScriptFile:String = 'custom_notetypes/' + notetype;
			var exts = [#if LUA_ALLOWED "lua" #end];
			for (e in FunkinIris.H_EXTS)
				exts.push(e);
			for (ext in exts)
			{
				if (doPush) break;
				var baseFile = '$baseScriptFile.$ext';
				var files = [#if MODS_ALLOWED Paths.modFolders(baseFile), #end Paths.getPrimaryPath(baseFile)];
				for (file in files)
				{
					if (FileSystem.exists(file))
					{
						if (ext == LUA)
						{
							var script = new FunkinLua(file, notetype);
							luaArray.push(script);
							funkyScripts.push(script);
							notetypeScripts.set(notetype, script);
							doPush = true;
						}
						else
						{
							var script = initFunkinIris(file, notetype);
							if (script != null)
							{
								notetypeScripts.set(notetype, script);
								doPush = true;
							}
						}
						if (doPush) break;
					}
				}
			}
		}
		
		// loads events
		for (event in getEvents())
		{
			if (!eventPushedMap.exists(event.event))
			{
				eventPushedMap.set(event.event, true);
				firstEventPush(event);
			}
		}
		
		for (event in eventPushedMap.keys())
		{
			var doPush:Bool = false;
			var baseScriptFile:String = 'custom_events/' + event;
			var exts = [#if LUA_ALLOWED "lua" #end].concat(FunkinIris.H_EXTS);
			for (ext in exts)
			{
				if (doPush) break;
				var baseFile = '$baseScriptFile.$ext';
				var files = [#if MODS_ALLOWED Paths.modFolders(baseFile), #end Paths.getPrimaryPath(baseFile)];
				for (file in files)
				{
					if (FileSystem.exists(file))
					{
						if (ext == LUA)
						{
							var script = new FunkinLua(file, event);
							luaArray.push(script);
							funkyScripts.push(script);
							trace("event script " + event);
							eventScripts.set(event, script);
							script.call("onLoad", [event]);
							doPush = true;
						}
						else
						{
							var script = initFunkinIris(file, event);
							if (script != null)
							{
								eventScripts.set(event, script);
								script.call("onLoad", [event]);
								doPush = true;
							}
						}
						if (doPush) break;
					}
				}
			}
		}
		
		for (subEvent in getEvents())
		{
			subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
			eventNotes.push(subEvent);
			eventPushed(subEvent);
		}
		if (eventNotes.length > 1)
		{ // No need to sort if there's a single one or none at all
			eventNotes.sort(SortUtil.sortByTime);
		}
		
		speedChanges.sort(SortUtil.svSort);
		
		var lastBFNotes:Array<Note> = [null, null, null, null];
		var lastDadNotes:Array<Note> = [null, null, null, null];
		// Should populate these w/ nulls depending on keycount -neb
		
		#if debug
		var cpuTime = Sys.time();
		#end
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % SONG.keys);
				
				var gottaHitNote:Bool = section.mustHitSection;
				
				if (songNotes[1] > (SONG.keys - 1))
				{
					gottaHitNote = !section.mustHitSection;
				}
				{
					var realTime = daStrumTime + ClientPrefs.noteOffset;
					
					var last = (gottaHitNote ? lastBFNotes : lastDadNotes)[daNoteData];
					if (last != null)
					{
						if (Math.abs(realTime - last.strumTime) <= 3)
						{
							continue;
						}
					}
				}
				
				var oldNote:Note = null;
				
				var pixelStage = isPixelStage;
				// var skin = arrowSkin;
				
				var type:Dynamic = songNotes[3];
				if (!Std.isOfType(type, String)) type = ChartingState.noteTypeList[type];
				
				// TODO: maybe make a checkNoteType n shit but idfk im lazy
				// or maybe make a "Transform Notes" event which'll make notes which don't change texture change into the specified one
				
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, gottaHitNote ? 0 : 1);
				swagNote.row = Conductor.secsToRow(daStrumTime);
				var rowArray = noteRows[gottaHitNote ? 0 : 1];
				if (rowArray[swagNote.row] == null) rowArray[swagNote.row] = [];
				rowArray[swagNote.row].push(swagNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				if (gottaHitNote)
				{
					lastBFNotes[daNoteData] = swagNote;
				}
				else
				{
					lastDadNotes[daNoteData] = swagNote;
				}
				
				var dataToCheck:Int = songNotes[1];
				if (songData.lanes > 1)
				{
					if (gottaHitNote) swagNote.lane = 0;
					if (!gottaHitNote) swagNote.lane = 1;
					
					if (dataToCheck > Std.int((SONG.keys * 2) - 1)) swagNote.lane = Std.int(Math.max(Math.floor(dataToCheck / SONG.keys), -1));
				}
				else swagNote.lane = 0;
				
				swagNote.gfNote = (section.gfSection && (songNotes[1] < SONG.keys));
				
				swagNote.noteType = type;
				
				swagNote.scrollFactor.set();
				// swagNote.player = gottaHitNote ? 0 : 1;
				
				var susLength:Float = swagNote.sustainLength;
				
				susLength = susLength / Conductor.stepCrotchet;
				swagNote.ID = unspawnNotes.length;
				modchartObjects.set('note${swagNote.ID}', swagNote);
				unspawnNotes.push(swagNote);
				
				if (swagNote.noteScript != null && swagNote.noteScript.scriptType == LUA)
				{
					callScript(swagNote.noteScript, 'setupNote', [
						unspawnNotes.indexOf(swagNote),
						Math.abs(swagNote.noteData),
						swagNote.noteType,
						swagNote.isSustainNote,
						swagNote.ID
					]);
				}
				
				var floorSus:Int = Math.round(susLength);
				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						
						var sustainNote:Note = new Note(daStrumTime
							+ (Conductor.stepCrotchet * susNote)
							+ (Conductor.stepCrotchet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true,
							false, gottaHitNote ? 0 : 1);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.noteType = type;
						if (!sustainNote.alive) break;
						sustainNote.ID = unspawnNotes.length;
						modchartObjects.set('note${sustainNote.ID}', sustainNote);
						sustainNote.scrollFactor.set();
						sustainNote.lane = swagNote.lane;
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						// sustainNote.player = sustainNote.parent.player;
						unspawnNotes.push(sustainNote);
						if (sustainNote.noteScript != null && sustainNote.noteScript.scriptType == LUA)
						{
							callScript(sustainNote.noteScript, 'setupNote', [
								unspawnNotes.indexOf(sustainNote),
								Math.abs(sustainNote.noteData),
								sustainNote.noteType,
								sustainNote.isSustainNote,
								sustainNote.ID
							]);
						}
						
						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if (ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if (daNoteData > 1) // Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}
				
				// arrowSkin = skin;
				
				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if (ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if (daNoteData > 1) // Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}
			}
			daBeats += 1;
		}
		
		#if debug
		trace('loadingChart took: ' + (Sys.time() - cpuTime));
		#end
		
		lastDadNotes = null;
		lastBFNotes = null;
		
		unspawnNotes.sort(SortUtil.sortByStrumTime);
		
		checkEventNote();
		generatedMusic = true;
	}
	
	public function getNoteInitialTime(time:Float)
	{
		var event:SpeedEvent = getSV(time);
		return getTimeFromSV(time, event);
	}
	
	public inline function getTimeFromSV(time:Float, event:SpeedEvent) return event.position
		+ (modManager.getBaseVisPosD(time - event.songTime, 1) * event.speed);
		
	public function getSV(time:Float)
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
	
	function eventPushed(event:EventNote)
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
				callEventScript(event.event, 'onPush', [event], [event.value1, event.value2]);
		}
		callOnScripts('onEventPush', [event]);
	}
	
	function firstNotePush(type:String)
	{
		switch (type)
		{
			default:
				if (notetypeScripts.exists(type))
				{
					var script:Dynamic = notetypeScripts.get(type);
					callScript(script, "onLoad", []);
				}
		}
	}
	
	function firstEventPush(event:EventNote)
	{
		switch (event.event)
		{
			default:
				callEventScript(event.event, 'firstPush', [event], [event.value1, event.value2]);
		}
	}
	
	function eventNoteEarlyTrigger(event:EventNote):Float
	{
		var returnValue:Dynamic = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2]);
		if (returnValue != Globals.Function_Continue)
		{
			return returnValue;
		}
		
		returnValue = callEventScript(event.event, 'offsetStrumtime', [event], [event.value1, event.value2]);
		if (returnValue != Globals.Function_Continue)
		{
			return returnValue;
		}
		
		switch (event.event)
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		
		return 0;
	}
	
	public var skipArrowStartTween:Bool = false; // for lua
	
	function removeStatics(player:Int)
	{
		var isPlayer:Bool = player == 1;
		for (field in playFields.members)
		{
			if (field.isPlayer == isPlayer || player == -1)
			{
				field.clearReceptors();
			}
		}
	}
	
	// player 0 is opponent player 1 is player. Set to -1 to affect both players
	
	function resetStrumPositions(player:Int, ?baseX:Float)
	{
		if (!generatedMusic) return;
		
		var isPlayer:Bool = player == 1;
		for (field in playFields.members)
		{
			if (field.isPlayer == isPlayer || player == -1)
			{
				var x = field.baseX;
				if (baseX != null) x = baseX;
				
				field.forEachAlive(function(strum:StrumNote) {
					strum.x = x;
					strum.postAddedToGroup();
					if (field.offsetReceptors) field.doReceptorOffset(strum);
				});
			}
		}
	}
	
	function regenStaticArrows(player:Int)
	{
		var isPlayer:Bool = player == 1;
		for (field in playFields.members)
		{
			if (field.isPlayer == isPlayer || player == -1)
			{
				field.generateReceptors();
				field.fadeIn(true);
			}
		}
	}
	
	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}
			
			FlxTimer.globalManager.forEach((i:FlxTimer) -> if (!i.finished) i.active = false);
			FlxTween.globalManager.forEach((i:FlxTween) -> if (!i.finished) i.active = false);
			
			#if VIDEOS_ALLOWED
			forEachOfType(FunkinVideoSprite, video -> if (video != null && video.isStateAffected) video.pause(), true);
			#end
			
			for (i in playFields.members)
			{
				if (i.inControl && i.playerControls)
				{
					for (s in i.members)
					{
						if (s.animation.curAnim?.name != 'static')
						{
							s.playAnim('static');
							s.resetAnim = 0;
						}
					}
				}
			}
		}
		callOnHScripts('onSubstateOpen', []);
		super.openSubState(SubState);
	}
	
	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}
			
			FlxTimer.globalManager.forEach((i:FlxTimer) -> if (!i.finished) i.active = true);
			FlxTween.globalManager.forEach((i:FlxTween) -> if (!i.finished) i.active = true);
			
			#if VIDEOS_ALLOWED
			forEachOfType(FunkinVideoSprite, video -> if (video != null && video.isStateAffected) video.resume(), true);
			#end
			
			paused = false;
			callOnScripts('onResume', []);
			
			#if DISCORD_ALLOWED
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, FlxG.random.getObject(DiscordClient.discordPresences), null, true, songLength
					- Conductor.songPosition
					- ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, FlxG.random.getObject(DiscordClient.discordPresences));
			}
			#end
		}
		callOnHScripts('onSubstateClose', []);
		super.closeSubState();
	}
	
	override public function onFocus():Void
	{
		#if DISCORD_ALLOWED
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, FlxG.random.getObject(DiscordClient.discordPresences), null, true, songLength
					- Conductor.songPosition
					- ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, FlxG.random.getObject(DiscordClient.discordPresences));
			}
		}
		#end
		
		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if DISCORD_ALLOWED
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, FlxG.random.getObject(DiscordClient.discordPresences));
		}
		#end
		
		super.onFocusLost();
	}
	
	function resyncVocals():Void
	{
		if (finishTimer != null) return;
		
		vocals.pause();
		
		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		
		vocals.time = Conductor.songPosition;
		vocals.play(false, Conductor.songPosition);
	}
	
	public var paused:Bool = false;
	public var canReset:Bool = true;
	
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	
	override public function update(elapsed:Float)
	{
		if (!inCutscene)
		{
			final lerpRate = 0.04 * cameraSpeed;
			FlxG.camera.followLerp = lerpRate;
			
			if (!startingSong && !endingSong && !boyfriend.isAnimNull() && boyfriend.getAnimName().startsWith('idle'))
			{
				boyfriendIdleTime += elapsed;
				if (boyfriendIdleTime >= 0.15)
				{ // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			}
			else
			{
				boyfriendIdleTime = 0;
			}
		}
		
		if (generatedMusic && !endingSong && !isCameraOnForcedPos) moveCameraSection();
		
		for (key in notetypeScripts.keys())
			notetypeScripts.get(key).call('update', [elapsed]);
		for (key in eventScripts.keys())
			eventScripts.get(key).call('update', [elapsed]);
			
		callOnHScripts('update', [elapsed]);
		callOnScripts('onUpdate', [elapsed]);
		
		super.update(elapsed);
		
		currentSV = getSV(Conductor.songPosition);
		Conductor.visualPosition = getVisualPosition();
		checkEventNote();
		
		setOnHScripts('curDecStep', curDecStep);
		setOnHScripts('curDecBeat', curDecBeat);
		setOnHScripts('curStep', curStep);
		setOnHScripts('curBeat', curBeat);
		
		if (controls.PAUSE && startedCountdown && canPause)
		{
			final ret:Dynamic = callOnScripts('onPause', []);
			if (ret != Globals.Function_Stop) openPauseMenu();
		}
		
		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene) openChartEditor();
		
		if (FlxG.keys.justPressed.NINE) openNoteskinEditor();
		if (FlxG.keys.justPressed.F4 && vocals != null && FlxG.sound.music != null) resyncVocals();
		
		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene)
		{
			persistentUpdate = false;
			paused = true;
			CoolUtil.cancelMusicFadeTween();
			FlxG.switchState(() -> new CharacterEditorState(SONG.player2));
		}
		
		if (health > healthBounds.max) health = healthBounds.max;
		
		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0) startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;
			
			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;
				
				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}
			}
		}
		
		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom + defaultCamZoomAdd, FlxG.camera.zoom, Math.exp(-elapsed * 6.25 * camZoomingDecay));
			camHUD.zoom = FlxMath.lerp(defaultHudZoom, camHUD.zoom, Math.exp(-elapsed * 6.25 * camZoomingDecay));
		}
		
		if (!ClientPrefs.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		
		doDeathCheck();
		
		modManager.updateTimeline(curDecStep);
		modManager.update(elapsed);
		
		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime; // shit be werid on 4:3
			if (songSpeed < 1) time /= songSpeed;
			
			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				var doSpawn:Bool = true;
				if (dunceNote.noteScript != null && dunceNote.noteScript.scriptType == LUA)
				{
					doSpawn = callScript(dunceNote.noteScript, "spawnNote", [dunceNote]) != Globals.Function_Stop;
				}
				if (doSpawn) doSpawn = callOnHScripts('onSpawnNote', [dunceNote]) != Globals.Function_Stop;
				if (doSpawn)
				{
					var desiredPlayfield = playFields.members[dunceNote.lane];
					if (desiredPlayfield != null) playFields.members[dunceNote.lane].addNote(dunceNote);
					else
					{
						if (dunceNote.desiredPlayfield != null) dunceNote.desiredPlayfield.addNote(dunceNote);
						else if (dunceNote.parent != null && dunceNote.parent.playField != null) dunceNote.parent.playField.addNote(dunceNote);
						else
						{
							for (field in playFields.members)
							{
								if (field.isPlayer == dunceNote.mustPress)
								{
									field.addNote(dunceNote);
									break;
								}
							}
						}
					}
					if (dunceNote.playField == null)
					{
						var deadNotes:Array<Note> = [dunceNote];
						for (note in dunceNote.tail)
							deadNotes.push(note);
							
						for (note in deadNotes)
						{
							note.active = false;
							note.visible = false;
							note.ignoreNote = true;
							
							if (modchartObjects.exists('note${note.ID}')) modchartObjects.remove('note${note.ID}');
							note.kill();
							unspawnNotes.remove(note);
							note.destroy();
						}
						break;
					}
					notes.insert(0, dunceNote);
					dunceNote.spawned = true;
					var index:Int = unspawnNotes.indexOf(dunceNote);
					unspawnNotes.splice(index, 1);
					callOnLuas('onSpawnNote', [
						notes.members.indexOf(dunceNote),
						dunceNote.noteData,
						dunceNote.noteType,
						dunceNote.isSustainNote,
						dunceNote.ID
					]);
					callOnHScripts('onSpawnNotePost', [dunceNote]);
					if (dunceNote.noteScript != null)
					{
						var script:Dynamic = dunceNote.noteScript;
						if (script.scriptType == LUA)
						{
							callScript(script, 'postSpawnNote', [
								notes.members.indexOf(dunceNote),
								Math.abs(dunceNote.noteData),
								dunceNote.noteType,
								dunceNote.isSustainNote,
								dunceNote.ID
							]);
						}
						else
						{
							callScript(script, "postSpawnNote", [dunceNote]);
						}
					}
				}
				else
				{
					var deadNotes:Array<Note> = [dunceNote];
					for (note in dunceNote.tail)
						deadNotes.push(note);
						
					for (note in deadNotes)
					{
						note.active = false;
						note.visible = false;
						note.ignoreNote = true;
						
						if (modchartObjects.exists('note${note.ID}')) modchartObjects.remove('note${note.ID}');
						note.kill();
						unspawnNotes.remove(note);
						note.destroy();
					}
				}
			}
		}
		
		if (startedCountdown)
		{
			opponentStrums.forEachAlive(function(strum:StrumNote) {
				var pos = modManager.getPos(0, 0, 0, curDecBeat, strum.noteData, 1, strum, [], strum.vec3Cache);
				modManager.updateObject(curDecBeat, strum, pos, 1);
				strum.x = pos.x + script_STRUMOffsets[strum.noteData].x;
				strum.y = pos.y + script_STRUMOffsets[strum.noteData].y;
			});
			
			playerStrums.forEachAlive(function(strum:StrumNote) {
				var pos = modManager.getPos(0, 0, 0, curDecBeat, strum.noteData, 0, strum, [], strum.vec3Cache);
				modManager.updateObject(curDecBeat, strum, pos, 0);
				strum.x = pos.x + script_STRUMOffsets[strum.noteData].x;
				strum.y = pos.y + script_STRUMOffsets[strum.noteData].y;
			});
			
			if (extraFields.length > 0)
			{
				for (extra in 2...SONG.lanes)
				{
					extraFields[extra - 2].forEachAlive(function(strum:StrumNote) {
						var pos = modManager.getPos(0, 0, 0, curDecBeat, strum.noteData, extra, strum, [], strum.vec3Cache);
						modManager.updateObject(curDecBeat, strum, pos, extra);
						strum.x = pos.x + script_STRUMOffsets[strum.noteData].x;
						strum.y = pos.y + script_STRUMOffsets[strum.noteData].y;
					});
				}
			}
		}
		
		if (generatedMusic)
		{
			if (!inCutscene)
			{
				if (!cpuControlled)
				{
					keyShit();
				}
				else if (boyfriend.holdTimer > Conductor.stepCrotchet * 0.0011 * boyfriend.singDuration
					&& boyfriend.getAnimName().startsWith('sing')
					&& !boyfriend.getAnimName().endsWith('miss'))
				{
					boyfriend.dance();
				}
			}
			
			notes.forEachAlive(function(daNote:Note) {
				if (daNote.lane > (SONG.lanes - 1)) return;
				
				final field = daNote.playField;
				
				final visPos = -((Conductor.visualPosition - daNote.visualTime) * songSpeed);
				final pos = modManager.getPos(daNote.strumTime, visPos, daNote.strumTime - Conductor.songPosition, curDecBeat, daNote.noteData, daNote.lane, daNote, null, daNote.vec3Cache);
				
				modManager.updateObject(curDecBeat, daNote, pos, daNote.lane);
				pos.x += daNote.offsetX;
				pos.y += daNote.offsetY;
				daNote.x = pos.x;
				daNote.y = pos.y;
				
				if (daNote.isSustainNote)
				{
					final futureSongPos = Conductor.visualPosition + (Conductor.stepCrotchet * 0.001);
					final diff = daNote.visualTime - futureSongPos;
					final vDiff = -((futureSongPos - daNote.visualTime) * songSpeed);
					
					var nextPos = modManager.getPos(daNote.strumTime, vDiff, diff, Conductor.getStep(futureSongPos) / 4, daNote.noteData, daNote.lane, daNote, [], daNote.vec3Cache);
					nextPos.x += daNote.offsetX;
					nextPos.y += daNote.offsetY;
					
					final diffX = (nextPos.x - pos.x);
					final diffY = (nextPos.y - pos.y);
					
					final rad = Math.atan2(diffY, diffX);
					
					final deg = rad * (180 / Math.PI);
					
					if (deg != 0) daNote.mAngle = (deg + 90);
					else daNote.mAngle = 0;
					
					daNote.x += script_SUSTAINOffsets[daNote.noteData].x;
					daNote.y += script_SUSTAINOffsets[daNote.noteData].y;
					if (daNote.animation.curAnim.name.endsWith('end${daNote.noteData}'))
					{
						daNote.x += script_SUSTAINENDOffsets[daNote.noteData].x;
						daNote.y += script_SUSTAINENDOffsets[daNote.noteData].y;
					}
				}
				
				daNote.x += script_NOTEOffsets[daNote.noteData].x;
				daNote.y += script_NOTEOffsets[daNote.noteData].y;
				
				if (field.inControl && field.autoPlayed)
				{
					if (!daNote.wasGoodHit && !daNote.ignoreNote)
					{
						if (daNote.isSustainNote)
						{
							if (daNote.canBeHit) field.noteHitCallback.dispatch(daNote, field);
						}
						else
						{
							if (daNote.strumTime <= Conductor.songPosition) field.noteHitCallback.dispatch(daNote, field);
						}
					}
				}
				
				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
				{
					daNote.garbage = true;
					if (daNote.playField != null && daNote.playField.playerControls && !daNote.playField.autoPlayed && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
					{
						if (field.playerControls && !field.autoPlayed) field.noteMissCallback.dispatch(daNote, field);
					}
				}
				
				if (daNote.garbage)
				{
					daNote.active = false;
					daNote.visible = false;
					
					disposeNote(daNote);
				}
			});
		}
		
		for (i in followingCams)
		{
			i.zoom = FlxG.camera.zoom;
			i.scroll.copyFrom(FlxG.camera.scroll);
		}
		
		#if debug
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();
				FlxG.sound.music.onComplete();
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
		#end
		
		callOnScripts('onUpdatePost', [elapsed]);
	}
	
	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;
		
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}
		openSubState(new PauseSubState());
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence(detailsPausedText, FlxG.random.getObject(DiscordClient.discordPresences));
		#end
	}
	
	function openChartEditor()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		CoolUtil.cancelMusicFadeTween();
		
		FlxG.switchState(ChartingState.new);
		chartingMode = true;
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}
	
	function openNoteskinEditor()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		CoolUtil.cancelMusicFadeTween();
		
		FlxG.switchState(() -> new NoteSkinEditor(((ClientPrefs.noteSkin.contains('Quant')
			&& noteSkin.data.hasQuants) ? 'QUANT${SONG.arrowSkin}' : SONG.arrowSkin), noteSkin));
		chartingMode = true;
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Noteskin Editor", null, null, true);
		#end
	}
	
	public function updateScoreBar(miss:Bool = false)
	{
		final scoreRetVal:Dynamic = callOnScripts('onUpdateScore', [miss]);
		if (scoreRetVal != Globals.Function_Stop) callHUDFunc(hud -> hud.onUpdateScore(songScore, funkin.utils.MathUtil.floorDecimal(ratingPercent * 100, 2), songMisses, miss));
	}
	
	public var isDead:Bool = false; // Don't mess with this on Lua!!!
	
	function doDeathCheck(?skipHealthCheck:Bool = false)
	{
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			final ret:Dynamic = callOnScripts('onGameOver', []);
			if (ret != Globals.Function_Stop)
			{
				boyfriend.stunned = true;
				deathCounter++;
				
				paused = true;
				
				vocals.stop();
				FlxG.sound.music.stop();
				
				persistentUpdate = false;
				persistentDraw = false;
				
				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();
				
				openSubState(new GameOverSubstate());
				
				#if DISCORD_ALLOWED
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, FlxG.random.getObject(DiscordClient.discordPresences));
				#end
				
				isDead = true;
				totalBeat = 0;
				return true;
			}
		}
		return false;
	}
	
	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			final leStrumTime:Float = eventNotes[0].strumTime;
			
			if (Conductor.songPosition < leStrumTime)
			{
				break;
			}
			
			final value1:String = eventNotes[0].value1 ?? '';
			final value2:String = eventNotes[0].value2 ?? '';
			
			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}
	
	function changeCharacter(name:String, charType:Int)
	{
		switch (charType)
		{
			case 0:
				if (boyfriend.curCharacter != name)
				{
					var oldChar = boyfriend;
					if (!boyfriendMap.exists(name))
					{
						addCharacterToList(name, charType);
					}
					
					var lastAlpha:Float = boyfriend.alpha;
					boyfriend.alpha = 0.00001;
					boyfriend = boyfriendMap.get(name);
					boyfriend.alpha = lastAlpha;
					for (field in playFields.members)
					{
						if (field.owner == oldChar) field.owner = boyfriend;
					}
				}
				setOnLuas('boyfriendName', boyfriend.curCharacter);
				setOnScripts('boyfriend', boyfriend);
				setOnScripts('boyfriendGroup', boyfriendGroup);
				
			case 1:
				if (dad.curCharacter != name)
				{
					var oldChar = dad;
					if (!dadMap.exists(name))
					{
						addCharacterToList(name, charType);
					}
					
					var wasGf:Bool = dad.curCharacter.startsWith('gf');
					var lastAlpha:Float = dad.alpha;
					dad.alpha = 0.00001;
					dad = dadMap.get(name);
					if (!dad.curCharacter.startsWith('gf'))
					{
						if (wasGf && gf != null)
						{
							gf.visible = true;
						}
					}
					else if (gf != null)
					{
						gf.visible = false;
					}
					dad.alpha = lastAlpha;
					for (field in playFields.members)
					{
						if (field.owner == oldChar) field.owner = dad;
					}
				}
				setOnLuas('dadName', dad.curCharacter);
				setOnScripts('dad', dad);
				setOnScripts('dadGroup', dadGroup);
				
			case 2:
				if (gf != null)
				{
					if (gf.curCharacter != name)
					{
						var oldChar = gf;
						if (!gfMap.exists(name))
						{
							addCharacterToList(name, charType);
						}
						
						var lastAlpha:Float = gf.alpha;
						gf.alpha = 0.00001;
						gf = gfMap.get(name);
						gf.alpha = lastAlpha;
						for (field in playFields.members)
						{
							if (field.owner == oldChar) field.owner = gf;
						}
					}
					setOnLuas('gfName', gf.curCharacter);
					setOnScripts('gf', gf);
					setOnScripts('gfGroup', gfGroup);
				}
		}
		callHUDFunc(hud -> hud.onCharacterChange());
	}
	
	public function triggerEventNote(eventName:String, value1:String, value2:String)
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
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					}
					else if (gf != null)
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				if (value != 1)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
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
					
					if (duration > 0)
					{
						FlxTween.tween(FlxG.camera, {zoom: targetZoom}, duration, {ease: FlxEase.circOut});
					}
					else
					{
						FlxG.camera.zoom = targetZoom;
					}
				}
				defaultCamZoom = targetZoom;
				setOnHScripts('defaultCamZoom', defaultCamZoom);
				
			case 'HUD Fade':
				FlxTween.cancelTweensOf(camHUD, ['alpha']);
				
				var leAlpha:Float = Std.parseFloat(value1);
				if (Math.isNaN(leAlpha)) leAlpha = 1;
				
				var duration:Float = Std.parseFloat(value2);
				if (Math.isNaN(duration)) duration = 1;
				
				if (duration > 0)
				{
					FlxTween.tween(camHUD, {alpha: leAlpha}, duration);
				}
				else
				{
					camHUD.alpha = leAlpha;
				}
			case 'Play Animation':
				// trace('Anim to play: ' + value1);
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
					
					if (duration > 0 && intensity != 0)
					{
						targetsArray[i].shake(intensity, duration);
					}
				}
				
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
				
				if (val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2,
						{
							ease: FlxEase.linear,
							onComplete: function(twn:FlxTween) {
								songSpeedTween = null;
							}
						});
				}
				
			case 'Camera Zoom Chain':
				var split1:Array<String> = value1.split(',');
				var gameZoom:Float = Std.parseFloat(split1[0].trim());
				var hudZoom:Float = Std.parseFloat(split1[1].trim());
				
				if (!Math.isNaN(gameZoom)) gameZ = 0.015;
				if (!Math.isNaN(hudZoom)) hudZ = 0.03;
				
				if (split1.length == 4)
				{
					var shGame:Float = Std.parseFloat(split1[2].trim());
					var shHUD:Float = Std.parseFloat(split1[3].trim());
					
					if (!Math.isNaN(shGame)) gameShake = shGame;
					if (!Math.isNaN(shHUD)) hudShake = shHUD;
					shakeTime = true;
				}
				else
				{
					shakeTime = false;
				}
				
				var split2:Array<String> = value2.split(',');
				var toBeat:Int = Std.parseInt(split2[0].trim());
				var tiBeat:Float = Std.parseFloat(split2[1].trim());
				
				if (Math.isNaN(toBeat)) toBeat = 4;
				if (Math.isNaN(tiBeat)) tiBeat = 1;
				
				totalBeat = toBeat;
				timeBeat = tiBeat;
				
			case 'Screen Shake Chain':
				var split1:Array<String> = value1.split(',');
				var gmShake:Float = Std.parseFloat(split1[0].trim());
				var hdShake:Float = Std.parseFloat(split1[1].trim());
				
				if (!Math.isNaN(gmShake)) gameShake = gmShake;
				if (!Math.isNaN(hdShake)) hudShake = hdShake;
				
				var toBeat:Int = Std.parseInt(value2);
				if (!Math.isNaN(toBeat)) totalShake = 4;
				
				totalShake = toBeat;
				
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
				var killMe:Array<String> = value1.split('.');
				if (killMe.length > 1)
				{
					Reflect.setProperty(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length - 1], value2);
				}
				else
				{
					Reflect.setProperty(this, value1, value2);
				}
		}
		
		callOnScripts('onEvent', [eventName, value1, value2]);
		
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
				final displacement = gf.returnDisplacePoint();
				
				camFollow.x += displacement.x;
				camFollow.y += displacement.y;
				
				displacement.putWeak();
			}
			
			callOnScripts('onMoveCamera', ['gf']);
			setOnScripts('whosTurn', 'gf');
			return;
		}
		
		var isDad = !SONG.notes[curSection].mustHitSection;
		moveCamera(isDad);
		callOnScripts('onMoveCamera', [isDad ? 'dad' : 'boyfriend']);
	}
	
	public function getCharacterCameraPos(char:Character)
	{
		var desiredPos = char.getMidpoint();
		if (char.isPlayer)
		{
			desiredPos.x -= 100 + (char.cameraPosition[0] - boyfriendCameraOffset[0]);
			desiredPos.y += -100 + char.cameraPosition[1] + boyfriendCameraOffset[1];
		}
		else
		{
			desiredPos.x += 150 + char.cameraPosition[0] + opponentCameraOffset[0];
			desiredPos.y += -100 + char.cameraPosition[1] + opponentCameraOffset[1];
		}
		
		return desiredPos;
	}
	
	public function moveCamera(isDad:Bool)
	{
		var desiredPos:FlxPoint = null;
		var curCharacter:Character = null;
		
		if (opponentStrums != null && playerStrums != null) curCharacter = isDad ? opponentStrums.owner : playerStrums.owner;
		else curCharacter = isDad ? dad : boyfriend;
		
		if (camCurTarget != null) curCharacter = camCurTarget;
		
		desiredPos = getCharacterCameraPos(curCharacter);
		
		camFollow.x = desiredPos.x;
		camFollow.y = desiredPos.y;
		
		if (ClientPrefs.camFollowsCharacters)
		{
			final displacement = curCharacter.returnDisplacePoint();
			
			camFollow.x += displacement.x;
			camFollow.y += displacement.y;
			
			displacement.putWeak();
		}
		
		desiredPos.put();
		
		setOnScripts('whosTurn', isDad ? 'dad' : 'boyfriend');
	}
	
	/**
	 * 'Snaps the camera to a position.'
	 * @param lockPosition 'if true, locks the camera position after snapping.'
	 */
	function snapCamToPos(x:Float = 0, y:Float = 0, lockPosition:Bool = false)
	{
		camFollow.setPosition(x, y);
		FlxG.camera.snapToTarget();
		if (lockPosition) isCameraOnForcedPos = true;
	}
	
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		
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
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss;
				}
			}
			
			if (doDeathCheck())
			{
				return;
			}
		}
		
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;
		
		deathCounter = 0;
		seenCutscene = false;
		
		#if ACHIEVEMENTS_ALLOWED
		if (achievementObj != null)
		{
			return;
		}
		else
		{
			var achieve:String = checkForAchievement([
				'week1_nomiss',
				'week2_nomiss',
				'week3_nomiss',
				'week4_nomiss',
				'week5_nomiss',
				'week6_nomiss',
				'ur_bad',
				'ur_good',
				'hype',
				'two_keys',
				'toastie',
				'debugger'
			]);
			
			if (achieve != null)
			{
				startAchievement(achieve);
				return;
			}
		}
		#end
		
		#if LUA_ALLOWED
		final ret:Dynamic = callOnScripts('onEndSong', []);
		#else
		final ret:Dynamic = Globals.Function_Continue;
		#end
		
		if (ret != Globals.Function_Stop && !transitioning)
		{
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if (Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}
			
			if (chartingMode)
			{
				openChartEditor();
				return;
			}
			
			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;
				
				storyPlaylist.remove(storyPlaylist[0]);
				
				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					FlxG.sound.music.volume = 1;
					
					CoolUtil.cancelMusicFadeTween();
					FlxG.switchState(() -> new StoryMenuState());
					
					if (!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false))
					{
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
						
						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}
						
						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					
					prevCamFollow = camFollow;
					
					final difficulty:String = Difficulty.getDifficultyFilePath();
					final songLowercase = Paths.formatToSongPath(storyPlaylist[0].toLowerCase());
					
					trace('LOADING: ' + Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);
					
					PlayState.SONG = Song.loadFromJson(songLowercase + difficulty, songLowercase);
					FlxG.sound.music.stop();
					
					CoolUtil.cancelMusicFadeTween();
					CoolUtil.loadAndSwitchState(PlayState.new);
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				CoolUtil.cancelMusicFadeTween();
				FlxG.switchState(() -> new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				FlxG.sound.music.volume = 1;
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}
	
	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	
	function startAchievement(achieve:String)
	{
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	
	function achievementEnd():Void
	{
		achievementObj = null;
		if (endingSong && !inCutscene)
		{
			endSong();
		}
	}
	#end
	
	public function KillNotes()
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
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		
		if (soundMode == 'SWAP')
		{
			vocals.playerVolume = 1;
			FlxG.sound.music.volume = 0;
		}
		else
		{
			vocals.playerVolume = 1;
		}
		
		// tryna do MS based judgment due to popular demand
		var daRating:Rating = Rating.judgeNote(note, noteDiff);
		var judgeScore:Int = daRating.score;
		
		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if (!note.ratingDisabled) daRating.increase();
		note.rating = daRating.name;
		
		if (daRating.noteSplash && !note.noteSplashDisabled && noteSkin.data.splashesEnabled)
		{
			spawnNoteSplashOnNote(note);
		}
		
		var field:PlayField = note.playField;
		
		if (!practiceMode && !field.autoPlayed)
		{
			if (defaultScoreAddition) songScore += judgeScore;
			if (!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}
		// If you're looking for the ratings graphics its done in the PlayHUDs now
		callOnHScripts('popupScore', [note, daRating]);
		callHUDFunc(hud -> hud.popUpScore(daRating.image, combo)); // only pushing the image bc is anyone ever gonna need anything else???
		callOnHScripts('popupScorePost', [note, daRating]);
	}
	
	function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		// trace('Pressed: ' + eventKey);
		if (cpuControlled || paused || !startedCountdown) return;
		
		if (key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if (!boyfriend.stunned && generatedMusic && !endingSong)
			{
				// more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;
				
				var canMiss:Bool = !ClientPrefs.ghostTapping;
				
				var pressNotes:Array<Note> = [];
				
				var ghostTapped:Bool = true;
				for (field in playFields.members)
				{
					if (field.playerControls && field.inControl && !field.autoPlayed)
					{
						var sortedNotesList:Array<Note> = field.getTapNotes(key);
						sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
						
						if (sortedNotesList.length > 0)
						{
							pressNotes.push(sortedNotesList[0]);
							field.noteHitCallback.dispatch(sortedNotesList[0], field);
						}
					}
				}
				
				if (pressNotes.length == 0)
				{
					callOnScripts('onGhostTap', [key]);
					if (canMiss)
					{
						noteMissPress(key);
						callOnScripts('noteMissPress', [key]);
					}
				}
				
				// this is for the "Just the Two of Us" achievement - Shadow Mario
				keysPressed[key] = true;
				
				// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}
			
			for (field in playFields.members)
			{
				if (field.inControl && !field.autoPlayed && field.playerControls)
				{
					var spr:StrumNote = field.members[key];
					if (spr != null && spr.animation.curAnim.name != 'confirm')
					{
						spr.playAnim('pressed');
						spr.resetAnim = 0;
					}
				}
			}
			
			callOnScripts('onKeyPress', [key]);
		}
	}
	
	function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if (startedCountdown && !paused && key > -1)
		{
			for (field in playFields.members)
			{
				if (field.inControl && !field.autoPlayed && field.playerControls)
				{
					var spr:StrumNote = field.members[key];
					if (spr != null)
					{
						spr.playAnim('static');
						spr.resetAnim = 0;
					}
				}
			}
			callOnScripts('onKeyRelease', [key]);
		}
	}
	
	function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}
	
	// Hold notes
	function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var dodge = controls.NOTE_DODGE;
		
		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [
				controls.NOTE_LEFT_P,
				controls.NOTE_DOWN_P,
				controls.NOTE_UP_P,
				controls.NOTE_RIGHT_P
			];
			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i]) onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}
		
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			
			notes.forEachAlive(function(daNote:Note) {
				// hold note functions
				if (!daNote.playField.autoPlayed && daNote.playField.inControl && daNote.playField.playerControls)
				{
					if (daNote.isSustainNote
						&& FlxG.keys.anyPressed(keysArray[daNote.noteData])
						&& daNote.canBeHit
						&& !daNote.tooLate
						&& !daNote.wasGoodHit)
					{
						daNote.playField.noteHitCallback.dispatch(daNote, daNote.playField);
					}
				}
			});
			
			if (keysArray.contains(true) && !endingSong)
			{
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null)
				{
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.holdTimer > Conductor.stepCrotchet * 0.0011 * boyfriend.singDuration
				&& boyfriend.getAnimName().startsWith('sing')
				&& !boyfriend.getAnimName().endsWith('miss'))
			{
				boyfriend.dance();
			}
		}
		
		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [
				controls.NOTE_LEFT_R,
				controls.NOTE_DOWN_R,
				controls.NOTE_UP_R,
				controls.NOTE_RIGHT_R
			];
			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i]) onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}
	
	function noteMiss(daNote:Note, field:PlayField):Void
	{ // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note
				&& field.playerControls
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
			{
				disposeNote(note);
			}
		});
		if (daNote.canMiss) return;
		
		combo = 0;
		health -= daNote.missHealth * healthLoss;
		
		if (soundMode == 'SWAP') FlxG.sound.music.volume = 1;
		
		if (instakillOnMiss)
		{
			vocals.playerVolume = 0;
			doDeathCheck(true);
		}
		
		songMisses++;
		vocals.playerVolume = 0;
		if (!practiceMode) songScore -= 10;
		
		totalPlayed++;
		RecalculateRating(field.playerControls);
		
		var char:Character = field.owner;
		if (daNote.gfNote) char = gf;
		
		if (char != null && !daNote.noMissAnimation)
		{
			if (char.animTimer <= 0 && !char.voicelining)
			{
				var daAlt = '';
				if (daNote.noteType == 'Alt Animation') daAlt = '-alt';
				
				var animToPlay:String = noteSkin.data.singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
				char.playAnim(animToPlay, true);
			}
		}
		
		callOnLuas('noteMiss', [
			notes.members.indexOf(daNote),
			daNote.noteData,
			daNote.noteType,
			daNote.isSustainNote,
			daNote.ID
		]);
		callOnHScripts("noteMiss", [daNote]);
		if (daNote.noteScript != null)
		{
			var script:Dynamic = daNote.noteScript;
			if (script.scriptType == LUA)
			{
				callScript(script, 'noteMiss', [
					notes.members.indexOf(daNote),
					Math.abs(daNote.noteData),
					daNote.noteType,
					daNote.isSustainNote,
					daNote.ID
				]);
			}
			else
			{
				callScript(script, "noteMiss", [daNote]);
			}
		}
	}
	
	function noteMissPress(direction:Int = 1, anim:Bool = true):Void // You pressed a key when there was no notes to press for this key
	{
		if (ClientPrefs.ghostTapping) return; // fuck it
		
		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if (instakillOnMiss)
			{
				vocals.playerVolume = 0;
				doDeathCheck(true);
			}
			
			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;
			
			if (!practiceMode) songScore -= 10;
			if (!endingSong)
			{
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating();
			
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			
			if (anim)
			{
				if (boyfriend.animTimer <= 0 && !boyfriend.voicelining) boyfriend.playAnim(noteSkin.data.singAnimations[Std.int(Math.abs(direction))]
					+ 'miss', true);
			}
			vocals.playerVolume = 0;
		}
		callOnScripts('noteMissPress', [direction]);
	}
	
	function opponentNoteHit(note:Note, playfield:PlayField):Void
	{
		camZooming = true;
		
		callOnLuas('opponentNoteHitPre', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote, note.ID]);
		callOnHScripts("opponentNoteHitPre", [note]);
		
		var char:Character = note.owner == null ? playfield.owner : note.owner;
		
		if (note.gfNote) char = gf;
		
		if (note.noteType == 'Hey!' && char.animOffsets.exists('hey'))
		{
			char.playAnim('hey', true);
			char.specialAnim = true;
			char.heyTimer = 0.6;
		}
		
		if (!note.noteSplashDisabled && !note.isSustainNote && playfield.playerControls)
		{
			spawnNoteSplashOnNote(note);
		}
		else if (!note.noAnimation)
		{
			var altAnim:String = "";
			
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation')
				{
					altAnim = '-alt';
				}
			}
			
			var animToPlay:String = noteSkin.data.singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if (char.voicelining) char.voicelining = false;
			
			if (char != null)
			{
				char.holdTimer = 0;
				
				// TODO: maybe move this all away into a seperate function
				if (ClientPrefs.jumpGhosts
					&& char.ghostsEnabled
					&& !note.isSustainNote
					&& noteRows[note.mustPress ? 0 : 1][note.row] != null
					&& noteRows[note.mustPress ? 0 : 1][note.row].length > 1
					&& note.noteType != "Ghost Note")
				{
					// potentially have jump anims?
					var chord = noteRows[note.mustPress ? 0 : 1][note.row];
					var animNote = chord[0];
					var realAnim = noteSkin.data.singAnimations[Std.int(Math.abs(animNote.noteData))] + altAnim;
					if (char.mostRecentRow != note.row) char.playAnim(realAnim, true);
					
					if (note.nextNote != null && note.prevNote != null)
					{
						if (note != animNote
							&& !note.nextNote.isSustainNote /* && !note.prevNote.isSustainNote */
							&& callOnHScripts('onGhostAnim', [animToPlay, note]) != Globals.Function_Stop)
						{
							char.playGhostAnim(chord.indexOf(note), animToPlay, true);
						}
						else if (note.nextNote.isSustainNote)
						{
							char.playAnim(realAnim, true);
							char.playGhostAnim(chord.indexOf(note), animToPlay, true);
						}
					}
					char.mostRecentRow = note.row;
				}
				else
				{
					if (note.noteType != "Ghost Note") char.playAnim(animToPlay, true);
					else char.playGhostAnim(note.noteData, animToPlay, true);
				}
			}
		}
		
		if (SONG.needsVoices)
		{
			if (soundMode == 'SWAP') FlxG.sound.music.volume = 0;
			
			if (vocals.opponentVocals.length == 0) vocals.playerVolume = 1;
			else vocals.opponentVolume = 1;
		}
		
		if (playfield.autoPlayed)
		{
			var time:Float = 0.15;
			if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
			{
				time += 0.15;
			}
			if (playfield.playAnims) strumPlayAnim(playfield, Std.int(Math.abs(note.noteData)) % SONG.keys, time, note);
		}
		else
		{
			playfield.forEach(function(spr:StrumNote) {
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.playAnim('confirm', true, note);
				}
			});
		}
		
		note.hitByOpponent = true;
		
		final luaArgs:Array<Dynamic> = [
			notes.members.indexOf(note),
			Math.abs(note.noteData),
			note.noteType,
			note.isSustainNote,
			note.ID
		];
		final hscriptArgs = [note];
		
		callOnLuas('opponentNoteHit', luaArgs);
		callOnHScripts("opponentNoteHit", hscriptArgs);
		if (note.noteScript != null)
		{
			final script:Dynamic = note.noteScript;
			if (script.scriptType == LUA)
			{
				callScript(script, 'opponentNoteHit', luaArgs);
			}
			else
			{
				callScript(script, "opponentNoteHit", hscriptArgs);
			}
		}
		if (!note.isSustainNote)
		{
			disposeNote(note);
		}
	}
	
	function goodNoteHit(note:Note, field:PlayField):Void
	{
		callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote, note.ID]);
		callOnHScripts("goodNoteHitPre", [note]);
		
		if (!note.wasGoodHit)
		{
			if (field.autoPlayed && (note.ignoreNote || note.hitCausesMiss)) return;
			
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}
			
			if (field.autoPlayed)
			{
				var time:Float = 0.15;
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					time += 0.15;
				}
				if (field.playAnims) strumPlayAnim(field, Std.int(Math.abs(note.noteData)) % SONG.keys, time, note);
			}
			else
			{
				field.forEach(function(spr:StrumNote) {
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true, note);
					}
				});
			}
			
			if (note.hitCausesMiss)
			{
				field.noteMissCallback.dispatch(note, field);
				if (!note.noteSplashDisabled && !note.isSustainNote && field.playerControls)
				{
					spawnNoteSplashOnNote(note);
				}
				
				if (!note.noMissAnimation)
				{
					switch (note.noteType)
					{
						case 'Hurt Note': // Hurt note
							if (field.owner.animation.exists('hurt'))
							{
								field.owner.playAnim('hurt', true);
								field.owner.specialAnim = true;
							}
					}
				}
				
				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					disposeNote(note);
				}
				return;
			}
			
			if (!note.isSustainNote)
			{
				combo += 1;
				if (combo > 9999) combo = 9999;
				popUpScore(note);
			}
			health += note.hitHealth * healthGain;
			
			if (!note.noAnimation)
			{
				var daAlt = '';
				if (note.noteType == 'Alt Animation') daAlt = '-alt';
				
				var animToPlay:String = noteSkin.data.singAnimations[Std.int(Math.abs(note.noteData))];
				
				if (note.gfNote)
				{
					if (gf != null)
					{
						gf.playAnim(animToPlay + daAlt, true);
						gf.holdTimer = 0;
					}
				}
				else if (field.owner.animTimer <= 0 && !field.owner.voicelining)
				{
					field.owner.holdTimer = 0;
					if (ClientPrefs.jumpGhosts
						&& field.owner.ghostsEnabled
						&& !note.isSustainNote
						&& noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row] != null
						&& noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row].length > 1
						&& note.noteType != "Ghost Note")
					{
						// potentially have jump anims?
						var chord = noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row];
						var animNote = chord[0];
						var realAnim = noteSkin.data.singAnimations[Std.int(Math.abs(animNote.noteData))] + daAlt;
						if (field.owner.mostRecentRow != note.row)
						{
							if (note.owner == null) field.owner.playAnim(realAnim, true);
							else note.owner.playAnim(realAnim, true);
						}
						
						if (note != animNote && chord.indexOf(note) != animNote.noteData)
						{
							if (note.owner == null) field.owner.playGhostAnim(chord.indexOf(note), animToPlay, true);
							else note.owner.playGhostAnim(chord.indexOf(note), animToPlay, true);
						}
						// doGhostAnim('bf', animToPlay);
						
						field.owner.mostRecentRow = note.row;
					}
					else
					{
						if (note.noteType != "Ghost Note")
						{
							if (note.owner == null) field.owner.playAnim(animToPlay + daAlt, true);
							else note.owner.playAnim(animToPlay + daAlt, true);
						}
						else
						{
							if (note.owner == null) field.owner.playGhostAnim(note.noteData, animToPlay, true);
							else note.owner.playGhostAnim(note.noteData, animToPlay, true);
						}
					}
				}
				
				if (note.noteType == 'Hey!')
				{
					if (field.owner.animTimer <= 0 && !field.owner.voicelining)
					{
						if (field.owner.animOffsets.exists('hey'))
						{
							field.owner.playAnim('hey', true);
							field.owner.specialAnim = true;
							field.owner.heyTimer = 0.6;
						}
					}
					
					if (gf != null && gf.animOffsets.exists('cheer'))
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}
			
			note.wasGoodHit = true;
			vocals.playerVolume = 1;
			
			final luaArgs:Array<Dynamic> = [
				notes.members.indexOf(note),
				Math.abs(note.noteData),
				note.noteType,
				note.isSustainNote,
				note.ID
			];
			final hscriptArgs = [note];
			
			callOnLuas('goodNoteHit', luaArgs);
			callOnHScripts("goodNoteHit", hscriptArgs);
			if (note.noteScript != null)
			{
				var script:Dynamic = note.noteScript;
				if (script.scriptType == LUA)
				{
					callScript(script, 'goodNoteHit', luaArgs);
				}
				else
				{
					callScript(script, "goodNoteHit", hscriptArgs);
				}
			}
			if (!note.isSustainNote)
			{
				disposeNote(note);
			}
		}
	}
	
	function extraNoteHit(note:Note, field:PlayField)
	{
		if (!note.wasGoodHit)
		{
			if (field.autoPlayed && (note.ignoreNote || note.hitCausesMiss)) return;
			
			if (field.autoPlayed)
			{
				var time:Float = 0.15;
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					time += 0.15;
				}
				if (field.playAnims) strumPlayAnim(field, Std.int(Math.abs(note.noteData)) % SONG.keys, time, note);
			}
			else
			{
				field.forEach(function(spr:StrumNote) {
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true, note);
					}
				});
			}
			
			if (note.hitCausesMiss)
			{
				field.noteMissCallback.dispatch(note, field);
				if (!note.noteSplashDisabled && !note.isSustainNote)
				{
					spawnNoteSplashOnNote(note);
				}
				
				if (!note.noMissAnimation)
				{
					switch (note.noteType)
					{
						case 'Hurt Note': // Hurt note
							if (field.owner.animation.exists('hurt'))
							{
								field.owner.playAnim('hurt', true);
								field.owner.specialAnim = true;
							}
					}
				}
				
				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					disposeNote(note);
				}
				return;
			}
			
			if (field.playerControls)
			{
				if (!note.isSustainNote)
				{
					combo += 1;
					if (combo > 9999) combo = 9999;
					popUpScore(note);
				}
				health += note.hitHealth * healthGain;
			}
			
			if (!note.noAnimation)
			{
				var daAlt = '';
				if (note.noteType == 'Alt Animation') daAlt = '-alt';
				
				var animToPlay:String = noteSkin.data.singAnimations[Std.int(Math.abs(note.noteData))];
				var owner = field.owner;
				
				if (note.gfNote)
				{
					if (gf != null)
					{
						gf.playAnim(animToPlay + daAlt, true);
						gf.holdTimer = 0;
					}
				}
				else if (field.owner.animTimer <= 0 && !field.owner.voicelining)
				{
					field.owner.holdTimer = 0;
					if (note.owner != null) owner = note.owner;
					if (ClientPrefs.jumpGhosts
						&& field.owner.ghostsEnabled
						&& !note.isSustainNote
						&& noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row] != null
						&& noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row].length > 1
						&& note.noteType != "Ghost Note")
					{
						// potentially have jump anims?
						var chord = noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row];
						var animNote = chord[0];
						var realAnim = noteSkin.data.singAnimations[Std.int(Math.abs(animNote.noteData))] + daAlt;
						if (field.owner.mostRecentRow != note.row)
						{
							if (owner == null) field.owner.playAnim(realAnim, true);
							else owner.playAnim(realAnim, true);
						}
						
						if (note != animNote && chord.indexOf(note) != animNote.noteData)
						{
							if (owner == null) field.owner.playGhostAnim(chord.indexOf(note), animToPlay, true);
							else owner.playGhostAnim(chord.indexOf(note), animToPlay, true);
						}
						// doGhostAnim('bf', animToPlay);
						
						field.owner.mostRecentRow = note.row;
					}
					else
					{
						if (note.noteType != "Ghost Note")
						{
							if (owner == null) field.owner.playAnim(animToPlay + daAlt, true);
							else owner.playAnim(animToPlay + daAlt, true);
						}
						else
						{
							if (owner == null) field.owner.playGhostAnim(note.noteData, animToPlay, true);
							else owner.playGhostAnim(note.noteData, animToPlay, true);
						}
					}
				}
				
				if (note.noteType == 'Hey!')
				{
					if (field.owner.animTimer <= 0 && !field.owner.voicelining)
					{
						if (field.owner.animOffsets.exists('hey'))
						{
							field.owner.playAnim('hey', true);
							field.owner.specialAnim = true;
							field.owner.heyTimer = 0.6;
						}
					}
					
					if (gf != null && gf.animOffsets.exists('cheer'))
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}
			
			note.wasGoodHit = true;
			vocals.playerVolume = 1;
			
			var luaArgs:Array<Dynamic> = [
				notes.members.indexOf(note),
				Math.abs(note.noteData),
				note.noteType,
				note.isSustainNote,
				note.ID
			];
			var hscriptArgs = [note];
			
			callOnLuas('extraNoteHit', luaArgs);
			callOnHScripts("extraNoteHit", hscriptArgs);
			if (note.noteScript != null)
			{
				var script:Dynamic = note.noteScript;
				if (script.scriptType == LUA)
				{
					callScript(script, 'extraNoteHit', luaArgs);
				}
				else
				{
					callScript(script, "extraNoteHit", hscriptArgs);
				}
			}
			if (!note.isSustainNote)
			{
				disposeNote(note);
			}
		}
	}
	
	function spawnNoteSplashOnNote(note:Note)
	{
		if (ClientPrefs.noteSplashes && note != null)
		{
			final strum:Null<StrumNote> = note.playField.members[note.noteData];
			if (strum != null)
			{
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}
	
	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		var skin:String = noteSplashSkin;
		
		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if (note != null)
		{
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}
		
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x + script_SPLASHOffsets[data].x, y + script_SPLASHOffsets[data].y, data, skin, hue, sat, brt, note.playField);
		grpNoteSplashes.add(splash);
		
		callOnHScripts('spawnNoteSplash', [splash, data, note, note.mustPress]);
	}
	
	override function refreshZ(?group:FlxTypedGroup<FlxBasic>)
	{
		group ??= stage;
		group.sort(SortUtil.sortByZ, flixel.util.FlxSort.ASCENDING);
	}
	
	var preventLuaRemove:Bool = false;
	
	override function destroy()
	{
		preventLuaRemove = true;
		
		instance = null;
		
		for (script in funkyScripts)
		{
			script.call("onDestroy", []);
			script = FlxDestroyUtil.destroy(script);
		}
		
		hscriptArray = [];
		funkyScripts = [];
		luaArray = [];
		notetypeScripts.clear();
		eventScripts.clear();
		
		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.destroy();
	}
	
	public function removeLua(lua:FunkinLua)
	{
		if (luaArray != null && !preventLuaRemove)
		{
			luaArray.remove(lua);
		}
	}
	
	override function stepHit()
	{
		super.stepHit();
		
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (SONG.needsVoices && vocals.getDesyncDifference(Math.abs(Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}
		
		if (curStep == lastStepHit)
		{
			return;
		}
		
		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit', []);
		callHUDFunc(hud -> hud.stepHit());
	}
	
	var lastStepHit:Int = -1;
	var lastBeatHit:Int = -1;
	var lastSection:Int = -1;
	
	override function beatHit()
	{
		super.beatHit();
		
		if (lastBeatHit >= curBeat)
		{
			return;
		}
		
		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}
		
		handleBoppers(curBeat);
		
		if (beatsPerZoom == 0) beatsPerZoom = 4;
		
		if (camZooming && ClientPrefs.camZooms && curBeat % beatsPerZoom == 0)
		{
			FlxG.camera.zoom += 0.015 * camZoomingMult;
			camHUD.zoom += 0.03 * camZoomingMult;
		}
		
		lastBeatHit = curBeat;
		
		if (totalBeat > 0)
		{
			if (curBeat % timeBeat == 0)
			{
				triggerEventNote('Add Camera Zoom', '' + gameZ, '' + hudZ);
				totalBeat -= 1;
				
				if (shakeTime)
				{
					triggerEventNote('Screen Shake', (((1 / (Conductor.bpm / 60)) / 2) * timeBeat)
						+ ', '
						+ gameShake, (((1 / (Conductor.bpm / 60)) / 2) * timeBeat)
						+ ', '
						+ hudShake);
				}
			}
		}
		
		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit', []);
		callHUDFunc(hud -> hud.beatHit());
	}
	
	// rework this
	public function handleBoppers(beat:Int)
	{
		if (gf != null
			&& beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
			&& !gf.isAnimNull()
			&& !gf.getAnimName().startsWith("sing")
			&& !gf.stunned)
		{
			gf.dance();
		}
		if (beat % boyfriend.danceEveryNumBeats == 0
			&& !boyfriend.isAnimNull()
			&& !boyfriend.getAnimName().startsWith('sing')
			&& !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (beat % dad.danceEveryNumBeats == 0 && !dad.isAnimNull() && !dad.getAnimName().startsWith('sing') && !dad.stunned)
		{
			dad.dance();
		}
	}
	
	override function sectionHit()
	{
		if (SONG.notes[curSection] != null)
		{
			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crotchet', Conductor.crotchet);
				setOnScripts('stepCrotchet', Conductor.stepCrotchet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		
		super.sectionHit();
		
		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
		callHUDFunc(hud -> hud.sectionHit());
	}
	
	public function callOnScripts(event:String, ?args:Array<Dynamic>, ignoreStops:Bool = false, ?exclusions:Array<String>, ?scriptArray:Array<Dynamic>, ?ignoreSpecialShit:Bool = true)
	{
		args ??= [];
		if (scriptArray == null)
		{
			scriptArray = funkyScripts.copy();
			for (s in eventScripts)
				scriptArray.push(s);
		}
		if (exclusions == null) exclusions = [];
		var returnVal:Dynamic = Globals.Function_Continue;
		for (script in scriptArray)
		{
			if (exclusions.contains(script.scriptName)
				|| ignoreSpecialShit
				&& (notetypeScripts.exists(script.scriptName) || eventScripts.exists(script.scriptName)))
			{
				continue;
			}
			var ret:Dynamic = script.call(event, args);
			if (ret == Globals.Function_Halt)
			{
				ret = returnVal;
				if (!ignoreStops) return returnVal;
			};
			
			if (ret != Globals.Function_Continue && ret != null) returnVal = ret;
		}
		if (returnVal == null) returnVal = Globals.Function_Continue;
		
		return returnVal;
	}
	
	public function setOnScripts(variable:String, arg:Dynamic, ?scriptArray:Array<Dynamic>)
	{
		if (scriptArray == null) scriptArray = funkyScripts;
		for (script in scriptArray)
		{
			script.set(variable, arg);
		}
	}
	
	// currently from my knowledge lua does not work like at all lol so we need to look into that later
	function callEventScript(scriptName:String, func:String, args:Array<Dynamic>, ?luaArgs:Array<Dynamic>):Dynamic
	{
		if (!eventScripts.exists(scriptName)) return Globals.Function_Continue;
		
		var script = eventScripts.get(scriptName);
		if (luaArgs == null) luaArgs = args;
		
		if (script.scriptType == LUA) return callScript(script, func, luaArgs);
		
		return callScript(script, func, args);
	}
	
	// data todo make a callNoteScript!
	function callNoteTypeScript() {}
	
	public function callScript(script:Dynamic, event:String, args:Array<Dynamic>):Dynamic
	{
		if (script is FunkinScript)
		{
			return callOnScripts(event, args, true, [], [script], false);
		}
		else if (script is Array)
		{
			return callOnScripts(event, args, true, [], script, false);
		}
		else if (script is String)
		{
			var scripts:Array<FunkinScript> = [];
			for (scr in funkyScripts)
			{
				if (scr.scriptName == script) scripts.push(scr);
			}
			return callOnScripts(event, args, true, [], scripts, false);
		}
		
		return Globals.Function_Continue;
	}
	
	inline public function callOnHScripts(event:String, args:Array<Dynamic>, ignoreStops = false, ?exclusions:Array<String>)
	{
		return callOnScripts(event, args, ignoreStops, exclusions, hscriptArray);
	}
	
	inline public function setOnHScripts(variable:String, arg:Dynamic)
	{
		return setOnScripts(variable, arg, hscriptArray);
	}
	
	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = false, ?exclusions:Array<String>)
	{
		#if LUA_ALLOWED
		return callOnScripts(event, args, ignoreStops, exclusions, luaArray);
		#else
		return Globals.Function_Continue;
		#end
	}
	
	public function setOnLuas(variable:String, arg:Dynamic)
	{
		#if LUA_ALLOWED
		setOnScripts(variable, arg, luaArray);
		#end
	}
	
	function strumPlayAnim(field:PlayField, id:Int, time:Float, ?note:Note)
	{
		var spr:StrumNote = field.members[id];
		
		if (spr != null)
		{
			spr.playAnim('confirm', true, note);
			spr.resetAnim = time;
		}
	}
	
	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	
	public function RecalculateRating(badHit:Bool = false)
	{
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);
		
		final ret:Dynamic = callOnScripts('onRecalculateRating', []);
		if (ret != Globals.Function_Stop)
		{
			if (totalPlayed < 1) // Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				// trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);
				
				// Rating Name
				if (ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length - 1].name; // Uses last string
				}
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
		
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
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
	
	override public function startOutro(onOutroComplete:() -> Void)
	{
		if (isPixelStage != stageData.isPixelStage) isPixelStage = stageData.isPixelStage;
		super.startOutro(onOutroComplete);
	}
}
