package funkin.states.editors;

import funkin.data.Chart;

import haxe.ds.IntMap;
import haxe.Json;
import haxe.io.Bytes;

import lime.media.AudioBuffer;

import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import openfl.utils.Assets as OpenFlAssets;
import openfl.geom.Rectangle;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.FlxUITabMenu;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxGradient;
import flixel.addons.ui.FlxUI;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.objects.Character;
import funkin.data.StageData;
import funkin.data.CharacterData;
// import funkin.data.NoteSkinHelper;
import funkin.backend.Difficulty;
import funkin.data.Song;
import funkin.states.substates.Prompt;
import funkin.backend.Conductor.BPMChangeEvent;
import funkin.data.Song;
import funkin.scripts.*;
import funkin.states.*;
import funkin.objects.*;
import funkin.objects.note.*;
import funkin.states.editors.ui.EditorNote;
import funkin.backend.MusicBeatSubstate;
import funkin.states.editors.ChartEditorState;

#if sys
import openfl.media.Sound;

import sys.FileSystem;
import sys.io.File;
#end

@:access(flixel.sound.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)
class OLDChartEditorState extends MusicBeatState
{
	public static var instance:OLDChartEditorState;
	
	public var notetypeScripts:Map<String, FunkinScript> = [];
	
	public static var noteTypeList:Array<String> = // Used for backwards compatibility with 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
		[
			'',
			'Alt Animation',
			'Hey!',
			'Hurt Note',
			'GF Sing',
			'No Animation',
			'Ghost Note',
			#if debug 'Test Owner Note' #end
		];
		
	private var noteTypeIntMap:Map<Int, String> = new Map<Int, String>();
	private var noteTypeMap:Map<String, Null<Int>> = new Map<String, Null<Int>>();
	
	public var ignoreWarnings = false;
	
	public static var camHUD:FlxCamera;
	
	var undos = [];
	var redos = [];
	var eventStuff:Array<Dynamic> = [
		['', "Nothing. Yep, that's right."],
		[
			'Hey!',
			"Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"
		],
		[
			'Set GF Speed',
			"Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"
		],
		[
			'Add Camera Zoom',
			"Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."
		],
		[
			'Play Animation',
			"Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"
		],
		[
			'Camera Follow Pos',
			"Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."
		],
		[
			'Alt Idle Animation',
			"Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"
		],
		[
			'Screen Shake',
			"Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."
		],
		[
			'Change Character',
			"Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"
		],
		// my auto formatter is forcing it to be liek this. i will fix it later
		['Change Noteskin', 'Value 1: name of the noteskin json to change to.\nValue 2: ID of strum to change. (0 -> player, 1 -> opponent, etc)'],
		['Change Scroll Speed', "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."],
		['Set Property', "Value 1: Variable name\nValue 2: New value"],
		['HUD Fade', "Fades the HUD camera\n\nValue 1: Alpha\nValue 2: Duration"],
		['Camera Fade', "Fades the game camera\n\nValue 1: Alpha\nValue 2: Duration"],
		['Camera Flash', "Value 1: Color, Alpha (Optional)\nValue 2: Fade duration"],
		['Camera Zoom', "Changes the Camera Zoom.\n\nValue 1: Zoom Multiplier (1 is default)\n\nIn case you want a tween, use Value 2 like this:\n\n\"3, elasticOut\"\n(Duration, Ease Type)"],
		['Camera Zoom Chain', "Value 1: Camera Zoom Values (0.015, 0.03)\n(also you can add another two values to make it\nzoom screen shake(0.015, 0.03, 0.01, 0.01))\n\nValue 2: Total Amount of Beat Cam Zooms and\nthe space with eachother (4, 1)"],
		['Screen Shake Chain', "Value 1: Screen Shake Values (0.003, 0.0015)\n\nValue 2: Total Amount of Screen Shake per beat]"], ['Set Cam Zoom', "Value 1: Zoom"],
		['Set Cam Pos', "Value 1: X\nValue 2: Y"], ["Mult SV", "Changes the notes' scroll velocity via multiplication.\nValue 1: Multiplier"],
		["Constant SV", "Uses scroll velocity to set the speed to a constant number.\nValue 1: Constant"]];
		
	public var variables:Map<String, Dynamic> = new Map();
	
	var _file:FileReference;
	
	public static var UI_box:FlxUITabMenu;
	public static var goToPlayState:Bool = false;
	
	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	public static var curSec:Int = 0;
	
	public static var lastSection:Int = 0;
	private static var lastSong:String = '';
	
	var bpmTxt:FlxText;
	var camPos:FlxObject;
	var strumLine:FlxSprite;
	var quant:AttachedSprite;
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var curSong:String = 'Test';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;
	var highlight:FlxSprite;
	
	public static var GRID_SIZE:Int = 40;
	
	public var CAM_OFFSET:Float = 0;
	
	var dummyArrow:FlxSprite;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedNotes:FlxTypedGroup<EditorNote>;
	var curRenderedNoteType:FlxTypedGroup<FlxText>;
	var nextRenderedSustains:FlxTypedGroup<FlxSprite>;
	var nextRenderedNotes:FlxTypedGroup<Note>;
	var prevRenderedSustains:FlxTypedGroup<FlxSprite>;
	var prevRenderedNotes:FlxTypedGroup<Note>;
	var gridBG:FlxSprite;
	var nextGridBG:FlxSprite;
	var prevGridBG:FlxSprite;
	var daquantspot = 0;
	var curEventSelected:Int = 0;
	var curUndoIndex = 0;
	var curRedoIndex = 0;
	
	static var _song(get, never):Song;
	
	static function get__song()
	{
		return (ChartEditorState.song);
	}
	
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNotes:Array<Array<Dynamic>> = [];
	var holdingNotes:Array<Array<Dynamic>> = [null, null, null, null, null, null, null, null];
	var tempBpm:Float = 0;
	var playbackSpeed:Float = 1;
	
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	
	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;
	var cameraIcon:FlxSprite;
	var value1InputText:FlxUIInputText;
	var value2InputText:FlxUIInputText;
	var currentSongName:String;
	var zoomTxt:FlxText;
	var zoomList:Array<Float> = [0.25, 0.5, 1, 2, 3, 4, 6, 8, 12, 16, 24];
	var curZoom:Int = 2;
	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenuEx> = [];
	var waveformSprite:FlxSprite;
	var gridLayer:FlxTypedGroup<FlxSprite>;
	
	public static var quantization:Int = 16;
	public static var curQuant = 3;
	
	public var quantizations:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];
	
	public static var lanes:Int = 2;
	public static var initialKeyCount:Int = 4;
	public static var startTime:Float = 0;
	
	var text:String = "";
	
	public static var textBox:FlxSprite;
	public static var clickForInfo:FlxText;
	public static var bPos:FlxPoint;
	public static var vortex:Bool = false;
	
	var vortexControlArray:Array<Bool>;
	
	public var mouseQuant:Bool = false;
	
	var bg:FlxSprite;
	var gradient:FlxBackdrop;
	var canAddNotes:Bool = true;
	var littleBF:OurLittleFriend;
	var littleDad:OurLittleFriend;
	var littleStage:FlxSprite;
	var dadIcon:String = 'dad';
	var bfIcon:String = 'bf';
	var gfIcon:String = 'gf';
	var endOffset:Int = 17;
	var songEnded:Bool = false;
	
	override function create()
	{
		instance = this;
		
		ChartEditorState.song ??= ChartEditorState.getDefaultSong();
		
		initialKeyCount = _song.keys;
		ClientPrefs.load();
		
		// if (PlayState.noteSkin != null)
		// {
		// 	NoteSkinHelper.keys = _song.keys;
		// }
		
		// Updating Discord Rich Presence
		// DiscordClient.changePresence("Chart Editor", StringTools.replace(_song.song, '-', ' '));
		DiscordClient.changePresence("Chart Editor", "Uhm idk mane burp");
		
		camHUD = new FlxCamera();
		camHUD.bgColor = 0x0;
		FlxG.cameras.add(camHUD, false);
		
		camPos = new FlxObject(0, 0, 1, 1);
		FlxG.camera.follow(camPos);
		
		vortex = FlxG.save.data.chart_vortex;
		ignoreWarnings = FlxG.save.data.ignoreWarnings;
		
		gradient = new FlxBackdrop(null, Y);
		add(gradient);
		
		bg = new FlxSprite().loadGraphic(Paths.image('menus/menuDesat'));
		bg.scrollFactor.set();
		add(bg);
		createFriends();
		
		gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);
		
		waveformSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
		add(waveformSprite);
		
		// var eventIcon:FlxSprite = new FlxSprite(-GRID_SIZE - 5, -90).loadGraphic(Paths.image('eventArrow'));
		leftIcon = new HealthIcon(bfIcon);
		rightIcon = new HealthIcon(dadIcon);
		cameraIcon = new FlxSprite().loadGraphic(Paths.image('editors/camera'));
		
		// eventIcon.setGraphicSize(30, 30);
		
		// add(eventIcon);
		add(leftIcon);
		add(rightIcon);
		add(cameraIcon);
		
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedNotes = new FlxTypedGroup<EditorNote>();
		curRenderedNoteType = new FlxTypedGroup<FlxText>();
		
		prevRenderedSustains = new FlxTypedGroup<FlxSprite>();
		prevRenderedNotes = new FlxTypedGroup<Note>();
		
		nextRenderedSustains = new FlxTypedGroup<FlxSprite>();
		nextRenderedNotes = new FlxTypedGroup<Note>();
		
		if (curSec >= _song.notes.length) curSec = _song.notes.length - 1;
		
		FlxG.mouse.visible = true;
		
		tempBpm = _song.bpm;
		
		addSection();
		
		// sections = _song.notes;
		
		bfIcon = CharacterParser.fetchInfo(_song.player1).healthicon;
		dadIcon = CharacterParser.fetchInfo(_song.player2).healthicon;
		gfIcon = CharacterParser.fetchInfo(_song.gfVersion).healthicon;
		
		currentSongName = Paths.sanitize(_song.song);
		loadSong();
		reloadGradient();
		reloadGridLayer();
		Conductor.bpm = _song.bpm;
		Conductor.mapBPMChanges(_song);
		
		gridZoom(true);
		
		bpmTxt = new FlxText(10, 30, 0, "", 16);
		bpmTxt.scrollFactor.set();
		bpmTxt.camera = camHUD;
		add(bpmTxt);
		
		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * ((_song.keys * _song.lanes) + 1)), 4);
		add(strumLine);
		
		quant = new AttachedSprite('editors/chart_quant', 'chart_quant');
		quant.animation.addByPrefix('q', 'chart_quant', 0, false);
		quant.animation.play('q', true, false, 0);
		quant.sprTracker = strumLine;
		quant.xAdd = -32;
		quant.yAdd = 8;
		add(quant);
		
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		reloadStrumShit();
		add(strumLineNotes);
		
		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);
		
		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Events", label: 'Events'},
			{name: "Charting", label: 'Charting'},
			{name: "Visuals", label: 'Visuals'}
		];
		
		FlxG.sound.music.looped = false;
		
		UI_box = new FlxUITabMenu(null, tabs, true);
		
		UI_box.resize(360, 380);
		UI_box.x = 10;
		UI_box.y = 20;
		UI_box.scrollFactor.set();
		UI_box.color = ClientPrefs.editorUIColor;
		UI_box.camera = camHUD;
		
		zoomTxt = new FlxText(10, UI_box.y + UI_box.height + 10, 0, "Zoom: 1 / 1", 16);
		zoomTxt.scrollFactor.set();
		zoomTxt.camera = camHUD;
		add(zoomTxt);
		bpmTxt.y = zoomTxt.y + 20;
		
		// clickForInfo.setPosition((textBox.width / 2) - (clickForInfo.width / 2), (textBox.height / 2) - (clickForInfo.height / 2));
		// text =
		// "W/S or Mouse Wheel - Change Conductor's strum time
		// \nA/D - Go to the previous/next section
		// \nLeft/Right - Change Snap
		// \nUp/Down - Change Conductor's Strum Time with Snapping
		// \nLeft Bracket / Right Bracket - Change Song Playback Rate (SHIFT to go Faster)
		// \nHold Shift to move 4x faster
		// \nHold Control and click on an arrow to select it
		// \nZ/X - Zoom in/out
		// \n
		// \nEsc - Play your chart in game at the given timestamp
		// \nEnter - Play your chart
		// \nQ/E - Decrease/Increase Note Sustain Length
		// \nSpace - Stop/Resume song";
		
		// var tipTextArray:Array<String> = text.split('\n');
		// for (i in 0...tipTextArray.length) {
		// 	var tipText:FlxText = new FlxText(UI_box.x, UI_box.y + UI_box.height + 8, 0, tipTextArray[i], 16);
		// 	tipText.y += i * 12;
		// 	tipText.setFormat(Paths.DEFAULT_FONT, 14, FlxColor.WHITE, LEFT/*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
		// 	//tipText.borderSize = 2;
		// 	tipText.scrollFactor.set();
		// 	add(tipText);
		// }
		add(UI_box);
		
		addSongUI();
		addSectionUI();
		addNoteUI();
		addEventsUI();
		addChartingUI();
		addVisualsUI();
		updateWaveform();
		// UI_box.selected_tab = 4;
		
		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedNoteType);
		add(nextRenderedSustains);
		add(nextRenderedNotes);
		add(prevRenderedSustains);
		add(prevRenderedNotes);
		
		// clickForInfo = new FlxText(UI_box.x + 20, UI_box.y + UI_box.height + 8, 0, 'Click for help!', 16);
		// clickForInfo.setFormat(Paths.DEFAULT_FONT, 14, 0xFF8c8c8c, LEFT /*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
		// clickForInfo.scrollFactor.set();
		
		// textBox = new FlxSprite().makeGraphic(Std.int(clickForInfo.width * 1.25), Std.int(clickForInfo.height * 1.25),
		// 	FlxColor.fromRGB(ClientPrefs.editorUIColor.red, ClientPrefs.editorUIColor.green, ClientPrefs.editorUIColor.blue));
		// textBox.setPosition(((UI_box.width - textBox.width) / 2) + UI_box.x + 20, (UI_box.height + UI_box.y) + 10);
		// textBox.scrollFactor.set();
		// textBox.alpha = 0.6;
		// textBox.color = FlxColor.BLACK;
		
		// textBox.camera = camHUD;
		// clickForInfo.camera = camHUD;
		
		// bPos = FlxPoint.get(textBox.x, textBox.y);
		// clickForInfo.setPosition(((textBox.width - clickForInfo.width) / 2) + textBox.x, (UI_box.height + UI_box.y) + 11.5);
		
		// add(textBox);
		// add(clickForInfo);
		
		if (lastSong != currentSongName)
		{
			changeSection();
		}
		lastSong = currentSongName;
		
		updateGrid();
		
		super.create();
	}
	
	function createFriends()
	{
		// temp
		var isInfry:Bool = FlxG.random.bool(50);
		
		littleBF = new OurLittleFriend(isInfry ? 'dingalingdemon' : 'bf');
		littleBF.setPosition(210, FlxG.height - littleBF.height - 50);
		littleBF.scrollFactor.set();
		littleBF.camera = camHUD;
		
		littleDad = new OurLittleFriend(isInfry ? "opp" : 'fella');
		littleDad.setPosition(10, FlxG.height - littleDad.height - 50);
		littleDad.scrollFactor.set();
		littleDad.camera = camHUD;
		
		littleStage = new FlxSprite().loadGraphic(Paths.image('editors/friends/${isInfry ? "stage" : 'platform'}'));
		littleStage.scrollFactor.set();
		littleStage.scale.set(littleDad.scale.x, littleDad.scale.x);
		littleStage.updateHitbox();
		littleStage.x = littleDad.x;
		littleStage.y = littleDad.y + littleDad.height + (isInfry ? -10 : 0);
		littleStage.camera = camHUD;
		
		add(littleStage);
		add(littleDad);
		add(littleBF);
	}
	
	inline function resetLittleFriends()
	{
		littleBF?.sing(4);
		littleDad?.sing(4);
	}
	
	inline function reloadGradient():Void
	{
		if (ClientPrefs.editorGradVis)
		{
			gradient.revive();
			gradient.loadGraphic(FlxGradient.createGradientBitmapData(1, FlxG.height * 4, [
				ClientPrefs.editorGradColors[0],
				ClientPrefs.editorGradColors[1],
				ClientPrefs.editorGradColors[0],
			]));
			gradient.screenCenter(X);
			gradient.scrollFactor.set();
			
			bg.setColorTransform(-.25, -.25, -.25, 1, 60, 60, 60);
			bg.blend = SUBTRACT;
		}
		else
		{
			gradient.kill();
			
			bg.setColorTransform();
			bg.color = 0xff222222;
			bg.blend = NORMAL;
		}
	}
	
	var check_mute_inst:FlxUICheckBox = null;
	var check_vortex:FlxUICheckBox = null;
	var check_warnings:FlxUICheckBox = null;
	var playSoundBf:FlxUICheckBox = null;
	var playSoundDad:FlxUICheckBox = null;
	var UI_songTitle:FlxUIInputText;
	var noteSkinInputText:FlxUIInputText;
	var noteSplashesInputText:FlxUIInputText;
	var stageDropDown:FlxUIDropDownMenuEx;
	var sliderRate:FlxUISlider;
	
	function addSongUI():Void
	{
		UI_songTitle = new FlxUIInputTextEx(10, 10, 70, _song.song, 8);
		blockPressWhileTypingOn.push(UI_songTitle);
		
		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function() {
			_song.needsVoices = check_voices.checked;
			// trace('CHECKED!');
		};
		
		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function() {
			saveLevel();
		});
		
		var reloadSong:FlxButton = new FlxButton(saveButton.x + 90, saveButton.y, "Reload Audio", function() {
			currentSongName = Paths.sanitize(UI_songTitle.text);
			loadSong();
			updateWaveform();
		});
		
		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function() {
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function() {
				loadJson(_song.song.toLowerCase());
			}, null, ignoreWarnings));
		});
		
		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'Load Autosave', function() {
			try
			{
				PlayState.SONG = Json.parse(FlxG.save.data.autosave).song;
			}
			catch (e)
			{
				Logger.log('failed to load autosave!', ERROR, true);
				return;
			}
			
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		});
		
		var loadEventJson:FlxButton = new FlxButton(loadAutosaveBtn.x, loadAutosaveBtn.y + 30, 'Load Events', function() {
			var songName:String = Paths.sanitize(_song.song);
			var file:String = Paths.json(songName + '/charts/events');
			
			if (FunkinAssets.exists(file, TEXT))
			{
				clearEvents();
				
				final _events = Chart.fromPath(file);
				_song.events = _events.events;
				changeSection(curSec);
			}
			else
			{
				Logger.log('events at ($file) could not be found', WARN, true);
			}
		});
		
		var saveEvents:FlxButton = new FlxButton(110, reloadSongJson.y, 'Save Events', function() {
			saveEvents();
		});
		
		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 70, 1, 1, 1, 400, 3, 1, new FlxUIInputTextEx(0, 0, 25));
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';
		blockPressWhileTypingOnStepper.push(stepperBPM);
		
		var stepperStrums:FlxUINumericStepper = new FlxUINumericStepper(stepperBPM.x + (stepperBPM.width * 2), 70, 1, 2, 1, 8, 0, 1, new FlxUIInputTextEx(0, 0, 25));
		stepperStrums.value = _song.lanes;
		stepperStrums.name = 'song_strums';
		blockPressWhileTypingOnStepper.push(stepperStrums);
		
		var stepperKeys:FlxUINumericStepper = new FlxUINumericStepper(stepperBPM.x + (stepperBPM.width * 2), 100, 1, 2, 1, 9, 0, 1, new FlxUIInputTextEx(0, 0, 25));
		stepperKeys.value = _song.keys;
		stepperKeys.name = 'song_keys';
		blockPressWhileTypingOnStepper.push(stepperKeys);
		
		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, stepperBPM.y + 35, 0.1, 1, 0.1, 10, 1, 1, new FlxUIInputTextEx(0, 0, 25));
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
		blockPressWhileTypingOnStepper.push(stepperSpeed);
		#if MODS_ALLOWED
		var directories:Array<String> = [
		
			Paths.mods('data/characters/'),
			Paths.mods(Mods.currentModDirectory + '/data/characters/'),
			Paths.getCorePath('data/characters/'),
			
			Paths.mods('characters/'),
			Paths.mods(Mods.currentModDirectory + '/characters/'),
			Paths.getCorePath('characters/'),
		];
		
		for (mod in Mods.globalMods)
		{
			directories.push(Paths.mods(mod + '/data/characters/'));
			directories.push(Paths.mods(mod + '/characters/'));
		}
		#else
		var directories:Array<String> = [Paths.getCorePath('data/characters/'), Paths.getCorePath('characters/')];
		#end
		
		var tempMap:Map<String, Bool> = new Map<String, Bool>();
		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));
		for (i in 0...characters.length)
		{
			tempMap.set(characters[i], true);
		}
		
		#if MODS_ALLOWED
		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FunkinAssets.exists(directory))
			{
				for (file in FunkinAssets.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					var isXml = false;
					if (!FunkinAssets.isDirectory(path) && (file.endsWith('.json') || (file.endsWith('.xml') && (isXml = true))))
					{
						var charToCheck:String = file.substr(0, file.length - (isXml ? 4 : 5));
						if (!charToCheck.endsWith('-dead') && !tempMap.exists(charToCheck))
						{
							tempMap.set(charToCheck, true);
							characters.push(charToCheck);
						}
					}
				}
			}
		}
		#end
		
		var player1DropDown = new FlxUIDropDownMenuEx(10, stepperSpeed.y + 45, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String) {
			_song.player1 = characters[Std.parseInt(character)];
			
			bfIcon = CharacterParser.fetchInfo(_song.player1).healthicon;
			
			updateHeads();
		});
		player1DropDown.selectedLabel = _song.player1;
		blockPressWhileScrolling.push(player1DropDown);
		
		var gfVersionDropDown = new FlxUIDropDownMenuEx(player1DropDown.x, player1DropDown.y + 40, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String) {
			_song.gfVersion = characters[Std.parseInt(character)];
			
			gfIcon = CharacterParser.fetchInfo(_song.gfVersion).healthicon;
			
			updateHeads();
		});
		gfVersionDropDown.selectedLabel = _song.gfVersion;
		blockPressWhileScrolling.push(gfVersionDropDown);
		
		var player2DropDown = new FlxUIDropDownMenuEx(player1DropDown.x, gfVersionDropDown.y + 40, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String) {
			_song.player2 = characters[Std.parseInt(character)];
			
			dadIcon = CharacterParser.fetchInfo(_song.player2).healthicon;
			if (dadIcon == 'face') dadIcon = 'dad';
			
			updateHeads();
		});
		player2DropDown.selectedLabel = _song.player2;
		blockPressWhileScrolling.push(player2DropDown);
		
		#if MODS_ALLOWED
		var directories:Array<String> = [
			Paths.mods('data/stages/'),
			Paths.mods(Mods.currentModDirectory + '/data/stages/'),
			Paths.getCorePath('data/stages/'),
			
			Paths.mods('stages/'),
			Paths.mods(Mods.currentModDirectory + '/stages/'),
			Paths.getCorePath('stages/')
		];
		for (mod in Mods.globalMods)
		{
			directories.push(Paths.mods(mod + '/data/stages/'));
			directories.push(Paths.mods(mod + '/stages/'));
		}
		#else
		var directories:Array<String> = [Paths.getCorePath('data/stages/'), Paths.getCorePath('stages/')];
		#end
		
		tempMap.clear();
		var stageFile:Array<String> = CoolUtil.coolTextFile(Paths.txt('stageList'));
		var stages:Array<String> = [];
		for (i in 0...stageFile.length)
		{ // Prevent duplicates
			var stageToCheck:String = stageFile[i];
			if (!tempMap.exists(stageToCheck))
			{
				stages.push(stageToCheck);
			}
			tempMap.set(stageToCheck, true);
		}
		#if MODS_ALLOWED
		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FunkinAssets.exists(directory))
			{
				for (file in FunkinAssets.readDirectory(directory))
				{
					// too lazy to make a func that checks if theres a file ending. go my shitty workaround!!!!!
					if (!file.contains('.'))
					{
						tempMap.set(file, true);
						stages.push(file);
					}
					else if (file.endsWith('json'))
					{
						var stageToCheck:String = file.substr(0, file.length - 5);
						if (!tempMap.exists(stageToCheck))
						{
							tempMap.set(stageToCheck, true);
							stages.push(stageToCheck);
						}
					}
				}
			}
		}
		#end
		if (stages.length < 1) stages.push('stage');
		
		stageDropDown = new FlxUIDropDownMenuEx(player1DropDown.x + 140, player1DropDown.y, FlxUIDropDownMenu.makeStrIdLabelArray(stages, true), function(character:String) {
			_song.stage = stages[Std.parseInt(character)];
		});
		stageDropDown.selectedLabel = _song.stage;
		blockPressWhileScrolling.push(stageDropDown);
		
		// var skin = PlayState.SONG.arrowSkin;
		// if (skin == null) skin = '';
		noteSkinInputText = new FlxUIInputTextEx(player2DropDown.x, player2DropDown.y + 50, 150, 'skin', 8);
		// blockPressWhileTypingOn.push(noteSkinInputText);
		
		noteSplashesInputText = new FlxUIInputTextEx(noteSkinInputText.x, noteSkinInputText.y + 35, 150, 'poop', 8);
		// blockPressWhileTypingOn.push(noteSplashesInputText);
		
		// var reloadNotesButton:FlxButton = new FlxButton(noteSplashesInputText.x + 5, noteSplashesInputText.y, 'Change Notes', function() {
		// _song.arrowSkin = noteSkinInputText.text;
		
		// trace('noteskin file: "${_song.arrowSkin}"');
		
		// updateGrid();
		// });
		
		var clear_events:FlxButton = new FlxButton(reloadSong.x, noteSplashesInputText.y - 20, 'Clear events', function() {
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, clearEvents, null, ignoreWarnings));
		});
		clear_events.color = FlxColor.RED;
		clear_events.label.color = FlxColor.WHITE;
		
		var clear_notes:FlxButton = new FlxButton(reloadSong.x, clear_events.y + 30, 'Clear notes', function() {
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function() {
				for (sec in 0..._song.notes.length)
				{
					_song.notes[sec].sectionNotes = [];
				}
				updateGrid();
			}, null, ignoreWarnings));
		});
		clear_notes.color = FlxColor.RED;
		clear_notes.label.color = FlxColor.WHITE;
		
		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);
		
		tab_group_song.add(check_voices);
		tab_group_song.add(clear_events);
		tab_group_song.add(clear_notes);
		tab_group_song.add(saveButton);
		tab_group_song.add(saveEvents);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(loadEventJson);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperStrums);
		tab_group_song.add(stepperKeys);
		tab_group_song.add(stepperSpeed);
		// tab_group_song.add(reloadNotesButton);
		// tab_group_song.add(noteSkinInputText);
		// tab_group_song.add(noteSplashesInputText);
		// cuz fuck you thats why : )
		tab_group_song.add(new FlxText(stepperBPM.x, stepperBPM.y - 15, 0, 'Song BPM:'));
		tab_group_song.add(new FlxText(stepperBPM.x + 100, stepperBPM.y - 15, 0, 'Strum Count:'));
		tab_group_song.add(new FlxText(stepperBPM.x + 100, stepperKeys.y - 15, 0, 'Key Count:'));
		tab_group_song.add(new FlxText(stepperSpeed.x, stepperSpeed.y - 15, 0, 'Song Speed:'));
		tab_group_song.add(new FlxText(player2DropDown.x, player2DropDown.y - 15, 0, 'Opponent:'));
		tab_group_song.add(new FlxText(gfVersionDropDown.x, gfVersionDropDown.y - 15, 0, 'Girlfriend:'));
		tab_group_song.add(new FlxText(player1DropDown.x, player1DropDown.y - 15, 0, 'Boyfriend:'));
		tab_group_song.add(new FlxText(stageDropDown.x, stageDropDown.y - 15, 0, 'Stage:'));
		// tab_group_song.add(new FlxText(noteSkinInputText.x, noteSkinInputText.y - 15, 0, 'Note Texture:'));
		// tab_group_song.add(new FlxText(noteSplashesInputText.x, noteSplashesInputText.y - 15, 0, 'Note Splashes Texture:'));
		tab_group_song.add(player2DropDown);
		tab_group_song.add(gfVersionDropDown);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(stageDropDown);
		
		UI_box.addGroup(tab_group_song);
	}
	
	var box1Colors:Array<Int> = [];
	var box2Colors:Array<Int> = [];
	var check_grad_vis:FlxUICheckBox = null;
	
	function addVisualsUI():Void
	{
		var tab_group_visual = new FlxUI(null, UI_box);
		tab_group_visual.name = 'Visuals';
		
		var gradTxt = new FlxText(10, 10, 0, "Gradient Colors", 12);
		
		var gradient1colors = new FlxUIInputTextEx(10, 30, 150, '${ClientPrefs.editorGradColors[0].red}, ${ClientPrefs.editorGradColors[0].green}, ${ClientPrefs.editorGradColors[0].blue}', 8);
		var gradient2colors = new FlxUIInputTextEx(10, 50, 150, '${ClientPrefs.editorGradColors[1].red}, ${ClientPrefs.editorGradColors[1].green}, ${ClientPrefs.editorGradColors[1].blue}', 8);
		
		var changecolors:FlxButton = new FlxButton(180, 37.5, "Change colors", function() {
			var grad1Colors:Array<Int> = [for (i in gradient1colors.text.split(',')) Std.parseInt(i.trim())];
			var grad2Colors:Array<Int> = [for (i in gradient2colors.text.split(',')) Std.parseInt(i.trim())];
			
			ClientPrefs.editorGradColors[0] = FlxColor.fromRGB(grad1Colors[0], grad1Colors[1], grad1Colors[2]);
			ClientPrefs.editorGradColors[1] = FlxColor.fromRGB(grad2Colors[0], grad2Colors[1], grad2Colors[2]);
			ClientPrefs.flush();
			
			reloadGradient();
		});
		
		check_grad_vis = new FlxUICheckBox(10, 75, null, null, "Gradient Visible?", 100);
		check_grad_vis.checked = gradient.alive;
		
		check_grad_vis.callback = function() {
			ClientPrefs.editorGradVis = (!ClientPrefs.editorGradVis);
			ClientPrefs.flush();
			
			reloadGradient();
		}
		
		blockPressWhileTypingOn.push(gradient1colors);
		blockPressWhileTypingOn.push(gradient2colors);
		
		tab_group_visual.add(gradTxt);
		tab_group_visual.add(gradient1colors);
		tab_group_visual.add(gradient2colors);
		tab_group_visual.add(changecolors);
		tab_group_visual.add(check_grad_vis);
		
		var boxTxt = new FlxText(10, 95, 0, "Grid Colors", 12);
		
		var boxTxtColors1 = new FlxUIInputTextEx(10, 115, 150, '${ClientPrefs.editorBoxColors[0].red}, ${ClientPrefs.editorBoxColors[0].green}, ${ClientPrefs.editorBoxColors[0].blue}', 8);
		var boxTxtColors2 = new FlxUIInputTextEx(10, 135, 150, '${ClientPrefs.editorBoxColors[1].red}, ${ClientPrefs.editorBoxColors[1].green}, ${ClientPrefs.editorBoxColors[1].blue}', 8);
		
		var changecolors:FlxButton = new FlxButton(180, 125, "Change colors", function() {
			box1Colors = [];
			box2Colors = [];
			// gradient.y = 0;
			
			for (i in boxTxtColors1.text.split(', '))
			{
				box1Colors.push(Std.parseInt(i));
			}
			for (i in boxTxtColors2.text.split(', '))
			{
				box2Colors.push(Std.parseInt(i));
			}
			
			ClientPrefs.editorBoxColors[0] = FlxColor.fromRGB(box1Colors[0], box1Colors[1], box1Colors[2]);
			ClientPrefs.editorBoxColors[1] = FlxColor.fromRGB(box2Colors[0], box2Colors[1], box2Colors[2]);
			ClientPrefs.flush();
			
			reloadGridLayer();
		});
		
		blockPressWhileTypingOn.push(boxTxtColors1);
		blockPressWhileTypingOn.push(boxTxtColors2);
		
		tab_group_visual.add(boxTxt);
		tab_group_visual.add(boxTxtColors1);
		tab_group_visual.add(boxTxtColors2);
		tab_group_visual.add(changecolors);
		
		var uiTxt = new FlxText(10, 155, 0, "UI Colors", 12);
		
		var uiBoxTxt = new FlxUIInputTextEx(10, 175, 150, '${ClientPrefs.editorUIColor.red}, ${ClientPrefs.editorUIColor.green}, ${ClientPrefs.editorUIColor.blue}', 8);
		
		var changecolors:FlxButton = new FlxButton(180, 170, "Change Color", function() {
			var shit = uiBoxTxt.text.split(', ');
			
			ClientPrefs.editorUIColor = FlxColor.fromRGB(Std.parseInt(shit[0]), Std.parseInt(shit[1]), Std.parseInt(shit[2]));
			ClientPrefs.flush();
			
			UI_box.color = ClientPrefs.editorUIColor;
			reloadGridLayer();
		});
		blockPressWhileTypingOn.push(uiBoxTxt);
		
		var prsTxt = new FlxText(10, 200, 0, "Presets", 12);
		
		var prsNm = new FlxText(10, 230, 0, "New Preset Name", 6);
		var newPrsName = new FlxUIInputTextEx(10, 240, 150, '', 8);
		
		var lPrs = new FlxText(10, 260, 0, "Load Preset", 6);
		var prsList = new FlxUIDropDownMenuEx(10, 270, FlxUIDropDownMenu.makeStrIdLabelArray(ClientPrefs.chartPresetList), function(preset:String) {
			var presetToUse = ClientPrefs.chartPresets.get(preset);
			ClientPrefs.editorGradColors = presetToUse[0];
			ClientPrefs.editorGradVis = presetToUse[1];
			ClientPrefs.editorBoxColors = presetToUse[2];
			ClientPrefs.editorUIColor = presetToUse[3];
			ClientPrefs.flush();
			
			reloadGradient();
			check_grad_vis.checked = gradient.alive;
			UI_box.color = ClientPrefs.editorUIColor;
			reloadGridLayer();
		});
		
		var newPrsButton = new FlxButton((newPrsName.x + newPrsName.width) + 10, 240, "New Preset", function() {
			if (!ClientPrefs.chartPresets.exists(newPrsName.text)) ClientPrefs.chartPresetList.push(newPrsName.text);
			ClientPrefs.chartPresets.set(newPrsName.text, [
				[ClientPrefs.editorGradColors[0], ClientPrefs.editorGradColors[1]],
				false,
				[ClientPrefs.editorBoxColors[0], ClientPrefs.editorBoxColors[1]],
				ClientPrefs.editorUIColor
			]);
			ClientPrefs.flush();
			
			prsList.setData(FlxUIDropDownMenu.makeStrIdLabelArray(ClientPrefs.chartPresetList));
			
			trace('New Preset! [${newPrsName.text}]\nValue: ${ClientPrefs.chartPresets.get(newPrsName.text)}');
		});
		blockPressWhileTypingOn.push(newPrsName);
		
		var clearPresets = new FlxButton((prsList.x + prsList.width) + 10, 270, "Clear Presets", function() {
			openSubState(new Prompt('This action will clear all presets.\n\nProceed?', 0, function() {
				ClientPrefs.chartPresets.clear();
				ClientPrefs.chartPresetList = ['Default'];
				ClientPrefs.chartPresets.set('Default', [
					[FlxColor.fromRGB(0, 0, 0), FlxColor.fromRGB(0, 0, 0)],
					false,
					[FlxColor.fromRGB(255, 255, 255), FlxColor.fromRGB(210, 210, 210)],
					FlxColor.fromRGB(250, 250, 250)
				]);
				ClientPrefs.flush();
				
				prsList.setData(FlxUIDropDownMenu.makeStrIdLabelArray(ClientPrefs.chartPresetList));
			}, null, ignoreWarnings));
		});
		clearPresets.color = FlxColor.RED;
		
		tab_group_visual.add(prsTxt);
		tab_group_visual.add(prsNm);
		tab_group_visual.add(newPrsName);
		tab_group_visual.add(newPrsButton);
		tab_group_visual.add(lPrs);
		tab_group_visual.add(prsList);
		tab_group_visual.add(clearPresets);
		
		tab_group_visual.add(uiTxt);
		tab_group_visual.add(uiBoxTxt);
		tab_group_visual.add(changecolors);
		
		UI_box.addGroup(tab_group_visual);
	}
	
	var stepperBeats:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_gfSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;
	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic>;
	
	function addSectionUI():Void
	{
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';
		
		check_mustHitSection = new FlxUICheckBox(10, 15, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = _song.notes[curSec].mustHitSection;
		
		check_gfSection = new FlxUICheckBox(10, check_mustHitSection.y + 22, null, null, "GF section", 100);
		check_gfSection.name = 'check_gf';
		check_gfSection.checked = _song.notes[curSec].gfSection;
		// _song.needsVoices = check_mustHit.checked;
		
		check_altAnim = new FlxUICheckBox(check_gfSection.x + 120, check_gfSection.y, null, null, "Alt Animation", 100);
		check_altAnim.checked = _song.notes[curSec].altAnim;
		
		stepperBeats = new FlxUINumericStepper(10, 100, 1, 4, 1, 6, 2, 1, new FlxUIInputTextEx(0, 0, 25));
		stepperBeats.value = getSectionBeats();
		stepperBeats.name = 'section_beats';
		blockPressWhileTypingOnStepper.push(stepperBeats);
		check_altAnim.name = 'check_altAnim';
		
		check_changeBPM = new FlxUICheckBox(10, stepperBeats.y + 30, null, null, 'Change BPM', 100);
		check_changeBPM.checked = _song.notes[curSec].changeBPM;
		check_changeBPM.name = 'check_changeBPM';
		
		stepperSectionBPM = new FlxUINumericStepper(10, check_changeBPM.y + 20, 1, Conductor.bpm, 1, 999, 1, 1, new FlxUIInputTextEx(0, 0, 25));
		if (check_changeBPM.checked)
		{
			stepperSectionBPM.value = _song.notes[curSec].bpm;
		}
		else
		{
			stepperSectionBPM.value = Conductor.bpm;
		}
		stepperSectionBPM.name = 'section_bpm';
		blockPressWhileTypingOnStepper.push(stepperSectionBPM);
		
		var check_eventsSec:FlxUICheckBox = null;
		var check_notesSec:FlxUICheckBox = null;
		var copyButton:FlxButton = new FlxButton(10, 190, "Copy Section", function() {
			notesCopied = [];
			sectionToCopy = curSec;
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				notesCopied.push(note);
			}
			
			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);
			for (event in _song.events)
			{
				var strumTime:Float = event[0];
				if (endThing > event[0] && event[0] >= startThing)
				{
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length)
					{
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
					notesCopied.push([strumTime, -1, copiedEventArray]);
				}
			}
		});
		
		var pasteButton:FlxButton = new FlxButton(copyButton.x + 100, copyButton.y, "Paste Section", function() {
			if (notesCopied == null || notesCopied.length < 1)
			{
				return;
			}
			
			var addToTime:Float = Conductor.stepCrotchet * (getSectionBeats() * 4 * (curSec - sectionToCopy));
			// trace('Time to add: ' + addToTime);
			
			for (note in notesCopied)
			{
				var copiedNote:Array<Dynamic> = [];
				var newStrumTime:Float = note[0] + addToTime;
				if (note[1] < 0)
				{
					if (check_eventsSec.checked)
					{
						var copiedEventArray:Array<Dynamic> = [];
						for (i in 0...note[2].length)
						{
							var eventToPush:Array<Dynamic> = note[2][i];
							copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
						}
						_song.events.push([newStrumTime, copiedEventArray]);
					}
				}
				else
				{
					if (check_notesSec.checked)
					{
						if (note[4] != null)
						{
							copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
						}
						else
						{
							copiedNote = [newStrumTime, note[1], note[2], note[3]];
						}
						_song.notes[curSec].sectionNotes.push(copiedNote);
					}
				}
			}
			updateGrid();
		});
		
		var clearSectionButton:FlxButton = new FlxButton(pasteButton.x + 100, pasteButton.y, "Clear", function() {
			if (check_notesSec.checked)
			{
				_song.notes[curSec].sectionNotes = [];
			}
			
			if (check_eventsSec.checked)
			{
				var i:Int = _song.events.length - 1;
				var startThing:Float = sectionStartTime();
				var endThing:Float = sectionStartTime(1);
				while (i > -1)
				{
					var event:Array<Dynamic> = _song.events[i];
					if (event != null && endThing > event[0] && event[0] >= startThing)
					{
						_song.events.remove(event);
					}
					--i;
				}
			}
			updateGrid();
			updateNoteUI();
		});
		clearSectionButton.color = FlxColor.RED;
		clearSectionButton.label.color = FlxColor.WHITE;
		
		check_notesSec = new FlxUICheckBox(10, clearSectionButton.y + 25, null, null, "Notes", 100);
		check_notesSec.checked = true;
		check_eventsSec = new FlxUICheckBox(check_notesSec.x + 100, check_notesSec.y, null, null, "Events", 100);
		check_eventsSec.checked = true;
		
		var swapSection:FlxButton = new FlxButton(10, check_notesSec.y + 40, "Swap section", function() {
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				if (note[1] < (_song.keys * 2))
				{
					note[1] = ((note[1] + _song.keys) % (_song.keys * 2));
					_song.notes[curSec].sectionNotes[i] = note;
				}
			}
			updateGrid();
		});
		
		var shiftNotes:FlxButton = new FlxButton(swapSection.x + swapSection.width + 10, swapSection.y, "Shift section", function() {
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				note[1] = ((note[1] + _song.keys) % (lanes * _song.keys));
			}
			updateGrid();
		});
		
		var stepperCopy:FlxUINumericStepper = null;
		var copyLastButton:FlxButton = new FlxButton(10, swapSection.y + 30, "Copy last section", function() {
			var value:Int = Std.int(stepperCopy.value);
			if (value == 0) return;
			
			var daSec = FlxMath.maxInt(curSec, value);
			
			for (note in _song.notes[daSec - value].sectionNotes)
			{
				var strum = note[0] + Conductor.stepCrotchet * (getSectionBeats(daSec) * 4 * value);
				
				var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
				_song.notes[daSec].sectionNotes.push(copiedNote);
			}
			
			var startThing:Float = sectionStartTime(-value);
			var endThing:Float = sectionStartTime(-value + 1);
			for (event in _song.events)
			{
				var strumTime:Float = event[0];
				if (endThing > event[0] && event[0] >= startThing)
				{
					strumTime += Conductor.stepCrotchet * (getSectionBeats(daSec) * 4 * value);
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length)
					{
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
					_song.events.push([strumTime, copiedEventArray]);
				}
			}
			updateGrid();
		});
		copyLastButton.setGraphicSize(80, 30);
		copyLastButton.updateHitbox();
		
		stepperCopy = new FlxUINumericStepper(copyLastButton.x + 100, copyLastButton.y, 1, 1, -999, 999, 0, 1, new FlxUIInputTextEx(0, 0, 25));
		blockPressWhileTypingOnStepper.push(stepperCopy);
		
		var duetButton:FlxButton = new FlxButton(10, copyLastButton.y + 45, "Choir Notes", function() {
			choirNotes(_song.notes[curSec].sectionNotes);
			
			updateGrid();
		});
		var mirrorButton:FlxButton = new FlxButton(duetButton.x + 100, duetButton.y, "Mirror Notes", function() {
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				note[1] = ((_song.keys - (note[1] % _song.keys) - 1) + Std.int(note[1] / _song.keys) * _song.keys);
			}
			
			updateGrid();
		});
		
		tab_group_section.add(new FlxText(stepperBeats.x, stepperBeats.y - 15, 0, 'Beats per Section:'));
		tab_group_section.add(stepperBeats);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_gfSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(pasteButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(check_notesSec);
		tab_group_section.add(check_eventsSec);
		tab_group_section.add(swapSection);
		tab_group_section.add(shiftNotes);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(copyLastButton);
		tab_group_section.add(duetButton);
		tab_group_section.add(mirrorButton);
		
		UI_box.addGroup(tab_group_section);
	}
	
	var stepperSusLength:FlxUINumericStepper;
	var strumTimeInputText:FlxUIInputText; // I wanted to use a stepper but we can't scale these as far as i know :(
	var noteTypeDropDown:FlxUIDropDownMenuEx;
	var currentType:Int = 0;
	
	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';
		
		stepperSusLength = new FlxUINumericStepper(10, 25, Conductor.stepCrotchet / 2, 0, 0, Conductor.stepCrotchet * 64, 0, 1, new FlxUIInputTextEx(0, 0, 25));
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';
		blockPressWhileTypingOnStepper.push(stepperSusLength);
		
		strumTimeInputText = new FlxUIInputTextEx(10, 65, 180, "0");
		tab_group_note.add(strumTimeInputText);
		blockPressWhileTypingOn.push(strumTimeInputText);
		
		var key:Int = 0;
		var displayNameList:Array<String> = [];
		while (key < noteTypeList.length)
		{
			displayNameList.push(noteTypeList[key]);
			noteTypeMap.set(noteTypeList[key], key);
			noteTypeIntMap.set(key, noteTypeList[key]);
			key++;
		}
		
		var directories:Array<String> = [Paths.getPath('data/notetypes/'), Paths.getPath('notetypes/')];
		
		#if MODS_ALLOWED
		directories.push(Paths.mods('data/notetypes/'));
		directories.push(Paths.mods(Mods.currentModDirectory + '/data/notetypes/'));
		
		directories.push(Paths.mods('notetypes/'));
		directories.push(Paths.mods(Mods.currentModDirectory + '/notetypes/'));
		
		for (mod in Mods.globalMods)
		{
			directories.push(Paths.mods(mod + '/data/notetypes/'));
			directories.push(Paths.mods(mod + '/notetypes/'));
		}
		#end
		
		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FunkinAssets.exists(directory))
			{
				for (file in FunkinAssets.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FunkinAssets.isDirectory(path))
					{
						for (ext in FunkinScript.H_EXTS)
						{
							if (file.endsWith(ext))
							{
								var fileToCheck:String = file.substr(0, file.length - ext.length - 1);
								
								if (!noteTypeMap.exists(fileToCheck))
								{
									displayNameList.push(fileToCheck);
									noteTypeMap.set(fileToCheck, key);
									noteTypeIntMap.set(key, fileToCheck);
									
									key++;
								}
							}
						}
					}
				}
			}
		}
		
		for (i in 1...displayNameList.length)
		{
			displayNameList[i] = i + '. ' + displayNameList[i];
		}
		
		noteTypeDropDown = new FlxUIDropDownMenuEx(10, 105, FlxUIDropDownMenu.makeStrIdLabelArray(displayNameList, true), function(character:String) {
			currentType = Std.parseInt(character);
			
			var changed:Bool = false;
			
			for (note in curSelectedNotes)
			{
				if (note[2] == null) continue;
				
				note[3] = noteTypeIntMap.get(currentType);
				changed = true;
			}
			
			if (changed) updateGrid();
		});
		blockPressWhileScrolling.push(noteTypeDropDown);
		
		tab_group_note.add(new FlxText(10, 10, 0, 'Sustain length:'));
		tab_group_note.add(new FlxText(10, 50, 0, 'Strum time (in miliseconds):'));
		tab_group_note.add(new FlxText(10, 90, 0, 'Note type:'));
		tab_group_note.add(stepperSusLength);
		tab_group_note.add(strumTimeInputText);
		tab_group_note.add(noteTypeDropDown);
		
		UI_box.addGroup(tab_group_note);
	}
	
	var eventDropDown:FlxUIDropDownMenuEx;
	var descText:FlxText;
	var selectedEventText:FlxText;
	
	function addEventsUI():Void
	{
		var tab_group_event = new FlxUI(null, UI_box);
		tab_group_event.name = 'Events';
		
		#if MODS_ALLOWED
		var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
		var directories:Array<String> = [];
		
		#if MODS_ALLOWED
		directories.push(Paths.mods('data/events/'));
		directories.push(Paths.mods(Mods.currentModDirectory + '/data/events/'));
		for (mod in Mods.globalMods)
			directories.push(Paths.mods(mod + '/data/events/'));
			
		directories.push(Paths.mods('events/'));
		directories.push(Paths.mods(Mods.currentModDirectory + '/events/'));
		for (mod in Mods.globalMods)
			directories.push(Paths.mods(mod + '/events/'));
		#end
		
		var eventexts = ['.txt', '.hx', '.hxs', '.hscript'];
		var removeShit = [4, 3, 4, 8];
		
		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FunkinAssets.exists(directory))
			{
				for (file in FunkinAssets.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					for (ext in 0...eventexts.length)
					{
						if (!FunkinAssets.isDirectory(path) && file != 'readme.txt' && file.endsWith(eventexts[ext]))
						{
							var fileToCheck:String = file.substr(0, file.length - removeShit[ext]);
							if (!eventPushedMap.exists(fileToCheck))
							{
								eventPushedMap.set(fileToCheck, true);
								for (x in ['.hx', '.hxs', '.hscript'])
								{
									if (file.endsWith(x))
									{
										eventStuff.push([fileToCheck, 'scripted description']);
										break;
									}
									else
									{
										eventStuff.push([fileToCheck, File.getContent(path)]);
										break;
									}
								}
							}
							break;
						}
					}
				}
			}
		}
		eventPushedMap.clear();
		eventPushedMap = null;
		#end
		
		descText = new FlxText(20, 200, 0, eventStuff[0][0]);
		
		var leEvents:Array<String> = [];
		for (i in 0...eventStuff.length)
		{
			leEvents.push(eventStuff[i][0]);
		}
		
		var text:FlxText = new FlxText(20, 30, 0, "Event:");
		tab_group_event.add(text);
		eventDropDown = new FlxUIDropDownMenuEx(20, 50, FlxUIDropDownMenu.makeStrIdLabelArray(leEvents, true), function(pressed:String) {
			var selectedEvent:Int = Std.parseInt(pressed);
			descText.text = eventStuff[selectedEvent][1];
			
			var event = curSelectedNotes[0];
			if (curSelectedNotes.length == 1 && eventStuff != null)
			{
				if (event[2] == null)
				{
					event[1][curEventSelected][0] = eventStuff[selectedEvent][0];
				}
				updateGrid();
			}
		});
		blockPressWhileScrolling.push(eventDropDown);
		
		var text:FlxText = new FlxText(20, 90, 0, "Value 1:");
		tab_group_event.add(text);
		value1InputText = new FlxUIInputTextEx(20, 110, 100, "");
		blockPressWhileTypingOn.push(value1InputText);
		
		var text:FlxText = new FlxText(20, 130, 0, "Value 2:");
		tab_group_event.add(text);
		value2InputText = new FlxUIInputTextEx(20, 150, 100, "");
		blockPressWhileTypingOn.push(value2InputText);
		
		// New event buttons
		var removeButton:FlxButton = new FlxButton(eventDropDown.x + eventDropDown.width + 10, eventDropDown.y, '-', function() {
			var event = curSelectedNotes[0];
			if (curSelectedNotes.length == 1 && event[2] == null) // Is event note
			{
				if (event[1].length > 1)
				{
					event[1].remove(event[1][curEventSelected]);
				}
				else
				{
					_song.events.remove(event);
					curSelectedNotes.remove(event);
				}
				
				var eventsGroup:Array<Dynamic>;
				--curEventSelected;
				if (curEventSelected < 0) curEventSelected = 0;
				else if (event != null
					&& curEventSelected >= (eventsGroup = event[1]).length) curEventSelected = eventsGroup.length - 1;
					
				changeEventSelected();
				updateGrid();
			}
		});
		removeButton.setGraphicSize(Std.int(removeButton.height), Std.int(removeButton.height));
		removeButton.updateHitbox();
		removeButton.color = FlxColor.RED;
		removeButton.label.color = FlxColor.WHITE;
		removeButton.label.size = 12;
		setAllLabelsOffset(removeButton, -30, 0);
		tab_group_event.add(removeButton);
		
		var addButton:FlxButton = new FlxButton(removeButton.x + removeButton.width + 10, removeButton.y, '+', function() {
			var event = curSelectedNotes[0];
			if (curSelectedNotes.length == 1 && event[2] == null) // Is event note
			{
				var eventsGroup:Array<Dynamic> = event[1];
				eventsGroup.push(['', '', '']);
				
				changeEventSelected(1);
				updateGrid();
			}
		});
		addButton.setGraphicSize(Std.int(removeButton.width), Std.int(removeButton.height));
		addButton.updateHitbox();
		addButton.color = FlxColor.GREEN;
		addButton.label.color = FlxColor.WHITE;
		addButton.label.size = 12;
		setAllLabelsOffset(addButton, -30, 0);
		tab_group_event.add(addButton);
		
		var moveLeftButton:FlxButton = new FlxButton(addButton.x + addButton.width + 20, addButton.y, '<', function() {
			changeEventSelected(-1);
		});
		moveLeftButton.setGraphicSize(Std.int(addButton.width), Std.int(addButton.height));
		moveLeftButton.updateHitbox();
		moveLeftButton.label.size = 12;
		setAllLabelsOffset(moveLeftButton, -30, 0);
		tab_group_event.add(moveLeftButton);
		
		var moveRightButton:FlxButton = new FlxButton(moveLeftButton.x + moveLeftButton.width + 10, moveLeftButton.y, '>', function() {
			changeEventSelected(1);
		});
		moveRightButton.setGraphicSize(Std.int(moveLeftButton.width), Std.int(moveLeftButton.height));
		moveRightButton.updateHitbox();
		moveRightButton.label.size = 12;
		setAllLabelsOffset(moveRightButton, -30, 0);
		tab_group_event.add(moveRightButton);
		
		selectedEventText = new FlxText(addButton.x - 100, addButton.y + addButton.height + 6, (moveRightButton.x - addButton.x) + 186, 'Selected Event: None');
		selectedEventText.alignment = CENTER;
		tab_group_event.add(selectedEventText);
		
		tab_group_event.add(descText);
		tab_group_event.add(value1InputText);
		tab_group_event.add(value2InputText);
		tab_group_event.add(eventDropDown);
		
		UI_box.addGroup(tab_group_event);
	}
	
	function changeEventSelected(change:Int = 0)
	{
		var event = curSelectedNotes[0];
		if (curSelectedNotes.length > 1)
		{
			curEventSelected = 0;
			selectedEventText.text = 'Multiple Events Selected';
		}
		if (curSelectedNotes.length == 1 && event[2] == null) // Is event note
		{
			curEventSelected += change;
			if (curEventSelected < 0) curEventSelected = Std.int(event[1].length) - 1;
			else if (curEventSelected >= event[1].length) curEventSelected = 0;
			selectedEventText.text = 'Selected Event: ' + (curEventSelected + 1) + ' / ' + event[1].length;
		}
		else
		{
			curEventSelected = 0;
			selectedEventText.text = 'Selected Event: None';
		}
		updateNoteUI();
	}
	
	function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
	{
		for (point in button.labelOffsets)
		{
			point.set(x, y);
		}
	}
	
	var metronome:FlxUICheckBox;
	var mouseScrollingQuant:FlxUICheckBox;
	var metronomeStepper:FlxUINumericStepper;
	var metronomeOffsetStepper:FlxUINumericStepper;
	var disableAutoScrolling:FlxUICheckBox;
	#if desktop
	var waveformUseInstrumental:FlxUICheckBox;
	var waveformUseVoices:FlxUICheckBox;
	var waveformUseOpponentVoices:FlxUICheckBox;
	#end
	var instVolume:FlxUINumericStepper;
	var voicesVolume:FlxUINumericStepper;
	var opponentvoicesVolume:FlxUINumericStepper;
	
	function addChartingUI()
	{
		var tab_group_chart = new FlxUI(null, UI_box);
		tab_group_chart.name = 'Charting';
		
		#if desktop
		if (FlxG.save.data.chart_waveformInst == null) FlxG.save.data.chart_waveformInst = false;
		if (FlxG.save.data.chart_waveformVoices == null) FlxG.save.data.chart_waveformVoices = false;
		if (FlxG.save.data.chart_waveformOpponentVoices == null) FlxG.save.data.chart_waveformOpponentVoices = false;
		
		waveformUseInstrumental = new FlxUICheckBox(10, 90, null, null, "Waveform for Instrumental", 100);
		waveformUseInstrumental.checked = FlxG.save.data.chart_waveformInst;
		waveformUseInstrumental.callback = function() {
			waveformUseVoices.checked = false;
			waveformUseOpponentVoices.checked = false;
			FlxG.save.data.chart_waveformVoices = false;
			FlxG.save.data.chart_waveformOpponentVoices = false;
			FlxG.save.data.chart_waveformInst = waveformUseInstrumental.checked;
			updateWaveform();
		};
		
		waveformUseVoices = new FlxUICheckBox(waveformUseInstrumental.x + 120, waveformUseInstrumental.y, null, null, "Waveform for Voices", 100);
		waveformUseVoices.checked = FlxG.save.data.chart_waveformVoices;
		waveformUseVoices.callback = function() {
			waveformUseInstrumental.checked = false;
			waveformUseOpponentVoices.checked = false;
			FlxG.save.data.chart_waveformInst = false;
			FlxG.save.data.chart_waveformOpponentVoices = false;
			FlxG.save.data.chart_waveformVoices = waveformUseVoices.checked;
			updateWaveform();
		};
		
		waveformUseOpponentVoices = new FlxUICheckBox(waveformUseVoices.x + 120, waveformUseVoices.y, null, null, "Waveform for Opponent Voices", 100);
		waveformUseOpponentVoices.checked = FlxG.save.data.chart_waveformOpponentVoices;
		waveformUseOpponentVoices.callback = function() {
			waveformUseVoices.checked = false;
			waveformUseInstrumental.checked = false;
			FlxG.save.data.chart_waveformInst = false;
			FlxG.save.data.chart_waveformVoices = false;
			FlxG.save.data.chart_waveformOpponentVoices = waveformUseOpponentVoices.checked;
			updateWaveform();
		};
		#end
		
		check_mute_inst = new FlxUICheckBox(10, 310, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function() {
			var vol:Float = 1;
			
			if (check_mute_inst.checked) vol = 0;
			
			FlxG.sound.music.volume = vol;
		};
		mouseScrollingQuant = new FlxUICheckBox(10, 200, null, null, "Mouse Scrolling Quantization", 100);
		if (FlxG.save.data.mouseScrollingQuant == null) FlxG.save.data.mouseScrollingQuant = false;
		mouseQuant = mouseScrollingQuant.checked = FlxG.save.data.mouseScrollingQuant;
		
		mouseScrollingQuant.callback = function() {
			FlxG.save.data.mouseScrollingQuant = mouseScrollingQuant.checked;
			mouseQuant = FlxG.save.data.mouseScrollingQuant;
		};
		
		check_vortex = new FlxUICheckBox(10, 160, null, null, "Vortex Editor (BETA)", 100);
		if (FlxG.save.data.chart_vortex == null) FlxG.save.data.chart_vortex = false;
		check_vortex.checked = FlxG.save.data.chart_vortex;
		
		check_vortex.callback = function() {
			FlxG.save.data.chart_vortex = check_vortex.checked;
			vortex = FlxG.save.data.chart_vortex;
			reloadGridLayer();
		};
		
		check_warnings = new FlxUICheckBox(10, 120, null, null, "Ignore Progress Warnings", 100);
		if (FlxG.save.data.ignoreWarnings == null) FlxG.save.data.ignoreWarnings = false;
		check_warnings.checked = FlxG.save.data.ignoreWarnings;
		
		check_warnings.callback = function() {
			FlxG.save.data.ignoreWarnings = check_warnings.checked;
			ignoreWarnings = FlxG.save.data.ignoreWarnings;
		};
		
		var check_mute_vocals = new FlxUICheckBox(check_mute_inst.x + 120, check_mute_inst.y, null, null, "Mute Vocals (in editor)", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.callback = function() {
			if (vocals != null)
			{
				var vol:Float = 1;
				
				if (check_mute_vocals.checked) vol = 0;
				
				vocals.volume = vol;
			}
		};
		
		var check_mute_opp_vocals = new FlxUICheckBox(check_mute_vocals.x + 120, check_mute_inst.y, null, null, "Mute Opp Vocals (in editor)", 100);
		check_mute_opp_vocals.checked = false;
		check_mute_opp_vocals.callback = function() {
			if (opponentVocals != null)
			{
				var vol:Float = 1;
				
				if (check_mute_opp_vocals.checked) vol = 0;
				
				opponentVocals.volume = vol;
			}
		};
		
		playSoundBf = new FlxUICheckBox(check_mute_inst.x, check_mute_vocals.y + 30, null, null, 'Play Sound (Boyfriend notes)', 100, function() {
			FlxG.save.data.chart_playSoundBf = playSoundBf.checked;
		});
		if (FlxG.save.data.chart_playSoundBf == null) FlxG.save.data.chart_playSoundBf = false;
		playSoundBf.checked = FlxG.save.data.chart_playSoundBf;
		
		playSoundDad = new FlxUICheckBox(check_mute_inst.x + 120, playSoundBf.y, null, null, 'Play Sound (Opponent notes)', 100, function() {
			FlxG.save.data.chart_playSoundDad = playSoundDad.checked;
		});
		if (FlxG.save.data.chart_playSoundDad == null) FlxG.save.data.chart_playSoundDad = false;
		playSoundDad.checked = FlxG.save.data.chart_playSoundDad;
		
		metronome = new FlxUICheckBox(10, 15, null, null, "Metronome Enabled", 100, function() {
			FlxG.save.data.chart_metronome = metronome.checked;
		});
		if (FlxG.save.data.chart_metronome == null) FlxG.save.data.chart_metronome = false;
		metronome.checked = FlxG.save.data.chart_metronome;
		
		metronomeStepper = new FlxUINumericStepper(15, 55, 5, _song.bpm, 1, 1500, 1, 1, new FlxUIInputTextEx(0, 0, 25));
		metronomeOffsetStepper = new FlxUINumericStepper(metronomeStepper.x + 100, metronomeStepper.y, 25, 0, 0, 1000, 1, 1, new FlxUIInputTextEx(0, 0, 25));
		blockPressWhileTypingOnStepper.push(metronomeStepper);
		blockPressWhileTypingOnStepper.push(metronomeOffsetStepper);
		
		disableAutoScrolling = new FlxUICheckBox(metronome.x + 120, metronome.y, null, null, "Disable Autoscroll (Not Recommended)", 120, function() {
			FlxG.save.data.chart_noAutoScroll = disableAutoScrolling.checked;
		});
		if (FlxG.save.data.chart_noAutoScroll == null) FlxG.save.data.chart_noAutoScroll = false;
		disableAutoScrolling.checked = FlxG.save.data.chart_noAutoScroll;
		
		instVolume = new FlxUINumericStepper(metronomeStepper.x, 270, 0.1, 1, 0, 1, 1, 1, new FlxUIInputTextEx(0, 0, 25));
		instVolume.value = FlxG.sound.music.volume;
		instVolume.name = 'inst_volume';
		blockPressWhileTypingOnStepper.push(instVolume);
		
		voicesVolume = new FlxUINumericStepper(instVolume.x + 100, instVolume.y, 0.1, 1, 0, 1, 1, 1, new FlxUIInputTextEx(0, 0, 25));
		voicesVolume.value = vocals.volume;
		voicesVolume.name = 'voices_volume';
		blockPressWhileTypingOnStepper.push(voicesVolume);
		
		opponentvoicesVolume = new FlxUINumericStepper(voicesVolume.x + 100, instVolume.y, 0.1, 1, 0, 1, 1, 1, new FlxUIInputTextEx(0, 0, 25));
		opponentvoicesVolume.value = vocals.volume;
		opponentvoicesVolume.name = 'opponent_voices_volume';
		blockPressWhileTypingOnStepper.push(opponentvoicesVolume);
		
		sliderRate = new FlxUISlider(this, 'playbackSpeed', 120, 120, 0.5, 3, 150, 15, 5, FlxColor.WHITE, FlxColor.BLACK);
		sliderRate.nameLabel.text = 'Playback Rate';
		tab_group_chart.add(sliderRate);
		
		tab_group_chart.add(new FlxText(metronomeStepper.x, metronomeStepper.y - 15, 0, 'BPM:'));
		tab_group_chart.add(new FlxText(metronomeOffsetStepper.x, metronomeOffsetStepper.y - 15, 0, 'Offset (ms):'));
		tab_group_chart.add(new FlxText(instVolume.x, instVolume.y - 15, 0, 'Inst Volume'));
		tab_group_chart.add(new FlxText(voicesVolume.x, voicesVolume.y - 15, 0, 'Voices Volume'));
		tab_group_chart.add(new FlxText(opponentvoicesVolume.x, opponentvoicesVolume.y - 15, 0, 'Opp Voices Volume'));
		
		tab_group_chart.add(metronome);
		tab_group_chart.add(disableAutoScrolling);
		tab_group_chart.add(metronomeStepper);
		tab_group_chart.add(metronomeOffsetStepper);
		#if desktop
		tab_group_chart.add(waveformUseInstrumental);
		tab_group_chart.add(waveformUseVoices);
		tab_group_chart.add(waveformUseOpponentVoices);
		#end
		tab_group_chart.add(instVolume);
		tab_group_chart.add(voicesVolume);
		tab_group_chart.add(opponentvoicesVolume);
		tab_group_chart.add(check_mute_inst);
		tab_group_chart.add(check_mute_vocals);
		tab_group_chart.add(check_mute_opp_vocals);
		tab_group_chart.add(check_vortex);
		tab_group_chart.add(mouseScrollingQuant);
		tab_group_chart.add(check_warnings);
		tab_group_chart.add(playSoundBf);
		tab_group_chart.add(playSoundDad);
		UI_box.addGroup(tab_group_chart);
	}
	
	function loadSong():Void
	{
		FlxG.sound.music?.stop();
		vocals?.stop();
		vocals?.destroy();
		
		opponentVocals?.stop();
		opponentVocals?.destroy();
		
		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		vocals.autoDestroy = false;
		opponentVocals.autoDestroy = false;
		
		final playerVocalsSnd:Null<Sound> = Paths.voices(currentSongName, 'player') ?? Paths.voices(currentSongName, null);
		
		if (playerVocalsSnd != null) vocals.loadEmbedded(playerVocalsSnd);
		else trace('failed to load vocals for current song');
		
		FlxG.sound.list.add(vocals);
		
		try
		{
			final oppVocals:Null<Sound> = Paths.voices(currentSongName, 'opp', true);
			if (oppVocals != null)
			{
				opponentVocals.loadEmbedded(oppVocals);
				FlxG.sound.list.add(opponentVocals);
			}
		}
		
		generateSong();
		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;
	}
	
	function generateSong()
	{
		FunkinSound.playMusic(Paths.inst(currentSongName), 0.6 /*, false*/);
		
		if (instVolume != null) FlxG.sound.music.volume = instVolume.value;
		if (check_mute_inst != null && check_mute_inst.checked) FlxG.sound.music.volume = 0;
		
		FlxG.sound.music.onComplete = function() {
			Conductor.songPosition = (FlxG.sound.music.length - endOffset);
			songEnded = true;
			
			toggleMusic(false);
		};
	}
	
	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}
		
		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
	}
	
	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section':
					_song.notes[curSec].mustHitSection = check.checked;
					
					reloadGridLayer();
					updateHeads();
					
				case 'GF section':
					_song.notes[curSec].gfSection = check.checked;
					
					updateGrid();
					updateHeads();
					
				case 'Change BPM':
					_song.notes[curSec].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.notes[curSec].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_beats')
			{
				_song.notes[curSec].sectionBeats = Std.int(nums.value);
				reloadGridLayer();
			}
			else if (wname == 'song_speed')
			{
				_song.speed = nums.value;
			}
			else if (wname == 'song_bpm')
			{
				tempBpm = nums.value;
				Conductor.mapBPMChanges(_song);
				Conductor.bpm = nums.value;
			}
			else if (wname == 'song_strums')
			{
				_song.lanes = Std.int(nums.value);
				lanes = Std.int(nums.value);
				
				reloadStrumShit();
				updateGrid();
				reloadGridLayer();
				
				gridZoom();
			}
			else if (wname == 'song_keys')
			{
				_song.keys = Std.int(nums.value);
				
				reloadStrumShit();
				updateGrid();
				reloadGridLayer();
				
				gridZoom();
			}
			else if (wname == 'note_susLength')
			{
				var changed:Bool = false;
				
				for (note in curSelectedNotes)
				{
					if (note[2] == null) continue;
					
					note[2] = nums.value;
					changed = true;
				}
				
				if (changed) updateGrid();
			}
			else if (wname == 'section_bpm')
			{
				_song.notes[curSec].bpm = nums.value;
				updateGrid();
			}
			else if (wname == 'inst_volume')
			{
				FlxG.sound.music.volume = nums.value;
			}
			else if (wname == 'voices_volume')
			{
				vocals.volume = nums.value;
			}
			else if (wname == 'opponent_voices_volume') // data todo
			{
				opponentVocals.volume = nums.value;
			}
		}
		else if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			// if (sender == noteSplashesInputText)
			// {
			// 	_song.splashSkin = noteSplashesInputText.text;
			// }
			if (curSelectedNotes.length > 0)
			{
				if (sender == value1InputText && curSelectedNotes.length == 1)
				{
					if (curSelectedNotes[0][1][curEventSelected] != null)
					{
						curSelectedNotes[0][1][curEventSelected][1] = value1InputText.text;
						updateGrid();
					}
				}
				else if (sender == value2InputText && curSelectedNotes.length == 1)
				{
					if (curSelectedNotes[0][1][curEventSelected] != null)
					{
						curSelectedNotes[0][1][curEventSelected][2] = value2InputText.text;
						updateGrid();
					}
				}
				else if (sender == strumTimeInputText) // todo only difference maybe
				{
					var value:Float = Std.parseFloat(strumTimeInputText.text);
					if (Math.isNaN(value)) value = 0;
					for (note in curSelectedNotes)
						note[0] = value;
					updateGrid();
				}
			}
		}
		else if (id == FlxUISlider.CHANGE_EVENT && (sender is FlxUISlider))
		{
			switch (sender)
			{
				case 'playbackSpeed':
					playbackSpeed = Std.int(sliderRate.value);
			}
		}
		
		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}
	
	// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	
	function gridZoom(snap:Bool = false):Void
	{
		final defaultGridWidth:Float = (GRID_SIZE * (4 * 2 + 1));
		final maxWidth:Float = 840;
		
		final stupidCenter:Float = (defaultGridWidth * .5 + 5);
		
		FlxTween.cancelTweensOf(this, ['CAM_OFFSET']);
		FlxTween.cancelTweensOf(FlxG.camera, ['zoom']);
		
		var nextZoom:Float = Math.min(maxWidth / gridBG.width, 1);
		var nextOffset:Float = (gridBG.width * .5 - (stupidCenter / nextZoom));
		
		if (snap)
		{
			camPos.x = (strumLine.x + (CAM_OFFSET = nextOffset));
			FlxG.camera.zoom = nextZoom;
		}
		else
		{
			FlxTween.tween(this, {CAM_OFFSET: nextOffset}, 0.325, {ease: FlxEase.quadOut});
			FlxTween.tween(FlxG.camera, {zoom: nextZoom}, 0.325, {ease: FlxEase.quadOut});
		}
	}
	
	var updatedSection:Bool = false;
	
	function sectionStartTime(add:Int = 0):Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		
		for (i in 0...curSec + add)
		{
			if (_song.notes[i]?.changeBPM) daBPM = _song.notes[i].bpm;
			
			daPos += (getSectionBeats(i) * (60000 / daBPM));
		}
		
		return daPos;
	}
	
	function getSectionIndex(time:Float = 0):Int
	{
		var daBPM:Float = _song.bpm, daPos:Float = 0, i:Int = 0;
		
		while (true)
		{
			if (_song.notes[i]?.changeBPM) daBPM = _song.notes[i].bpm;
			
			daPos += (getSectionBeats(i++) * (60000 / daBPM));
			
			if (daPos >= time) return i;
		}
	}
	
	var lastConductorPos:Float;
	var colorSine:Float = 0;
	
	override function update(elapsed:Float)
	{
		curStep = recalculateSteps();
		if (camPos != null) camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);
		
		bg.scale.x = bg.scale.y = (1 / FlxG.camera.zoom);
		
		if (gradient.alive)
		{
			gradient.scale.x = FlxG.camera.viewWidth;
			gradient.y = FlxMath.lerp(gradient.y, gradient.y - 10, 1 - Math.exp(-elapsed * 3));
		}
		
		if (FlxG.sound.music.time < 0)
		{
			Conductor.songPosition = 0;
			toggleMusic(false);
		}
		else if (songEnded || FlxG.sound.music.time > (FlxG.sound.music.length - endOffset)) // fuck gou
		{
			Conductor.songPosition = (FlxG.sound.music.length - endOffset);
			toggleMusic(false);
			songEnded = false;
		}
		
		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = UI_songTitle.text;
		
		strumLineUpdateY();
		for (strum in strumLineNotes)
		{
			strum.y = strumLine.y;
			strum.alpha = MathUtil.fpsLerp(strum.alpha, FlxG.sound.music.playing ? 1 : .35, .35);
		}
		
		FlxG.mouse.visible = true; // cause reasons. trust me
		camPos.y = strumLine.y;
		if (!disableAutoScrolling.checked)
		{
			if (Math.ceil(strumLine.y) >= gridBG.height)
			{
				if (_song.notes[curSec + 1] == null)
				{
					addSection();
				}
				
				changeSection(curSec + 1, false);
			}
			else if (strumLine.y < -10)
			{
				changeSection(curSec - 1, false);
			}
		}
		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);
		
		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
		{
			dummyArrow.visible = true;
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT) dummyArrow.y = FlxG.mouse.y;
			else
			{
				var gridmult = GRID_SIZE / (quantization / 16);
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridmult) * gridmult;
			}
		}
		else
		{
			dummyArrow.visible = false;
		}
		
		if (canAddNotes)
		{
			if (FlxG.mouse.justPressed)
			{
				if (FlxG.mouse.overlaps(curRenderedNotes))
				{
					for (note in curRenderedNotes)
					{
						if (!FlxG.mouse.overlaps(note)) continue;
						
						if (FlxG.keys.pressed.CONTROL || FlxG.mouse.justPressedRight)
						{
							selectNote(note);
						}
						else if (FlxG.keys.pressed.ALT)
						{
							selectNote(note);
							note.chartData[3] = noteTypeIntMap.get(currentType);
							updateGrid();
						}
						else
						{
							deleteNote(note);
							break;
						}
					}
				}
				else
				{
					if (FlxG.mouse.x > gridBG.x
						&& FlxG.mouse.x < gridBG.x + gridBG.width
						&& FlxG.mouse.y > gridBG.y
						&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
					{
						FlxG.log.add('added note');
						addNote();
					}
				}
			}
		}
		
		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
				break;
			}
		}
		
		if (!blockInput)
		{
			for (stepper in blockPressWhileTypingOnStepper)
			{
				@:privateAccess
				var leText:Dynamic = stepper.text_field;
				var leText:FlxUIInputText = leText;
				if (leText.hasFocus)
				{
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					FlxG.sound.volumeUpKeys = [];
					blockInput = true;
					break;
				}
			}
		}
		
		if (!blockInput)
		{
			FlxG.sound.muteKeys = ClientPrefs.muteKeys;
			FlxG.sound.volumeDownKeys = ClientPrefs.volumeDownKeys;
			FlxG.sound.volumeUpKeys = ClientPrefs.volumeUpKeys;
			
			for (dropDownMenu in blockPressWhileScrolling)
			{
				if (dropDownMenu.dropPanel.visible)
				{
					blockInput = true;
					break;
				}
			}
		}
		
		if (!blockInput)
		{
			var prevControlArray:Array<Dynamic> = vortexControlArray;
			if (vortex)
			{
				vortexControlArray = [
					 FlxG.keys.pressed.ONE, FlxG.keys.pressed.TWO, FlxG.keys.pressed.THREE, FlxG.keys.pressed.FOUR,
					FlxG.keys.pressed.FIVE, FlxG.keys.pressed.SIX, FlxG.keys.pressed.SEVEN, FlxG.keys.pressed.EIGHT
				];
			}
			
			if (FlxG.keys.justPressed.ENTER)
			{
				enterSong();
			}
			
			if (FlxG.keys.justPressed.E)
			{
				changeNoteSustain(Conductor.stepCrotchet);
			}
			if (FlxG.keys.justPressed.Q)
			{
				changeNoteSustain(-Conductor.stepCrotchet);
			}
			
			if (FlxG.keys.justPressed.BACKSPACE)
			{
				PlayState.chartingMode = false;
				FlxG.switchState(funkin.states.editors.MasterEditorMenu.new);
				FunkinSound.playMusic(Paths.music('freakyMenu'));
				FlxG.mouse.visible = false;
				return;
			}
			
			if (FlxG.keys.justPressed.Z && FlxG.keys.pressed.CONTROL)
			{
				undo();
			}
			
			if (FlxG.keys.justPressed.Z && curZoom > 0 && !FlxG.keys.pressed.CONTROL)
			{
				--curZoom;
				updateZoom();
			}
			if (FlxG.keys.justPressed.X && curZoom < zoomList.length - 1)
			{
				curZoom++;
				updateZoom();
			}
			
			if (FlxG.keys.justPressed.ESCAPE && FlxG.keys.pressed.SHIFT)
			{
				if (startTime == 0) playSongFromTimestamp(FlxG.sound.music.time);
				else playSongFromTimestamp(startTime);
			}
			if (FlxG.keys.justPressed.ESCAPE)
			{
				autosaveSong();
				toggleMusic(false);
				openSubState(new ChartingOptionsSubmenuOLD());
			}
			
			if (FlxG.keys.justPressed.TAB)
			{
				if (FlxG.keys.pressed.SHIFT)
				{
					UI_box.selected_tab -= 1;
					if (UI_box.selected_tab < 0) UI_box.selected_tab = 2;
				}
				else
				{
					UI_box.selected_tab += 1;
					if (UI_box.selected_tab >= 3) UI_box.selected_tab = 0;
				}
			}
			
			if (FlxG.keys.justPressed.SPACE && FlxG.sound.music.time < (FlxG.sound.music.length - endOffset)) togglePause();
			
			if (!FlxG.keys.pressed.ALT && FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.SHIFT) resetSection(true);
				else resetSection();
			}
			
			if (FlxG.mouse.wheel != 0)
			{
				resetLittleFriends();
				toggleMusic(false);
				
				if (!mouseQuant) FlxG.sound.music.time = FlxMath.bound(FlxG.sound.music.time - FlxG.mouse.wheel * Conductor.stepCrotchet * 0.8, 0, FlxG.sound.music.length);
				else scrollQuantized(FlxG.mouse.wheel > 0);
			}
			
			// ARROW VORTEX SHIT NO DEADASS
			
			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				resetLittleFriends();
				toggleMusic(false);
				
				var holdingShift:Float = 1;
				if (FlxG.keys.pressed.CONTROL) holdingShift = 0.25;
				else if (FlxG.keys.pressed.SHIFT) holdingShift = 4;
				
				var daTime:Float = 700 * FlxG.elapsed * holdingShift;
				resetLittleFriends();
				
				if (FlxG.keys.pressed.W)
				{
					if (FlxG.sound.music.time - daTime < 0) changeSection(-1);
					else FlxG.sound.music.time -= daTime;
				}
				else
				{
					if (FlxG.sound.music.time + daTime >= FlxG.sound.music.length) changeSection(0);
					else FlxG.sound.music.time += daTime;
				}
			}
			
			if (!blockInput)
			{
				if (FlxG.keys.justPressed.RIGHT)
				{
					curQuant++;
					if (curQuant > quantizations.length - 1) curQuant = 0;
					
					quantization = quantizations[curQuant];
				}
				
				if (FlxG.keys.justPressed.LEFT)
				{
					curQuant--;
					if (curQuant < 0) curQuant = quantizations.length - 1;
					
					quantization = quantizations[curQuant];
				}
				quant.animation.play('q', true, false, curQuant);
			}
			
			if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN) scrollQuantized(FlxG.keys.justPressed.UP);
			
			var style = currentType;
			
			if (FlxG.keys.pressed.SHIFT)
			{
				style = 3;
			}
			
			var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT) shiftThing = 4;
			
			if (FlxG.keys.justPressed.D) changeSection(curSec + shiftThing);
			if (FlxG.keys.justPressed.A) changeSection(curSec - shiftThing);
			
			if (vortex && !blockInput)
			{
				for (i in 0...vortexControlArray.length)
				{
					if (!vortexControlArray[i])
					{
						holdingNotes[i] = null;
					}
					else if (prevControlArray != null && vortexControlArray[i] != prevControlArray[i])
					{
						doANoteThing(quantize(FlxG.sound.music.time), i, style);
					}
				}
				
				stretchNotes();
			}
		}
		else if (FlxG.keys.justPressed.ENTER)
		{
			for (i in 0...blockPressWhileTypingOn.length)
			{
				if (blockPressWhileTypingOn[i].hasFocus)
				{
					blockPressWhileTypingOn[i].hasFocus = false;
				}
			}
		}
		// textBox.updateHitbox();
		// if (FlxG.mouse.overlaps(clickForInfo))
		// {
		// 	clickForInfo.color = FlxColor.WHITE;
		// 	// textBox.alpha = 0.5;
		// 	if (FlxG.mouse.justPressed)
		// 	{
		// 		if (FlxG.sound.music.playing)
		// 		{
		// 			FlxG.sound.music.pause();
		// 			if (vocals != null) vocals.pause();
		// 		}
		
		// 		FlxTween.tween(clickForInfo, {alpha: 0}, 0.75);
		
		// 		FlxTween.color(textBox, 0.75, FlxColor.BLACK, FlxColor.fromRGB(ClientPrefs.editorUIColor.red, ClientPrefs.editorUIColor.green, ClientPrefs.editorUIColor.blue),
		// 			{ease: FlxEase.quartOut});
		// 		FlxTween.tween(textBox, {x: 0, y: 0, alpha: 1}, 0.75, {ease: FlxEase.quartOut});
		// 		FlxTween.tween(textBox.scale, {x: 8.25806451613, y: 34.2857142857}, 0.75,
		// 			{
		// 				ease: FlxEase.quartOut,
		// 				onComplete: function(shit:FlxTween) {
		// 					openSubState(new ChartingInfoSubstate());
		// 				}
		// 			});
		// 	}
		// }
		// else
		// {
		// 	clickForInfo.color = 0xFF8c8c8c;
		// }
		
		_song.bpm = tempBpm;
		
		strumLineNotes.visible = quant.visible = vortex;
		
		// PLAYBACK SPEED CONTROLS //
		var holdingShift = FlxG.keys.pressed.SHIFT;
		var holdingLB = FlxG.keys.pressed.LBRACKET;
		var holdingRB = FlxG.keys.pressed.RBRACKET;
		var pressedLB = FlxG.keys.justPressed.LBRACKET;
		var pressedRB = FlxG.keys.justPressed.RBRACKET;
		
		if (!holdingShift && pressedLB || holdingShift && holdingLB) playbackSpeed -= 0.01;
		if (!holdingShift && pressedRB || holdingShift && holdingRB) playbackSpeed += 0.01;
		if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB)) playbackSpeed = 1;
		//
		
		if (playbackSpeed <= 0.5) playbackSpeed = 0.5;
		if (playbackSpeed >= 3) playbackSpeed = 3;
		
		FlxG.sound.music.pitch = playbackSpeed;
		vocals.pitch = playbackSpeed;
		opponentVocals.pitch = playbackSpeed;
		
		bpmTxt.text = '${calculateTime(FlxMath.roundDecimal(FlxG.sound.music.time, 2))} / ${calculateTime(FlxG.sound.music.length)} - Beat Snap: ${quantization}th'
			+ '\nSection: $curSec - Step: $curStep - Beat: ${FlxMath.roundDecimal(curDecBeat, 2)}';
			
		var playedSound:Array<Bool> = [for (_ in 0..._song.lanes) false]; // Prevents ouchy sex sounds
		
		curRenderedNotes.forEachAlive(function(note:EditorNote) {
			note.alpha = 1;
			
			if (curSelectedNotes.contains(note.chartData))
			{
				colorSine += elapsed;
				var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
				note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999); // Alpha can't be 100% or the color won't be updated for some reason, guess i will die
			}
			
			var time:Float = (note.strumTime + 1.6);
			
			if (time <= Conductor.songPosition)
			{
				note.alpha = 0.4;
				
				if (lastConductorPos <= time && FlxG.sound.music.playing && note.noteData > -1)
				{
					var fullData:Int = (note.noteData + note.lane * _song.keys);
					
					var strum = strumLineNotes.members[fullData];
					if (strum != null)
					{
						strum.lastNote = note;
						strum.playAnim('confirm', true);
						strum.resetAnim = (note.sustainLength / 1000) + 0.15;
					}
					
					var char:OurLittleFriend = note.mustPress ? littleBF : littleDad;
					char.sing(note.noteData % 4);
					
					if (!playedSound[note.lane] && ((playSoundBf.checked && note.mustPress) || (playSoundDad.checked && !note.mustPress)))
					{
						var soundToPlay = 'hitsound';
						if (_song.player1 == 'gf') soundToPlay = ('GF_' + Std.string(note.noteData + 1)); // Easter egg
						
						FlxG.sound.play(Paths.sound(soundToPlay)).pan = (note.noteData < (_song.keys * .5) ? -0.3 : 0.3); // would be coolio
						playedSound[note.lane] = true;
					}
				}
			}
		});
		
		if (metronome.checked && lastConductorPos != Conductor.songPosition) // TODO REMOVE THAT BPM / OFFSET GARBAGE FOR METRONOME
		{
			var metroInterval:Float = 60 / metronomeStepper.value;
			var metroStep:Int = Math.floor(((Conductor.songPosition + metronomeOffsetStepper.value) / metroInterval) / 1000);
			var lastMetroStep:Int = Math.floor(((lastConductorPos + metronomeOffsetStepper.value) / metroInterval) / 1000);
			if (metroStep != lastMetroStep)
			{
				FlxG.sound.play(Paths.sound('Metronome_Tick'));
				// trace('Ticked');
			}
		}
		
		lastConductorPos = Conductor.songPosition;
		super.update(elapsed);
	}
	
	public function scrollQuantized(up:Bool):Void
	{
		final leniency:Float = 1.25;
		
		toggleMusic(false);
		
		if (vortex && vortexControlArray != null)
		{
			for (i in 0...vortexControlArray.length)
			{
				var note:Array<Dynamic> = holdingNotes[i];
				
				if (vortexControlArray[i] && holdingNotes[i] == null) doANoteThing(quantize(FlxG.sound.music.time), i, FlxG.keys.pressed.SHIFT ? 3 : currentType);
			}
		}
		
		updateCurStep();
		var beat:Float = (curDecStep / 4);
		var increase:Float = (1 / (quantization / 4));
		
		var time:Float = Conductor.beatToSeconds((up ? Math.ceil : Math.floor)((beat + (increase * leniency) * (up ? -1 : 1)) / increase) * increase);
		
		if (time < 0) return changeSection(-1);
		else if (time > (FlxG.sound.music.length - endOffset)) return changeSection(0);
		
		if (!vortex)
		{
			FlxG.sound.music.time = time;
		}
		else
		{
			FlxTween.cancelTweensOf(FlxG.sound.music, ['time']);
			FlxTween.tween(FlxG.sound.music, {time: time}, 0.07, {ease: FlxEase.circOut});
		}
	}
	
	function stretchNotes():Void
	{
		if (holdingNotes == null)
		{
			return trace('what');
		}
		
		var changed:Bool = false;
		
		for (note in holdingNotes)
		{
			if (note == null) continue;
			
			var newLength:Float = Math.max(quantize(FlxG.sound.music.time) - note[0], 0);
			changed = (changed || note[2] != newLength);
			note[2] = newLength;
		}
		
		if (changed)
		{
			updateGrid();
			updateNoteUI();
		}
	}
	
	public static function quantize(time:Float, ?quant:Int):Float
	{
		var q:Float = (1 / ((quant ?? quantization) / 4));
		return Conductor.beatToSeconds(MathUtil.quantize(Conductor.getBeat(time), q));
	}
	
	function updateZoom()
	{
		var daZoom:Float = zoomList[curZoom];
		var zoomThing:String = '1 / ' + daZoom;
		if (daZoom < 1) zoomThing = Math.round(1 / daZoom) + ' / 1';
		zoomTxt.text = 'Zoom: ' + zoomThing;
		reloadGridLayer();
	}
	
	/*
		function loadAudioBuffer() {
			if(audioBuffers[0] != null) {
				audioBuffers[0].dispose();
			}
			audioBuffers[0] = null;
			#if MODS_ALLOWED
			if(FunkinAssets.exists(Paths.modFolders('songs/' + currentSongName + '/Inst.ogg'))) {
				audioBuffers[0] = AudioBuffer.fromFile(Paths.modFolders('songs/' + currentSongName + '/Inst.ogg'));
				//trace('Custom vocals found');
			}
			else { #end
				var leVocals:String = Paths.getPath(currentSongName + '/Inst.' + Paths.SOUND_EXT, SOUND, 'songs');
				if (OpenFlAssets.exists(leVocals)) { //Vanilla inst
					audioBuffers[0] = AudioBuffer.fromFile('./' + leVocals.substr(6));
					//trace('Inst found');
				}
			#if MODS_ALLOWED
			}
			#end

			if(audioBuffers[1] != null) {
				audioBuffers[1].dispose();
			}
			audioBuffers[1] = null;
			#if MODS_ALLOWED
			if(FunkinAssets.exists(Paths.modFolders('songs/' + currentSongName + '/Voices.ogg'))) {
				audioBuffers[1] = AudioBuffer.fromFile(Paths.modFolders('songs/' + currentSongName + '/Voices.ogg'));
				//trace('Custom vocals found');
			} else { #end
				var leVocals:String = Paths.getPath(currentSongName + '/Voices.' + Paths.SOUND_EXT, SOUND, 'songs');
				if (OpenFlAssets.exists(leVocals)) { //Vanilla voices
					audioBuffers[1] = AudioBuffer.fromFile('./' + leVocals.substr(6));
					//trace('Voices found, LETS FUCKING GOOOO');
				}
			#if MODS_ALLOWED
			}
			#end
		}
	 */
	function reloadStrumShit()
	{
		if (strumLineNotes != null)
		{
			// var noteSkin = new NoteSkinHelper(Paths.noteskin(_song.arrowSkin));
			
			// NoteSkinHelper.arrowSkins = [noteSkin.data.playerSkin, noteSkin.data.opponentSkin];
			// if (_song.lanes > 2) for (i in 2..._song.lanes)
			// 	NoteSkinHelper.arrowSkins.push(noteSkin.data.extraSkin);
			
			// noteSkin.destroy();
			
			strumLineNotes.clear();
			
			for (i in 0...(_song.keys * _song.lanes))
			{
				var note:StrumNote = new StrumNote(0, 0, 0, i % _song.keys);
				
				note.setPosition(GRID_SIZE * (i + 1), strumLine.y);
				note.setGraphicSize(GRID_SIZE, GRID_SIZE);
				note.playAnim('static', true);
				note.scrollFactor.set(1, 1);
				note.updateHitbox();
				note.alpha = 0;
				
				strumLineNotes.add(note);
			}
		}
	}
	
	var lastSecBeats:Float = 0;
	var lastSecBeatsNext:Float = 0;
	
	function reloadGridLayer()
	{
		gridLayer.forEach(spr -> spr?.destroy());
		gridLayer.clear();
		
		if (strumLine == null)
		{
			strumLine = new FlxSprite(0, 50);
			final idx = strumLineNotes != null ? members.indexOf(strumLineNotes) : 0;
			insert(idx, strumLine);
		}
		
		strumLine.makeGraphic(Std.int(GRID_SIZE * ((_song.keys * _song.lanes) + 1)), 4);
		
		// this is all kind of cringe but its okay
		final rowsPerBeat:Int = Std.int(4 * zoomList[curZoom]);
		
		final prevRows:Int = ((getSectionBeats(curSec - 1) ?? 0) * rowsPerBeat);
		final curRows:Int = ((getSectionBeats() ?? 0) * rowsPerBeat);
		final nextRows:Int = ((getSectionBeats(curSec + 1) ?? 0) * rowsPerBeat);
		
		final columns:Int = Std.int((_song.keys * _song.lanes) + 1);
		
		var light = ClientPrefs.editorBoxColors[0],
			dark = ClientPrefs.editorBoxColors[1];
			
		inline function prepareGrid(sprite:FlxSprite, columns:Int, rows:Int, key:String, ?sub:Int, alpha:Int = 255):FlxSprite
		{
			sprite.makeGraphic(columns, rows, key);
			
			sprite.antialiasing = false;
			sprite.setGraphicSize(sprite.width * GRID_SIZE, sprite.height * GRID_SIZE);
			sprite.updateHitbox();
			
			var bm = sprite.graphic.bitmap;
			
			for (y in 0...bm.height)
			{
				for (x in 0...bm.width)
				{
					var checker:Bool = ((x + y) % 2 == 0);
					
					var alpha:Int = alpha;
					var sub:Null<Int> = sub;
					
					if ((!_song.notes[curSec].mustHitSection && (x < (_song.keys + 1) || x >= (_song.keys * 2 + 1))) ||
						(_song.notes[curSec].mustHitSection && (x < 1 || x >= (_song.keys + 1)))) sub ??= 50;
						
					sub ??= 0;
					
					var lightColor:FlxColor = FlxColor.fromRGB(light.red - sub, light.green - sub, light.blue - sub, alpha);
					var darkColor:FlxColor = FlxColor.fromRGB(dark.red - sub, dark.green - sub, dark.blue - sub, alpha);
					
					bm.setPixel32(x, y, checker ? lightColor : darkColor);
				}
			}
			
			return sprite;
		}
		
		gridBG = gridLayer.add(prepareGrid(new FlxSprite(), columns, curRows, 'charterGrid'));
		prevGridBG = nextGridBG = null;
		
		if (curSec > 0)
		{
			prevGridBG = gridLayer.add(prepareGrid(new FlxSprite(), columns, prevRows, 'charterPrevGrid', 50, 128));
			prevGridBG.y -= prevGridBG.height;
		}
		
		if (curSec < _song.notes.length)
		{
			nextGridBG = gridLayer.add(prepareGrid(new FlxSprite(), columns, nextRows, 'charterNextGrid', 50, 128));
			nextGridBG.y += gridBG.height;
		}
		
		#if desktop
		if (FlxG.save.data.chart_waveformInst || FlxG.save.data.chart_waveformVoices || FlxG.save.data.chart_waveformOpponentVoices)
		{
			updateWaveform();
		}
		#end
		
		updateGrid();
		
		// events -> strum1 seperator
		gridLayer.add(gridBG);
		
		for (i in 0...lanes)
		{
			var line = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
			
			line.x = (gridBG.x + (i * _song.keys + 1) * GRID_SIZE - 2);
			line.y = (prevGridBG?.y ?? gridBG.y);
			
			line.scale.set(4, (prevGridBG?.height ?? 0) + gridBG.height + (nextGridBG?.height ?? 0));
			line.updateHitbox();
			
			gridLayer.add(line);
		}
		
		lastSecBeats = getSectionBeats();
		if (sectionStartTime(1) >= FlxG.sound.music.length) lastSecBeatsNext = 0;
		else getSectionBeats(curSec + 1);
		
		updateHeads();
	}
	
	function strumLineUpdateY()
	{
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrotchet * 16)) / (getSectionBeats() / 4);
	}
	
	var waveformPrinted:Bool = true;
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];
	
	function updateWaveform()
	{
		#if desktop
		if (waveformPrinted)
		{
			waveformSprite.makeGraphic(Std.int(GRID_SIZE * 8), Std.int(gridBG.height), 0x00FFFFFF);
			waveformSprite.pixels.fillRect(new Rectangle(0, 0, gridBG.width, gridBG.height), 0x00FFFFFF);
		}
		waveformPrinted = false;
		
		if (!FlxG.save.data.chart_waveformInst && !FlxG.save.data.chart_waveformVoices && !FlxG.save.data.chart_waveformOpponentVoices)
		{
			// trace('Epic fail on the waveform lol');
			return;
		}
		
		wavData[0][0] = [];
		wavData[0][1] = [];
		wavData[1][0] = [];
		wavData[1][1] = [];
		
		var steps:Int = (getSectionBeats() * 4);
		var st:Float = sectionStartTime();
		var et:Float = st + (Conductor.stepCrotchet * steps);
		
		if (FlxG.save.data.chart_waveformInst)
		{
			var sound:FlxSound = FlxG.sound.music;
			if (sound._sound != null && sound._sound.__buffer != null)
			{
				var bytes:Bytes = sound._sound.__buffer.data.toBytes();
				
				wavData = waveformData(sound._sound.__buffer, bytes, st, et, 1, wavData, Std.int(gridBG.height));
			}
		}
		
		if (FlxG.save.data.chart_waveformVoices)
		{
			var sound:FlxSound = vocals;
			if (sound._sound != null && sound._sound.__buffer != null)
			{
				var bytes:Bytes = sound._sound.__buffer.data.toBytes();
				
				wavData = waveformData(sound._sound.__buffer, bytes, st, et, 1, wavData, Std.int(gridBG.height));
			}
		}
		
		if (FlxG.save.data.chart_waveformOpponentVoices)
		{
			var sound:FlxSound = opponentVocals;
			if (sound._sound != null && sound._sound.__buffer != null)
			{
				var bytes:Bytes = sound._sound.__buffer.data.toBytes();
				
				wavData = waveformData(sound._sound.__buffer, bytes, st, et, 1, wavData, Std.int(gridBG.height));
			}
		}
		
		// Draws
		var gSize:Int = Std.int(GRID_SIZE * 8);
		var hSize:Int = Std.int(gSize / 2);
		
		var lmin:Float = 0;
		var lmax:Float = 0;
		
		var rmin:Float = 0;
		var rmax:Float = 0;
		
		var size:Float = 1;
		
		var leftLength:Int = (wavData[0][0].length > wavData[0][1].length ? wavData[0][0].length : wavData[0][1].length);
		
		var rightLength:Int = (wavData[1][0].length > wavData[1][1].length ? wavData[1][0].length : wavData[1][1].length);
		
		var length:Int = leftLength > rightLength ? leftLength : rightLength;
		
		var index:Int;
		for (i in 0...length)
		{
			index = i;
			
			lmin = FlxMath.bound(((index < wavData[0][0].length && index >= 0) ? wavData[0][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			lmax = FlxMath.bound(((index < wavData[0][1].length && index >= 0) ? wavData[0][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			
			rmin = FlxMath.bound(((index < wavData[1][0].length && index >= 0) ? wavData[1][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			rmax = FlxMath.bound(((index < wavData[1][1].length && index >= 0) ? wavData[1][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			
			waveformSprite.pixels.fillRect(new Rectangle(hSize - (lmin + rmin), i * size, (lmin + rmin) + (lmax + rmax), size), FlxColor.BLUE);
		}
		
		waveformPrinted = true;
		#end
	}
	
	function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>, ?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null) return [[[0], [0]], [[0], [0]]];
		
		var khz:Float = (buffer.sampleRate / 1000);
		var channels:Int = buffer.channels;
		
		var index:Int = Std.int(time * khz);
		
		var samples:Float = ((endTime - time) * khz);
		
		if (steps == null) steps = 1280;
		
		var samplesPerRow:Float = samples / steps;
		var samplesPerRowI:Int = Std.int(samplesPerRow);
		
		var gotIndex:Int = 0;
		
		var lmin:Float = 0;
		var lmax:Float = 0;
		
		var rmin:Float = 0;
		var rmax:Float = 0;
		
		var rows:Float = 0;
		
		var simpleSample:Bool = true; // samples > 17200;
		var v1:Bool = false;
		
		if (array == null) array = [[[0], [0]], [[0], [0]]];
		
		while (index < (bytes.length - 1))
		{
			if (index >= 0)
			{
				var byte:Int = bytes.getUInt16(index * channels * 2);
				
				if (byte > 65535 / 2) byte -= 65535;
				
				var sample:Float = (byte / 65535);
				
				if (sample > 0)
				{
					if (sample > lmax) lmax = sample;
				}
				else if (sample < 0)
				{
					if (sample < lmin) lmin = sample;
				}
				
				if (channels >= 2)
				{
					byte = bytes.getUInt16((index * channels * 2) + 2);
					
					if (byte > 65535 / 2) byte -= 65535;
					
					sample = (byte / 65535);
					
					if (sample > 0)
					{
						if (sample > rmax) rmax = sample;
					}
					else if (sample < 0)
					{
						if (sample < rmin) rmin = sample;
					}
				}
			}
			
			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow)
			{
				v1 = false;
				rows -= samplesPerRow;
				
				gotIndex++;
				
				var lRMin:Float = Math.abs(lmin) * multiply;
				var lRMax:Float = lmax * multiply;
				
				var rRMin:Float = Math.abs(rmin) * multiply;
				var rRMax:Float = rmax * multiply;
				
				if (gotIndex > array[0][0].length) array[0][0].push(lRMin);
				else array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;
				
				if (gotIndex > array[0][1].length) array[0][1].push(lRMax);
				else array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;
				
				if (channels >= 2)
				{
					if (gotIndex > array[1][0].length) array[1][0].push(rRMin);
					else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;
					
					if (gotIndex > array[1][1].length) array[1][1].push(rRMax);
					else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
				}
				else
				{
					if (gotIndex > array[1][0].length) array[1][0].push(lRMin);
					else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;
					
					if (gotIndex > array[1][1].length) array[1][1].push(lRMax);
					else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
				}
				
				lmin = 0;
				lmax = 0;
				
				rmin = 0;
				rmax = 0;
			}
			
			index++;
			rows++;
			if (gotIndex > steps) break;
		}
		
		return array;
		#else
		return [[[0], [0]], [[0], [0]]];
		#end
	}
	
	function changeNoteSustain(value:Float):Void
	{
		var changed:Bool = false;
		
		for (note in curSelectedNotes)
		{
			if (note[0] < 0 || note[2] == null) continue;
			
			note[2] = Math.max(note[2] + value, 0);
			changed = true;
		}
		
		if (!changed) return;
		
		updateNoteUI();
		updateGrid();
	}
	
	function calculateTime(miliseconds:Float = 0):String
	{
		var seconds = Std.int(miliseconds / 1000);
		var minutes = Std.int(seconds / 60);
		seconds = seconds % 60;
		return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
	}
	
	function recalculateSteps(add:Float = 0):Int
	{
		var lastChange:BPMChangeEvent =
			{
				stepTime: 0,
				songTime: 0,
				bpm: 0
			}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime) lastChange = Conductor.bpmChangeMap[i];
		}
		
		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime + add) / Conductor.stepCrotchet);
		updateBeat();
		
		return curStep;
	}
	
	function resetSection(songBeginning:Bool = false, pause:Bool = true):Void
	{
		updateGrid();
		
		toggleMusic(false);
		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();
		
		resetLittleFriends();
		
		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSec = 0;
		}
		
		updateCurStep();
		
		updateGrid();
		updateSectionUI();
		updateWaveform();
	}
	
	public function toggleMusic(play:Bool):Void
	{
		if (play && !FlxG.sound.music.playing)
		{
			FlxG.sound.music.play();
			for (m in [vocals, opponentVocals])
			{
				if (m == null) continue;
				
				m.play(true, FlxG.sound.music.time);
			}
			
			Conductor.songPosition = FlxG.sound.music.time;
		}
		else if (!play && FlxG.sound.music.playing)
		{
			FlxG.sound.music.pause();
			opponentVocals?.pause();
			vocals?.pause();
			
			FlxG.sound.music.time = Conductor.songPosition;
		}
	}
	
	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		curSec = sec;
		
		if (updateMusic)
		{
			toggleMusic(false);
			
			var newTime:Float;
			
			if (curSec >= 0)
			{
				newTime = sectionStartTime();
			}
			else
			{
				newTime = FlxG.sound.music.length - endOffset;
				
				curSec = getSectionIndex(newTime);
			}
			
			if (newTime < FlxG.sound.music.length)
			{
				FlxG.sound.music.time = newTime;
				
				if (_song.notes.length <= curSec)
				{
					var old:Int = _song.notes.length;
					
					while (_song.notes.length <= curSec)
						addSection();
						
					trace('populated ${_song.notes.length - old} sections');
				}
			}
			else
			{
				FlxG.sound.music.time = curSec = 0;
			}
			
			updateCurStep();
		}
		
		var blah1:Float = getSectionBeats();
		var blah2:Float = getSectionBeats(curSec + 1);
		if (sectionStartTime(1) > FlxG.sound.music.length) blah2 = 0;
		
		if (blah1 != lastSecBeats || blah2 != lastSecBeatsNext)
		{
			reloadGridLayer();
		}
		else
		{
			updateGrid();
		}
		updateSectionUI();
		
		Conductor.songPosition = FlxG.sound.music.time;
		updateWaveform();
		resetLittleFriends();
	}
	
	function updateSectionUI():Void
	{
		var sec = _song.notes[curSec];
		
		stepperBeats.value = getSectionBeats();
		check_mustHitSection.checked = sec.mustHitSection;
		check_gfSection.checked = sec.gfSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;
		
		updateHeads();
	}
	
	function updateHeads():Void
	{
		var mustHit:Bool = _song.notes[curSec].mustHitSection;
		var isGF:Bool = _song.notes[curSec].gfSection;
		
		rightIcon.visible = (_song.lanes > 1);
		
		// leftIcon.updateOffset = rightIcon.updateOffset = false;
		
		leftIcon.changeIcon((isGF && mustHit) ? gfIcon : bfIcon);
		rightIcon.changeIcon((isGF && !mustHit) ? gfIcon : dadIcon);
		
		leftIcon.setGraphicSize(0, 45);
		leftIcon.updateHitbox(); // absolute duct tape
		rightIcon.setGraphicSize(0, 45);
		rightIcon.updateHitbox();
		
		leftIcon.x = (GRID_SIZE * (_song.keys * .5 + 1) - leftIcon.width * .5);
		rightIcon.x = (GRID_SIZE * (_song.keys * 1.5 + 1) - rightIcon.width * .5);
		
		leftIcon.y = (-leftIcon.height);
		rightIcon.y = (-rightIcon.height);
		
		var focusedIcon:HealthIcon = (mustHit ? leftIcon : rightIcon);
		
		cameraIcon.scale.copyFrom(leftIcon.scale);
		cameraIcon.updateHitbox();
		cameraIcon.setPosition(focusedIcon.x - 20, focusedIcon.y - 20);
	}
	
	function updateNoteUI():Void
	{
		var note = curSelectedNotes[0];
		if (note == null || curSelectedNotes.length != 1) return;
		
		if (note[2] != null)
		{
			stepperSusLength.value = note[2];
			if (note[3] != null)
			{
				currentType = noteTypeMap.get(note[3]);
				if (currentType <= 0)
				{
					noteTypeDropDown.selectedLabel = '';
				}
				else
				{
					noteTypeDropDown.selectedLabel = currentType + '. ' + note[3];
				}
			}
		}
		else
		{
			eventDropDown.selectedLabel = note[1][curEventSelected][0];
			
			var selected:Int = Std.parseInt(eventDropDown.selectedId);
			if (selected > 0 && selected < eventStuff.length)
			{
				descText.text = eventStuff[selected][1];
			}
			value1InputText.text = note[1][curEventSelected][1];
			value2InputText.text = note[1][curEventSelected][2];
		}
		strumTimeInputText.text = '' + note[0];
	}
	
	function updateGrid():Void
	{
		curRenderedNotes.forEach(spr -> spr?.destroy());
		curRenderedSustains.forEach(spr -> spr?.destroy());
		curRenderedNoteType.forEach(spr -> spr?.destroy());
		nextRenderedNotes.forEach(spr -> spr?.destroy());
		nextRenderedSustains.forEach(spr -> spr?.destroy());
		prevRenderedNotes.forEach(spr -> spr?.destroy());
		prevRenderedSustains.forEach(spr -> spr?.destroy());
		
		curRenderedNotes.clear();
		curRenderedSustains.clear();
		curRenderedNoteType.clear();
		nextRenderedNotes.clear();
		nextRenderedSustains.clear();
		prevRenderedNotes.clear();
		prevRenderedSustains.clear();
		
		// var skin:NoteSkinHelper = PlayState.noteSkin;
		
		// var arrowSkin:Null<String> = _song?.arrowSkin;
		
		// if (arrowSkin != null && arrowSkin.length > 0)
		// {
		// 	final path = Paths.noteskin(arrowSkin);
		// 	if (FunkinAssets.exists(path, TEXT))
		// 	{
		// 		skin = new NoteSkinHelper(path);
		// 	}
		// }
		// else
		// {
		// 	final path = Paths.noteskin('default');
		// 	if (FunkinAssets.exists(path, TEXT))
		// 	{
		// 		skin = new NoteSkinHelper(path);
		// 	}
		// }
		
		// if (skin != null)
		// {
		// 	NoteSkinHelper.instance?.destroy();
		// 	NoteSkinHelper.keys = _song.keys;
		// 	NoteSkinHelper.instance = skin;
		// }
		
		if (_song.notes[curSec].changeBPM && _song.notes[curSec].bpm > 0)
		{
			Conductor.bpm = _song.notes[curSec].bpm;
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSec)
				if (_song.notes[i].changeBPM) daBPM = _song.notes[i].bpm;
			Conductor.bpm = daBPM;
		}
		
		// CURRENT SECTION
		var beats:Float = getSectionBeats();
		for (i in _song.notes[curSec].sectionNotes)
		{
			var note:EditorNote = setupNoteData(i, false);
			curRenderedNotes.add(note);
			
			if (note.sustainLength > 0) curRenderedSustains.add(setupSusNote(note, beats));
			
			if (note.noteType != null && note.noteType.length > 0)
			{
				var typeInt:Null<Int> = noteTypeMap.get(i[3]);
				var theType:String = '' + typeInt;
				if (typeInt == null) theType = '?';
				
				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, theType, 24);
				daText.setFormat(Paths.DEFAULT_FONT, 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				daText.xAdd = -32;
				daText.yAdd = 6;
				daText.borderSize = 1;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
			
			note.mustPress = (note.lane != 1);
			
			note.player = (note.mustPress ? 0 : 1);
		}
		
		// CURRENT EVENTS
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		for (i in _song.events)
		{
			if (endThing > i[0] && i[0] >= startThing)
			{
				var note:EditorNote = setupNoteData(i, false);
				curRenderedNotes.add(note);
				
				var text:String = 'Event: ' + note.eventName + ' (' + Math.floor(note.strumTime) + ' ms)' + '\nValue 1: ' + note.eventVal1 + '\nValue 2: ' + note.eventVal2;
				if (note.eventLength > 1) text = note.eventLength + ' Events:\n' + note.eventName;
				
				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);
				daText.setFormat(Paths.DEFAULT_FONT, 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -410;
				daText.borderSize = 1;
				if (note.eventLength > 1) daText.yAdd += 8;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
				// trace('test: ' + i[0], 'startThing: ' + startThing, 'endThing: ' + endThing);
			}
		}
		
		// NEXT SECTION
		var beats:Float = getSectionBeats(1);
		if (curSec < _song.notes.length - 1)
		{
			for (i in _song.notes[curSec + 1].sectionNotes)
			{
				var note:EditorNote = setupNoteData(i, true, false);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
				if (note.sustainLength > 0)
				{
					nextRenderedSustains.add(setupSusNote(note, beats));
				}
			}
		}
		
		// PREV SECTION
		var beats:Float = getSectionBeats(-1);
		if (curSec > 0)
		{
			for (i in _song.notes[curSec - 1].sectionNotes)
			{
				var note:EditorNote = setupNoteData(i, false, true);
				note.alpha = 0.6;
				prevRenderedNotes.add(note);
				if (note.sustainLength > 0)
				{
					prevRenderedSustains.add(setupSusNote(note, beats));
				}
			}
		}
		
		// NEXT EVENTS
		var startThing:Float = sectionStartTime(1);
		var endThing:Float = sectionStartTime(2);
		for (i in _song.events)
		{
			if (endThing > i[0] && i[0] >= startThing)
			{
				var note:EditorNote = setupNoteData(i, true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
			}
		}
	}
	
	function setupNoteData(i:Array<Dynamic>, isNextSection:Bool, ?isPrevSection:Bool = false):EditorNote
	{
		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var daSus:Dynamic = i[2];
		var shifted = i[4];
		
		var intendedData = daNoteInfo;
		if (!shifted)
		{
			if (daNoteInfo % _song.keys != daNoteInfo % initialKeyCount)
			{
				shifted = true;
				intendedData = daNoteInfo + (_song.keys - initialKeyCount);
			}
		}
		else
		{
			intendedData = daNoteInfo;
		}
		
		if (daNoteInfo != intendedData && (!isNextSection && !isPrevSection))
		{
			for (p in _song.notes[curSec].sectionNotes)
			{
				if (p[0] == daStrumTime && p[1] == daNoteInfo && !p[4])
				{
					_song.notes[curSec].sectionNotes[_song.notes[curSec].sectionNotes.indexOf(p)][1] = intendedData;
					_song.notes[curSec].sectionNotes[_song.notes[curSec].sectionNotes.indexOf(p)][4] = true;
					trace('previous data: $daNoteInfo | new data: $intendedData | _song.notes data: ${_song.notes[curSec].sectionNotes[_song.notes[curSec].sectionNotes.indexOf(p)][1]} | youre not gonna shift again..? ${_song.notes[curSec].sectionNotes[_song.notes[curSec].sectionNotes.indexOf(p)][4]}');
				}
			}
		}
		
		var note:EditorNote = new EditorNote(daStrumTime, intendedData % _song.keys, null, null, true);
		note.lane = Std.int(Math.max(Math.floor(intendedData / _song.keys), 0));
		note.noteData = intendedData % _song.keys;
		note.alreadyShifted = true;
		note.chartData = i;
		
		if (daSus != null)
		{ // Common note
			if (i[3] != null && i[3] != '')
			{
				if (!Std.isOfType(i[3], String)) // Convert old note type to new note type format
				{
					i[3] = noteTypeIntMap.get(i[3]);
				}
				if (i.length > (_song.keys - 1) && (i[_song.keys - 1] == null || i[_song.keys - 1].length < 1))
				{
					i.remove(i[3]);
				}
			}
			note.sustainLength = daSus;
			note.noteType = i[3];
		}
		else
		{ // Event note
			note.loadGraphic(Paths.image('editors/eventArrow'));
			note.eventName = getEventName(i[1]);
			note.eventLength = i[1].length;
			if (i[1].length < 2)
			{
				note.eventVal1 = i[1][0][1];
				note.eventVal2 = i[1][0][2];
			}
			note.noteData = -1;
			intendedData = -1;
		}
		
		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = Math.floor(intendedData * GRID_SIZE) + GRID_SIZE;
		
		var num:Int = 0;
		if (isNextSection) num = 1;
		if (isPrevSection) num = -1;
		var beats:Float = getSectionBeats(curSec + num);
		note.y = getYfromStrumNotes(daStrumTime - sectionStartTime(), beats);
		// trace
		// if(note.y < -150) note.y = -150;
		return note;
	}
	
	function getEventName(names:Array<Dynamic>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...names.length)
		{
			if (addedOne) retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}
	
	function setupSusNote(note:EditorNote, beats:Float):FlxSprite
	{
		var height:Int = Math.floor(FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrotchet * 16, 0, GRID_SIZE * 16 * zoomList[curZoom])
			+ (GRID_SIZE * zoomList[curZoom])
			- GRID_SIZE / 2);
		var minHeight:Int = Std.int((GRID_SIZE * zoomList[curZoom] / 2) + GRID_SIZE / 2);
		if (height < minHeight) height = minHeight;
		if (height < 1) height = 1; // Prevents error of invalid height
		
		var spr:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * 0.5) - 4, note.y + GRID_SIZE / 2).makeGraphic(8, height);
		return spr;
	}
	
	private function addSection(sectionBeats:Int = 4):Void
	{
		var sec:SongSection =
			{
				sectionBeats: sectionBeats,
				bpm: _song.bpm,
				changeBPM: false,
				mustHitSection: true,
				gfSection: false,
				sectionNotes: [],
				altAnim: false
			};
			
		_song.notes.push(sec);
	}
	
	function selectNote(note:EditorNote):Void
	{
		if (!FlxG.keys.pressed.SHIFT) curSelectedNotes.resize(0);
		curSelectedNotes.push(note.chartData);
		
		if (note.noteData >= 0)
		{
			var noteDataToCheck:Int = (note.noteData + note.lane * _song.keys);
		}
		else if (curSelectedNotes.length == 1)
		{
			curEventSelected = Std.int(curSelectedNotes[0][1].length) - 1;
		}
		changeEventSelected();
		
		updateGrid();
		updateNoteUI();
	}
	
	function deleteNote(note:EditorNote):Void
	{
		var noteDataToCheck:Int = note.noteData;
		
		if (note.noteData > -1) // Normal Notes
		{
			noteDataToCheck = (note.noteData + note.lane * _song.keys);
			
			// FlxG.log.add('FOUND EVIL NOTE');
			_song.notes[curSec].sectionNotes.remove(note.chartData);
		}
		else // Events
		{
			_song.events.remove(note.chartData);
		}
		
		curSelectedNotes.remove(note.chartData);
		
		updateGrid();
	}
	
	public function doANoteThing(cs:Float, d:Int, style:Int)
	{
		for (note in curRenderedNotes)
		{
			if (Math.abs(cs - quantize(note.strumTime)) < 3 && d == (note.noteData + note.lane * _song.keys)) return deleteNote(note);
		}
		
		holdingNotes[d] = addNote(cs, d, style);
	}
	
	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}
		
		updateGrid();
	}
	
	private function addNote(strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null):Array<Dynamic>
	{
		// curUndoIndex++;
		// var newsong = _song.notes;
		//	undos.push(newsong);
		var noteStrum = getStrumTime(dummyArrow.y * (getSectionBeats() / 4), false) + sectionStartTime();
		var noteData = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE);
		var noteSus = 0;
		var daAlt = false;
		var daType = currentType;
		
		if (strum != null) noteStrum = strum;
		if (data != null) noteData = data;
		if (type != null) daType = type;
		
		var newNote:Array<Dynamic> = null;
		
		if (!FlxG.keys.pressed.SHIFT) curSelectedNotes.resize(0);
		
		if (noteData > -1)
		{
			newNote = [noteStrum, noteData, noteSus, noteTypeIntMap.get(daType), true];
			_song.notes[curSec].sectionNotes.push(newNote);
			
			if (FlxG.keys.pressed.CONTROL) choirNotes([newNote]);
		}
		else
		{
			var event = eventStuff[Std.parseInt(eventDropDown.selectedId)][0];
			var text1 = value1InputText.text;
			var text2 = value2InputText.text;
			
			newNote = [noteStrum, [[event, text1, text2]]];
			_song.events.push(newNote);
			
			if (!FlxG.keys.pressed.SHIFT || curSelectedNotes.length == 0) curEventSelected = 0;
		}
		
		curSelectedNotes.push(newNote);
		
		changeEventSelected();
		
		// trace(noteData + ', ' + noteStrum + ', ' + curSec);
		if (curSelectedNotes.length == 1) strumTimeInputText.text = '' + newNote[0];
		
		updateGrid();
		updateNoteUI();
		
		return newNote;
	}
	
	function choirNotes(notesArray:Array<Dynamic>)
	{
		var notes:Array<Dynamic> = _song.notes[curSec].sectionNotes;
		var duetNotes:Array<Array<Dynamic>> = [];
		
		for (note in notesArray)
		{
			if (note[1] < 0) continue;
			
			for (i in 0..._song.lanes)
			{
				var newData:Int = Std.int((note[1] % _song.keys) + i * _song.keys);
				var overlap:Bool = false;
				
				for (otherNote in notes)
				{
					if (Math.abs(otherNote[0] - note[0]) < 3 && otherNote[1] == newData)
					{
						overlap = true;
						break;
					}
				}
				
				if (!overlap) duetNotes.push([note[0], newData, note[2], note[3]]);
			}
		}
		
		for (note in duetNotes)
		{
			curSelectedNotes.push(note);
			notes.push(note);
		}
	}
	
	// will figure this out l8r
	// lol you didnt so i had to
	function redo()
	{
		// _song = redos[curRedoIndex];
	}
	
	function undo()
	{
		// redos.push(_song);
		undos.pop();
		// _song.notes = undos[undos.length - 1];
		///trace(_song.notes);
		// updateGrid();
	}
	
	function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if (!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height * leZoom, 0, 16 * Conductor.stepCrotchet);
	}
	
	function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if (!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrotchet, gridBG.y, gridBG.y + gridBG.height * leZoom);
	}
	
	function getYfromStrumNotes(strumTime:Float, beats:Float):Float
	{
		var value:Float = strumTime / (beats * 4 * Conductor.stepCrotchet);
		return GRID_SIZE * beats * 4 * zoomList[curZoom] * value + gridBG.y;
	}
	
	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];
		
		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}
		
		return noteData;
	}
	
	function loadJson(song:String):Void
	{
		reloadGridLayer();
		
		try
		{
			final songName = Paths.sanitize(song);
			
			ChartEditorState.song = Chart.fromPath(Paths.json('$songName/charts/${Difficulty.getDifficultyFilePath()}'));
		}
		catch (e)
		{
			Logger.log('error loading chart\nException: ${e.toString()}', ERROR, true);
			return;
		}
		
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		FlxG.resetState();
	}
	
	public static function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify(
			{
				"song": _song
			});
		FlxG.save.flush();
	}
	
	function clearEvents()
	{
		_song.events = [];
		updateGrid();
	}
	
	private function saveLevel()
	{
		if (_song.events != null && _song.events.length > 1) _song.events.sort(sortByTime);
		var json =
			{
				"song": _song
			};
			
		var data:String = Json.stringify(json, "\t");
		
		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), Paths.sanitize(_song.song) + ".json");
		}
	}
	
	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}
	
	private function saveEvents()
	{
		if (_song.events != null && _song.events.length > 1) _song.events.sort(sortByTime);
		var eventsSong:Dynamic =
			{
				events: _song.events
			};
		var json =
			{
				"song": eventsSong
			}
			
		var data:String = Json.stringify(json, "\t");
		
		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), "events.json");
		}
	}
	
	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}
	
	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}
	
	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
	
	function getSectionBeats(?section:Int):Null<Int>
	{
		return (_song.notes[section ?? curSec]?.sectionBeats ?? 4);
	}
	
	public static function enterSong()
	{
		autosaveSong();
		FlxG.mouse.visible = false;
		PlayState.SONG = _song;
		FlxG.sound.music.stop();
		if (vocals != null) vocals.stop();
		if (opponentVocals != null) opponentVocals.stop();
		
		FlxG.switchState(PlayState.new);
	}
	
	public static function playSongFromTimestamp(time:Float)
	{
		autosaveSong();
		FlxG.mouse.visible = false;
		PlayState.SONG = _song;
		
		PlayState.startOnTime = time;
		
		FlxG.sound.music?.stop();
		vocals?.stop();
		opponentVocals?.stop();
		
		FlxG.switchState(PlayState.new);
	}
	
	public function togglePause()
	{
		resetLittleFriends();
		
		toggleMusic(!FlxG.sound.music.playing);
	}
} // class ChartingInfoSubstate extends MusicBeatSubstate

// {
// 	var text:String = '';
// 	var textGrp:Array<FlxText> = [];
// 	public function new()
// 	{
// 		super();
// 		text = "Welcome to the Charting Info Hotkey / directions!
// 		\nPress ESC to close this window.
// 		\n
// 		\nLEFT Click - Place a note, or delete a note.
// 		\nRIGHT Click / Control - Select a note.
// 		\nQ/E - Decrease/Increase Note Sustain Length
// 		\nUse the \"Note\" tab to change the note type.
// 		\nIf a note type is already selected, ALT + LEFT click a note to assign the note to that type.
// 		\n
// 		\nW/S or Mouse Wheel - Change Conductor's strum time
// 		\nA/D - Go to the previous/next section
// 		\nSpace - Stop/Resume song
// 		\nLeft/Right - Change Beat Snap
// 		\nUp/Down - Change Conductor's Strum Time with Snapping
// 		\nLeft Bracket / Right Bracket - Change Song Playback Rate (SHIFT to go Faster)
// 		\nALT + Left Bracket / Right Bracket - Reset Song Playback Rate
// 		\nHold Shift to move 4x faster
// 		\nZ/X - Zoom in/out
// 		\n
// 		\nEsc - Enter charting options menu
// 		\nEnter - Play your chart in game
// 		";
// 		textGrp = [];
// 		var tipTextArray:Array<String> = text.split('\n');
// 		for (i in 0...tipTextArray.length)
// 		{
// 			var size:Int = (i <= 3) ? 30 : 20;
// 			var tipText:FlxText = new FlxText(0, 0, 0, tipTextArray[i], 16);
// 			tipText.setFormat(Paths.DEFAULT_FONT, size, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
// 			tipText.screenCenter(X);
// 			tipText.y += (i * 14) - 25;
// 			tipText.ID = i;
// 			tipText.scrollFactor.set();
// 			tipText.alpha = 0;
// 			add(tipText);
// 			textGrp.push(tipText);
// 			FlxTween.tween(tipText, {y: (i * 12), alpha: 1}, 0.25, {ease: FlxEase.quadOut, startDelay: 0.01 * i});
// 		}
// 	}
// 	override public function update(elapsed:Float)
// 	{
// 		ChartEditorState.textBox.updateHitbox();
// 		if (FlxG.keys.justPressed.ESCAPE)
// 		{
// 			for (text in textGrp)
// 			{
// 				FlxTween.cancelTweensOf(text);
// 				FlxTween.tween(text, {alpha: 0, y: text.y - 5}, 0.25, {ease: FlxEase.quadOut, startDelay: 0.01 * text.ID});
// 			}
// 			FlxTween.tween(ChartEditorState.clickForInfo, {alpha: 1}, 0.75, {ease: FlxEase.quartOut, startDelay: 0.25});
// 			FlxTween.tween(ChartEditorState.textBox, {x: ChartEditorState.bPos.x, y: ChartEditorState.bPos.y, alpha: 0.6}, 0.75, {ease: FlxEase.quartOut, startDelay: 0.25});
// 			FlxTween.color(ChartEditorState.textBox, 0.75, FlxColor.fromRGB(ClientPrefs.editorUIColor.red, ClientPrefs.editorUIColor.green, ClientPrefs.editorUIColor.blue), FlxColor.BLACK,
// 				{ease: FlxEase.quartOut, startDelay: 0.25});
// 			FlxTween.tween(ChartEditorState.textBox.scale, {x: 1, y: 1}, 0.75,
// 				{
// 					ease: FlxEase.quartOut,
// 					startDelay: 0.25,
// 					onComplete: function(shit:FlxTween) {
// 						close();
// 					}
// 				});
// 		}
// 	}
// }

class ChartingOptionsSubmenuOLD extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var menuItems:Array<String> = [
		'Resume',
		'Play from beginning',
		'Play from here',
		'Set start time',
		'Play from start time' /*, 'Botplay'*/,
		'Exit to Editor Menu'
	]; // shamelessly stolen from andromeda im sorry
	var curSelected:Int = 0;
	var canexit:Bool = false;
	
	public function new()
	{
		super();
		
		var bg:FlxSprite = new FlxSprite().makeGraphic(1280, 720, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.alpha = 0.6;
		add(bg);
		
		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);
		for (i in 0...menuItems.length)
		{
			var item = new Alphabet(0, 70 * i, menuItems[i], true, false);
			item.isMenuItem = true;
			item.targetY = i;
			item.scrollFactor.set();
			// if(menuItems[i] == 'Botplay'){
			// 	if(PlayState.instance.cpuControlled)
			// 		item.color = FlxColor.GREEN;
			// 	else
			// 		item.color = FlxColor.RED;
			// }
			grpMenuShit.add(item);
		}
		
		new FlxTimer().start(0.05, function(shit:FlxTimer) {
			canexit = true;
		});
		changeSelection();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}
	
	override public function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.ESCAPE && canexit)
		{
			close();
		}
		
		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		
		if (upP) changeSelection(-1);
		if (downP) changeSelection(1);
		if (accepted)
		{
			switch (menuItems[curSelected])
			{
				case 'Resume':
					close();
				case 'Play from beginning':
					OLDChartEditorState.enterSong();
				case 'Play from here':
					OLDChartEditorState.playSongFromTimestamp(FlxG.sound.music.time);
				case 'Play from start time':
					OLDChartEditorState.playSongFromTimestamp(OLDChartEditorState.startTime);
				case 'Set start time':
					OLDChartEditorState.startTime = FlxG.sound.music.time;
				// close();
				// case 'Botplay':
				// 	PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
				// 	PlayState.changedDifficulty = true;
				// 	PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
				// 	PlayState.instance.botplayTxt.alpha = 1;
				// 	PlayState.instance.botplaySine = 0;
				// 	trace(PlayState.instance.cpuControlled);
				// 	if(PlayState.instance.cpuControlled)
				// 		grpMenuShit.members[curSelected].color = FlxColor.GREEN;
				// 	else
				// 		grpMenuShit.members[curSelected].color = FlxColor.RED;
				// 	// close();
				case 'Exit to Editor Menu':
					FlxG.switchState(() -> new MasterEditorMenu());
					FunkinSound.playMusic(Paths.music('freakyMenu'));
			}
		}
	}
	
	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		if (curSelected < 0) curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length) curSelected = 0;
		
		var bullShit:Int = 0;
		
		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;
			
			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));
			
			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		trace(menuItems[curSelected]);
	}
}
