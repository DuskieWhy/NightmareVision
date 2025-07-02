package funkin.states.editors;

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
import flixel.addons.display.FlxGridOverlay;
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

import funkin.objects.character.CharacterBuilder;
import funkin.data.StageData;
import funkin.data.NoteSkinHelper;
import funkin.backend.Difficulty;
import funkin.data.Song;
import funkin.states.substates.Prompt;
import funkin.data.Conductor.BPMChangeEvent;
import funkin.data.Song.SwagSong;
import funkin.scripts.*;
import funkin.states.*;
import funkin.objects.*;
import funkin.backend.MusicBeatSubstate;

#if sys
import openfl.media.Sound;

import sys.FileSystem;
import sys.io.File;
#end

// this was neat //probably will rewrite the uhhh sing4 being idle later
class OurLittleFriend extends FlxSprite
{
	var _colors:Array<FlxColor> = [FlxColor.MAGENTA, FlxColor.CYAN, FlxColor.LIME, FlxColor.RED, FlxColor.WHITE];
	var _dances:Array<String> = ['left', 'down', 'up', 'right', 'idle'];
	
	var _offsetPath:String = '';
	
	public var offsets:IntMap<Array<Float>> = new IntMap();
	
	public function new(char:String)
	{
		super();
		final basePath = 'images/editors/friends/$char';
		if (FileSystem.exists(Paths.getPrimaryPath('$basePath.png')))
		{
			frames = Paths.getSparrowAtlas(basePath.substr(basePath.indexOf('/') + 1));
			animation.addByPrefix('idle', 'i', 24);
			animation.addByPrefix('left', 'l', 24, false);
			animation.addByPrefix('down', 'd', 24, false);
			animation.addByPrefix('up', 'u', 24, false);
			animation.addByPrefix('right', 'r', 24, false);
			
			setGraphicSize(100);
			updateHitbox();
			
			buildOffsets(basePath);
			
			sing(4);
		}
	}
	
	function buildOffsets(?path:String)
	{
		path ??= _offsetPath;
		if (FileSystem.exists(Paths.getPrimaryPath('$path.txt'))) for (k => i in File.getContent(Paths.getPrimaryPath('$path.txt')).trim().split('\n'))
		{
			var value = i.trim().split(',');
			offsets.set(k, [Std.parseFloat(value[0]), Std.parseFloat(value[1])]);
		}
		
		_offsetPath = path;
	}
	
	public function sing(dir:Int)
	{
		animation.play(_dances[dir]);
		
		color = _colors[dir];
		
		centerOffsets();
		
		if (offsets.exists(dir))
		{
			offset.x += offsets.get(dir)[0] * scale.x;
			offset.y += offsets.get(dir)[1] * scale.y;
		}
		// else offset.set();
	}
}

@:access(flixel.sound.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)
class ChartingState extends MusicBeatState
{
	public static var instance:ChartingState;
	
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
		[
			'Change Scroll Speed',
			"Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."
		],
		['Set Property', "Value 1: Variable name\nValue 2: New value"],
		['HUD Fade', "Fades the HUD camera\n\nValue 1: Alpha\nValue 2: Duration"],
		['Camera Fade', "Fades the game camera\n\nValue 1: Alpha\nValue 2: Duration"],
		['Camera Flash', "Value 1: Color, Alpha (Optional)\nValue 2: Fade duration"],
		[
			'Camera Zoom',
			"Changes the Camera Zoom.\n\nValue 1: Zoom Multiplier (1 is default)\n\nIn case you want a tween, use Value 2 like this:\n\n\"3, elasticOut\"\n(Duration, Ease Type)"
		],
		[
			'Camera Zoom Chain',
			"Value 1: Camera Zoom Values (0.015, 0.03)\n(also you can add another two values to make it\nzoom screen shake(0.015, 0.03, 0.01, 0.01))\n\nValue 2: Total Amount of Beat Cam Zooms and\nthe space with eachother (4, 1)"
		],
		[
			'Screen Shake Chain',
			"Value 1: Screen Shake Values (0.003, 0.0015)\n\nValue 2: Total Amount of Screen Shake per beat]"
		],
		['Set Cam Zoom', "Value 1: Zoom"],
		['Set Cam Pos', "Value 1: X\nValue 2: Y"],
		[
			"Mult SV",
			"Changes the notes' scroll velocity via multiplication.\nValue 1: Multiplier"
		],
		[
			"Constant SV",
			"Uses scroll velocity to set the speed to a constant number.\nValue 1: Constant"
		],
	];
	
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
	
	public var CAM_OFFSET:Int = 80;
	
	var dummyArrow:FlxSprite;
	
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedNotes:FlxTypedGroup<Note>;
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
	
	public static var _song:SwagSong;
	
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic> = null;
	
	var tempBpm:Float = 0;
	var playbackSpeed:Float = 1;
	
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	
	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;
	
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
	
	var totalKeyCount = 0;
	
	var text:String = "";
	
	public static var textBox:FlxSprite;
	public static var clickForInfo:FlxText;
	public static var bPos:FlxPoint;
	public static var vortex:Bool = false;
	
	public var mouseQuant:Bool = false;
	
	var bg:FlxSprite;
	var gradient:FlxSprite;
	var shit:FlxSprite;
	var canAddNotes:Bool = true;
	
	var littleBF:OurLittleFriend;
	var littleDad:OurLittleFriend;
	var littleStage:FlxSprite;
	
	override function create()
	{
		instance = this;
		if (PlayState.SONG != null) _song = PlayState.SONG;
		else
		{
			Difficulty.reset();
			
			_song =
				{
					song: 'Tutorial',
					notes: [],
					events: [],
					bpm: 100.0,
					needsVoices: true,
					arrowSkin: 'default',
					splashSkin: 'noteSplashes', // idk it would crash if i didn't
					player1: 'bf',
					player2: 'bf',
					gfVersion: 'gf',
					speed: 1,
					stage: 'stage',
					validScore: false,
					keys: 4,
					lanes: 2
				};
			addSection();
			PlayState.SONG = _song;
		}
		initialKeyCount = _song.keys;
		ClientPrefs.load();
		
		if (PlayState.noteSkin != null)
		{
			NoteSkinHelper.setNoteHelpers(PlayState.noteSkin, _song.keys);
		}
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		// DiscordClient.changePresence("Chart Editor", StringTools.replace(_song.song, '-', ' '));
		DiscordClient.changePresence("Chart Editor", "Uhm idk mane burp");
		#end
		
		camHUD = new FlxCamera();
		camHUD.bgColor = 0x0;
		FlxG.cameras.add(camHUD, false);
		
		CAM_OFFSET = 65;
		
		vortex = FlxG.save.data.chart_vortex;
		ignoreWarnings = FlxG.save.data.ignoreWarnings;
		
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF222222;
		add(bg);
		
		gradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height * 8, [0x0, ClientPrefs.editorGradColors[0], ClientPrefs.editorGradColors[1], 0x0]);
		// gradient.setPosition(0, ((FlxG.height * 4) * -1));
		gradient.scrollFactor.set(0, 0);
		gradient.updateHitbox();
		gradient.visible = ClientPrefs.editorGradVis;
		// gradient.alpha = 1;
		add(gradient);
		
		shit = new FlxSprite();
		shit.visible = false;
		add(shit);
		
		gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);
		
		waveformSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
		add(waveformSprite);
		
		// var eventIcon:FlxSprite = new FlxSprite(-GRID_SIZE - 5, -90).loadGraphic(Paths.image('eventArrow'));
		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('dad');
		// eventIcon.scrollFactor.set(1, 1);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);
		
		// eventIcon.setGraphicSize(30, 30);
		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);
		
		// add(eventIcon);
		add(leftIcon);
		add(rightIcon);
		
		leftIcon.setPosition(GRID_SIZE + 10, -100);
		rightIcon.setPosition(GRID_SIZE * 5.2, -100);
		
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedNoteType = new FlxTypedGroup<FlxText>();
		
		prevRenderedSustains = new FlxTypedGroup<FlxSprite>();
		prevRenderedNotes = new FlxTypedGroup<Note>();
		
		nextRenderedSustains = new FlxTypedGroup<FlxSprite>();
		nextRenderedNotes = new FlxTypedGroup<Note>();
		
		if (curSec >= _song.notes.length) curSec = _song.notes.length - 1;
		
		FlxG.mouse.visible = true;
		// FlxG.save.bind('funkin', 'ninjamuffin99');
		
		tempBpm = _song.bpm;
		
		addSection();
		
		// sections = _song.notes;
		
		currentSongName = Paths.formatToSongPath(_song.song);
		loadSong();
		reloadGridLayer();
		Conductor.bpm = _song.bpm;
		Conductor.mapBPMChanges(_song);
		
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
		
		totalKeyCount = (_song.keys * _song.lanes) + 1;
		
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		for (i in 0...totalKeyCount)
		{
			var note:StrumNote = new StrumNote(0, GRID_SIZE * (i + 1), strumLine.y, i % 4);
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.playAnim('static', true);
			strumLineNotes.add(note);
			note.scrollFactor.set(1, 1);
		}
		add(strumLineNotes);
		
		camPos = new FlxObject(0, 0, 1, 1);
		
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
		// 	tipText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT/*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
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
		updateHeads();
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
		// clickForInfo.setFormat(Paths.font("vcr.ttf"), 14, 0xFF8c8c8c, LEFT /*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
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
		
		createFriends();
		
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
			currentSongName = Paths.formatToSongPath(UI_songTitle.text);
			loadSong();
			updateWaveform();
		});
		
		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function() {
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function() {
				loadJson(_song.song.toLowerCase());
			}, null, ignoreWarnings));
		});
		
		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'Load Autosave', function() {
			PlayState.SONG = Song.parseJSON(FlxG.save.data.autosave);
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		});
		
		var loadEventJson:FlxButton = new FlxButton(loadAutosaveBtn.x, loadAutosaveBtn.y + 30, 'Load Events', function() {
			var songName:String = Paths.formatToSongPath(_song.song);
			var file:String = Paths.json(songName + '/events');
			#if sys
			if (#if MODS_ALLOWED FileSystem.exists(Paths.modsJson(songName + '/events')) || #end FileSystem.exists(file))
			#else
			if (OpenFlAssets.exists(file))
			#end
			{
				clearEvents();
				var events:SwagSong = Song.loadFromJson('events', songName);
				_song.events = events.events;
				changeSection(curSec);
			}
		});
		
		var saveEvents:FlxButton = new FlxButton(110, reloadSongJson.y, 'Save Events', function() {
			saveEvents();
		});
		
		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 70, 1, 1, 1, 400, 3);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';
		blockPressWhileTypingOnStepper.push(stepperBPM);
		
		var stepperStrums:FlxUINumericStepper = new FlxUINumericStepper(stepperBPM.x + (stepperBPM.width * 2), 70, 1, 2, 1, 8);
		stepperStrums.value = _song.lanes;
		stepperStrums.name = 'song_strums';
		blockPressWhileTypingOnStepper.push(stepperStrums);
		
		var stepperKeys:FlxUINumericStepper = new FlxUINumericStepper(stepperBPM.x + (stepperBPM.width * 2), 100, 1, 2, 4, 9);
		stepperKeys.value = _song.keys;
		stepperKeys.name = 'song_keys';
		blockPressWhileTypingOnStepper.push(stepperKeys);
		
		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, stepperBPM.y + 35, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
		blockPressWhileTypingOnStepper.push(stepperSpeed);
		#if MODS_ALLOWED
		var directories:Array<String> = [
			Paths.mods('characters/'),
			Paths.mods(Mods.currentModDirectory + '/characters/'),
			Paths.getPrimaryPath('characters/')
		];
		for (mod in Mods.globalMods)
			directories.push(Paths.mods(mod + '/characters/'));
		#else
		var directories:Array<String> = [Paths.getPrimaryPath('characters/')];
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
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						var charToCheck:String = file.substr(0, file.length - 5);
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
			updateHeads();
		});
		player1DropDown.selectedLabel = _song.player1;
		blockPressWhileScrolling.push(player1DropDown);
		
		var gfVersionDropDown = new FlxUIDropDownMenuEx(player1DropDown.x, player1DropDown.y + 40, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String) {
			_song.gfVersion = characters[Std.parseInt(character)];
			updateHeads();
		});
		gfVersionDropDown.selectedLabel = _song.gfVersion;
		blockPressWhileScrolling.push(gfVersionDropDown);
		
		var player2DropDown = new FlxUIDropDownMenuEx(player1DropDown.x, gfVersionDropDown.y + 40, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String) {
			_song.player2 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player2DropDown.selectedLabel = _song.player2;
		blockPressWhileScrolling.push(player2DropDown);
		
		#if MODS_ALLOWED
		var directories:Array<String> = [
			Paths.mods('stages/'),
			Paths.mods(Mods.currentModDirectory + '/stages/'),
			Paths.getPrimaryPath('stages/')
		];
		for (mod in Mods.globalMods)
			directories.push(Paths.mods(mod + '/stages/'));
		#else
		var directories:Array<String> = [Paths.getPrimaryPath('stages/')];
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
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (file.endsWith('.hx') || file.endsWith('.hxs') || file.endsWith('.hscript')) trace('NOT ADDING $file, contains an ending not supported.');
					else
					{
						var stageToCheck:String = file.endsWith('.json') ? file.substr(0, file.length - 5) : file;
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
		
		var skin = PlayState.SONG.arrowSkin;
		if (skin == null) skin = '';
		noteSkinInputText = new FlxUIInputTextEx(player2DropDown.x, player2DropDown.y + 50, 150, skin, 8);
		blockPressWhileTypingOn.push(noteSkinInputText);
		
		noteSplashesInputText = new FlxUIInputTextEx(noteSkinInputText.x, noteSkinInputText.y + 35, 150, _song.splashSkin, 8);
		blockPressWhileTypingOn.push(noteSplashesInputText);
		
		var reloadNotesButton:FlxButton = new FlxButton(noteSplashesInputText.x + 5, noteSplashesInputText.y, 'Change Notes', function() {
			_song.arrowSkin = noteSkinInputText.text;
			
			trace('noteskin file: "${_song.arrowSkin}"');
			
			updateGrid();
		});
		
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
		tab_group_song.add(reloadNotesButton);
		tab_group_song.add(noteSkinInputText);
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
		tab_group_song.add(new FlxText(noteSkinInputText.x, noteSkinInputText.y - 15, 0, 'Note Texture:'));
		// tab_group_song.add(new FlxText(noteSplashesInputText.x, noteSplashesInputText.y - 15, 0, 'Note Splashes Texture:'));
		tab_group_song.add(player2DropDown);
		tab_group_song.add(gfVersionDropDown);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(stageDropDown);
		
		UI_box.addGroup(tab_group_song);
		
		FlxG.camera.follow(camPos);
	}
	
	var grad1Colors:Array<Int> = [];
	var grad2Colors:Array<Int> = [];
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
			grad1Colors = [];
			grad2Colors = [];
			// gradient.y = 0;
			
			for (i in gradient1colors.text.split(', '))
			{
				grad1Colors.push(Std.parseInt(i));
			}
			for (i in gradient2colors.text.split(', '))
			{
				grad2Colors.push(Std.parseInt(i));
			}
			
			ClientPrefs.editorGradColors[0] = FlxColor.fromRGB(grad1Colors[0], grad1Colors[1], grad1Colors[2]);
			ClientPrefs.editorGradColors[1] = FlxColor.fromRGB(grad2Colors[0], grad2Colors[1], grad2Colors[2]);
			ClientPrefs.flush();
			
			remove(gradient);
			gradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height * 8, [
				0x0,
				FlxColor.fromRGB(grad1Colors[0], grad1Colors[1], grad1Colors[2]),
				FlxColor.fromRGB(grad2Colors[0], grad2Colors[1], grad2Colors[2]),
				0x0
			]);
			gradient.scrollFactor.set();
			insert(members.indexOf(shit), gradient);
		});
		
		check_grad_vis = new FlxUICheckBox(10, 75, null, null, "Gradient Visible?", 100);
		check_grad_vis.checked = gradient.visible;
		
		check_grad_vis.callback = function() {
			gradient.visible = check_grad_vis.checked;
			
			ClientPrefs.editorGradVis = gradient.visible;
			ClientPrefs.flush();
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
			
			gradient.visible = ClientPrefs.editorGradVis;
			check_grad_vis.checked = ClientPrefs.editorGradVis;
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
		
		stepperBeats = new FlxUINumericStepper(10, 100, 1, 4, 1, 6, 2);
		stepperBeats.value = getSectionBeats();
		stepperBeats.name = 'section_beats';
		blockPressWhileTypingOnStepper.push(stepperBeats);
		check_altAnim.name = 'check_altAnim';
		
		check_changeBPM = new FlxUICheckBox(10, stepperBeats.y + 30, null, null, 'Change BPM', 100);
		check_changeBPM.checked = _song.notes[curSec].changeBPM;
		check_changeBPM.name = 'check_changeBPM';
		
		stepperSectionBPM = new FlxUINumericStepper(10, check_changeBPM.y + 20, 1, Conductor.bpm, 0, 999, 1);
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
				note[1] = (note[1] + 4) % 8;
				_song.notes[curSec].sectionNotes[i] = note;
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
		
		stepperCopy = new FlxUINumericStepper(copyLastButton.x + 100, copyLastButton.y, 1, 1, -999, 999, 0);
		blockPressWhileTypingOnStepper.push(stepperCopy);
		
		var duetButton:FlxButton = new FlxButton(10, copyLastButton.y + 45, "Duet Notes", function() {
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1];
				if (boob > 3)
				{
					boob -= 4;
				}
				else
				{
					boob += 4;
				}
				
				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				if (note[4] != null) copiedNote.push(note[4]);
				duetNotes.push(copiedNote);
			}
			
			for (i in duetNotes)
			{
				_song.notes[curSec].sectionNotes.push(i);
			}
			
			updateGrid();
		});
		var mirrorButton:FlxButton = new FlxButton(duetButton.x + 100, duetButton.y, "Mirror Notes", function() {
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1] % _song.keys;
				boob = 3 - boob;
				if (note[1] > (_song.keys - 1)) boob += 4;
				
				note[1] = boob;
				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				if (_song.keys == 7)
				{
					for (i in 4...7)
					{
						copiedNote.push(note[i]);
					}
				}
				// duetNotes.push(copiedNote);
			}
			
			for (i in duetNotes)
			{
				// _song.notes[curSec].sectionNotes.push(i);
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
		
		stepperSusLength = new FlxUINumericStepper(10, 25, Conductor.stepCrotchet / 2, 0, 0, Conductor.stepCrotchet * 64);
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
		
		var directories:Array<String> = [];
		
		#if MODS_ALLOWED
		directories.push(Paths.mods('custom_notetypes/'));
		directories.push(Paths.mods(Mods.currentModDirectory + '/custom_notetypes/'));
		for (mod in Mods.globalMods)
			directories.push(Paths.mods(mod + '/custom_notetypes/'));
		#end
		
		var exts:Array<String> = [
			#if LUA_ALLOWED
			".lua",
			#end
			".hscript",
			".hx",
			".hxs"
		];
		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path))
					{
						for (ext in exts)
						{
							if (file.endsWith(ext))
							{
								var fileToCheck:String = file.substr(0, file.length - ext.length);
								
								if (!noteTypeMap.exists(fileToCheck))
								{
									displayNameList.push(fileToCheck);
									noteTypeMap.set(fileToCheck, key);
									noteTypeIntMap.set(key, fileToCheck);
									
									if (ext != '.lua')
									{
										var script = FunkinIris.fromFile(path, fileToCheck);
										notetypeScripts.set(fileToCheck, script);
									}
									
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
			if (curSelectedNote != null && curSelectedNote[1] > -1)
			{
				curSelectedNote[3] = noteTypeIntMap.get(currentType);
				updateGrid();
			}
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
		
		#if LUA_ALLOWED
		var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
		var directories:Array<String> = [];
		
		#if MODS_ALLOWED
		directories.push(Paths.mods('custom_events/'));
		directories.push(Paths.mods(Mods.currentModDirectory + '/custom_events/'));
		for (mod in Mods.globalMods)
			directories.push(Paths.mods(mod + '/custom_events/'));
		#end
		
		var eventexts = ['.txt', '.hx', '.hxs', '.hscript'];
		var removeShit = [4, 3, 4, 8];
		
		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					for (ext in 0...eventexts.length)
					{
						if (!FileSystem.isDirectory(path) && file != 'readme.txt' && file.endsWith(eventexts[ext]))
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
			if (curSelectedNote != null && eventStuff != null)
			{
				if (curSelectedNote != null && curSelectedNote[2] == null)
				{
					curSelectedNote[1][curEventSelected][0] = eventStuff[selectedEvent][0];
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
			if (curSelectedNote != null && curSelectedNote[2] == null) // Is event note
			{
				if (curSelectedNote[1].length < 2)
				{
					_song.events.remove(curSelectedNote);
					curSelectedNote = null;
				}
				else
				{
					curSelectedNote[1].remove(curSelectedNote[1][curEventSelected]);
				}
				
				var eventsGroup:Array<Dynamic>;
				--curEventSelected;
				if (curEventSelected < 0) curEventSelected = 0;
				else if (curSelectedNote != null
					&& curEventSelected >= (eventsGroup = curSelectedNote[1]).length) curEventSelected = eventsGroup.length - 1;
					
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
			if (curSelectedNote != null && curSelectedNote[2] == null) // Is event note
			{
				var eventsGroup:Array<Dynamic> = curSelectedNote[1];
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
		if (curSelectedNote != null && curSelectedNote[2] == null) // Is event note
		{
			curEventSelected += change;
			if (curEventSelected < 0) curEventSelected = Std.int(curSelectedNote[1].length) - 1;
			else if (curEventSelected >= curSelectedNote[1].length) curEventSelected = 0;
			selectedEventText.text = 'Selected Event: ' + (curEventSelected + 1) + ' / ' + curSelectedNote[1].length;
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
		
		waveformUseInstrumental = new FlxUICheckBox(10, 90, null, null, "Waveform for Instrumental", 100);
		waveformUseInstrumental.checked = FlxG.save.data.chart_waveformInst;
		waveformUseInstrumental.callback = function() {
			waveformUseVoices.checked = false;
			FlxG.save.data.chart_waveformVoices = false;
			FlxG.save.data.chart_waveformInst = waveformUseInstrumental.checked;
			updateWaveform();
		};
		
		waveformUseVoices = new FlxUICheckBox(waveformUseInstrumental.x + 120, waveformUseInstrumental.y, null, null, "Waveform for Voices", 100);
		waveformUseVoices.checked = FlxG.save.data.chart_waveformVoices;
		waveformUseVoices.callback = function() {
			waveformUseInstrumental.checked = false;
			FlxG.save.data.chart_waveformInst = false;
			FlxG.save.data.chart_waveformVoices = waveformUseVoices.checked;
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
		mouseScrollingQuant.checked = FlxG.save.data.mouseScrollingQuant;
		
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
		
		metronomeStepper = new FlxUINumericStepper(15, 55, 5, _song.bpm, 1, 1500, 1);
		metronomeOffsetStepper = new FlxUINumericStepper(metronomeStepper.x + 100, metronomeStepper.y, 25, 0, 0, 1000, 1);
		blockPressWhileTypingOnStepper.push(metronomeStepper);
		blockPressWhileTypingOnStepper.push(metronomeOffsetStepper);
		
		disableAutoScrolling = new FlxUICheckBox(metronome.x + 120, metronome.y, null, null, "Disable Autoscroll (Not Recommended)", 120, function() {
			FlxG.save.data.chart_noAutoScroll = disableAutoScrolling.checked;
		});
		if (FlxG.save.data.chart_noAutoScroll == null) FlxG.save.data.chart_noAutoScroll = false;
		disableAutoScrolling.checked = FlxG.save.data.chart_noAutoScroll;
		
		instVolume = new FlxUINumericStepper(metronomeStepper.x, 270, 0.1, 1, 0, 1, 1);
		instVolume.value = FlxG.sound.music.volume;
		instVolume.name = 'inst_volume';
		blockPressWhileTypingOnStepper.push(instVolume);
		
		voicesVolume = new FlxUINumericStepper(instVolume.x + 100, instVolume.y, 0.1, 1, 0, 1, 1);
		voicesVolume.value = vocals.volume;
		voicesVolume.name = 'voices_volume';
		blockPressWhileTypingOnStepper.push(voicesVolume);
		
		opponentvoicesVolume = new FlxUINumericStepper(voicesVolume.x + 100, instVolume.y, 0.1, 1, 0, 1, 1);
		opponentvoicesVolume.value = vocals.volume;
		opponentvoicesVolume.name = 'opponent_voices_volume';
		blockPressWhileTypingOnStepper.push(opponentvoicesVolume);
		
		#if !html5
		sliderRate = new FlxUISlider(this, 'playbackSpeed', 120, 120, 0.5, 3, 150, 15, 5, FlxColor.WHITE, FlxColor.BLACK);
		sliderRate.nameLabel.text = 'Playback Rate';
		tab_group_chart.add(sliderRate);
		#end
		
		tab_group_chart.add(new FlxText(metronomeStepper.x, metronomeStepper.y - 15, 0, 'BPM:'));
		tab_group_chart.add(new FlxText(metronomeOffsetStepper.x, metronomeOffsetStepper.y - 15, 0, 'Offset (ms):'));
		tab_group_chart.add(new FlxText(instVolume.x, instVolume.y - 15, 0, 'Inst Volume'));
		tab_group_chart.add(new FlxText(voicesVolume.x, voicesVolume.y - 15, 0, 'Voices Volume'));
		tab_group_chart.add(metronome);
		tab_group_chart.add(disableAutoScrolling);
		tab_group_chart.add(metronomeStepper);
		tab_group_chart.add(metronomeOffsetStepper);
		#if desktop
		tab_group_chart.add(waveformUseInstrumental);
		tab_group_chart.add(waveformUseVoices);
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
		
		try
		{
			var playerVocals = Paths.voices(currentSongName, 'player', false);
			trace('plauerVoc' + playerVocals);
			vocals.loadEmbedded(playerVocals == null ? Paths.voices(currentSongName) : playerVocals);
		}
		catch (e)
		{
			trace('fuck. ' + e);
		}
		FlxG.sound.list.add(vocals);
		
		try
		{
			var oppVocals = Paths.voices(currentSongName, 'opp', false);
			if (oppVocals != null)
			{
				opponentVocals.loadEmbedded(oppVocals);
				FlxG.sound.list.add(opponentVocals);
			}
		}
		catch (e) {}
		
		generateSong();
		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;
	}
	
	function generateSong()
	{
		FlxG.sound.playMusic(Paths.inst(currentSongName), 0.6 /*, false*/);
		if (instVolume != null) FlxG.sound.music.volume = instVolume.value;
		if (check_mute_inst != null && check_mute_inst.checked) FlxG.sound.music.volume = 0;
		
		FlxG.sound.music.onComplete = function() {
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;
			for (m in [vocals, opponentVocals])
			{
				if (m != null)
				{
					m.pause();
					m.time = 0;
				}
			}
			changeSection();
			curSec = 0;
			updateGrid();
			updateSectionUI();
			vocals.play();
			opponentVocals.play();
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
					
					updateGrid();
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
				var change = nums.value - lanes;
				
				_song.lanes = Std.int(nums.value);
				lanes = Std.int(nums.value);
				reloadStrumShit();
				updateGrid();
				reloadGridLayer();
				FlxTween.tween(this, {CAM_OFFSET: CAM_OFFSET + (50 * change)}, 0.325, {ease: FlxEase.quadOut});
				if (lanes >= 6)
				{
					var newZ = FlxG.camera.zoom - (0.125 * change);
					FlxTween.tween(FlxG.camera, {zoom: newZ}, 0.325, {ease: FlxEase.quadOut});
					for (s in [bg, gradient])
						FlxTween.tween(s.scale, {x: 1 / newZ, y: 1 / newZ}, 0.325,
							{
								onUpdate: (t) -> {
									bg.screenCenter();
								},
								ease: FlxEase.quadOut
							});
				}
				
				if (lanes <= 5 && change == -1)
				{
					FlxTween.tween(FlxG.camera, {zoom: 1}, 0.325, {ease: FlxEase.quadOut});
					for (s in [bg, gradient])
						FlxTween.tween(s.scale, {x: 1, y: 1}, 0.325,
							{
								onUpdate: (t) -> {
									bg.screenCenter();
								},
								ease: FlxEase.quadOut
							});
				}
			}
			else if (wname == 'song_keys')
			{
				_song.keys = Std.int(nums.value);
				reloadStrumShit();
				updateGrid();
				reloadGridLayer();
			}
			else if (wname == 'note_susLength')
			{
				if (curSelectedNote != null && curSelectedNote[2] != null)
				{
					curSelectedNote[2] = nums.value;
					updateGrid();
				}
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
			if (sender == noteSplashesInputText)
			{
				_song.splashSkin = noteSplashesInputText.text;
			}
			else if (curSelectedNote != null)
			{
				if (sender == value1InputText)
				{
					if (curSelectedNote[1][curEventSelected] != null)
					{
						curSelectedNote[1][curEventSelected][1] = value1InputText.text;
						updateGrid();
					}
				}
				else if (sender == value2InputText)
				{
					if (curSelectedNote[1][curEventSelected] != null)
					{
						curSelectedNote[1][curEventSelected][2] = value2InputText.text;
						updateGrid();
					}
				}
				else if (sender == strumTimeInputText)
				{
					var value:Float = Std.parseFloat(strumTimeInputText.text);
					if (Math.isNaN(value)) value = 0;
					curSelectedNote[0] = value;
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
	
	var updatedSection:Bool = false;
	
	function sectionStartTime(add:Int = 0):Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSec + add)
		{
			if (_song.notes[i] != null)
			{
				if (_song.notes[i].changeBPM)
				{
					daBPM = _song.notes[i].bpm;
				}
				daPos += getSectionBeats(i) * (1000 * 60 / daBPM);
			}
		}
		return daPos;
	}
	
	var lastConductorPos:Float;
	var colorSine:Float = 0;
	
	override function update(elapsed:Float)
	{
		curStep = recalculateSteps();
		if (camPos != null) camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);
		
		if (gradient.y == (((FlxG.height * 8) * -1) - 300))
		{
			gradient.y = 100;
		}
		gradient.y = FlxMath.lerp(gradient.y, gradient.y - 10, FlxMath.bound(elapsed * 3, 0, 1));
		
		if (FlxG.sound.music.time < 0)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if (FlxG.sound.music.time > FlxG.sound.music.length)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = UI_songTitle.text;
		
		strumLineUpdateY();
		for (i in 0...totalKeyCount)
		{
			strumLineNotes.members[i].y = strumLine.y;
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
					curRenderedNotes.forEachAlive(function(note:Note) {
						if (FlxG.mouse.overlaps(note))
						{
							if (FlxG.keys.pressed.CONTROL || FlxG.mouse.justPressedRight)
							{
								selectNote(note);
							}
							else if (FlxG.keys.pressed.ALT)
							{
								selectNote(note);
								curSelectedNote[3] = noteTypeIntMap.get(currentType);
								updateGrid();
							}
							else
							{
								// trace('tryin to delete note...');
								deleteNote(note);
							}
						}
					});
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
			FlxG.sound.muteKeys = Init.muteKeys;
			FlxG.sound.volumeDownKeys = Init.volumeDownKeys;
			FlxG.sound.volumeUpKeys = Init.volumeUpKeys;
			
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
			if (FlxG.keys.justPressed.ENTER)
			{
				enterSong();
			}
			
			if (curSelectedNote != null && curSelectedNote[1] > -1)
			{
				if (FlxG.keys.justPressed.E)
				{
					changeNoteSustain(Conductor.stepCrotchet);
				}
				if (FlxG.keys.justPressed.Q)
				{
					changeNoteSustain(-Conductor.stepCrotchet);
				}
			}
			
			if (FlxG.keys.justPressed.BACKSPACE)
			{
				PlayState.chartingMode = false;
				FlxG.switchState(funkin.states.editors.MasterEditorMenu.new);
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
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
				// PlayState.instance.setSongTime(FlxG.sound.music.time);
			}
			if (FlxG.keys.justPressed.ESCAPE)
			{
				autosaveSong();
				pause();
				openSubState(new ChartingOptionsSubmenu());
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
			
			if (FlxG.keys.justPressed.SPACE)
			{
				togglePause();
			}
			
			if (!FlxG.keys.pressed.ALT && FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.SHIFT) resetSection(true);
				else resetSection();
			}
			
			if (FlxG.mouse.wheel != 0)
			{
				resetLittleFriends();
				FlxG.sound.music.pause();
				if (!mouseQuant) FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrotchet * 0.8);
				else
				{
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.mouse.wheel > 0)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
					else
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase;
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
				}
				for (m in [vocals, opponentVocals])
				{
					if (m != null)
					{
						m.pause();
						m.time = FlxG.sound.music.time;
					}
				}
			}
			
			// ARROW VORTEX SHIT NO DEADASS
			
			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				resetLittleFriends();
				FlxG.sound.music.pause();
				
				var holdingShift:Float = 1;
				if (FlxG.keys.pressed.CONTROL) holdingShift = 0.25;
				else if (FlxG.keys.pressed.SHIFT) holdingShift = 4;
				
				var daTime:Float = 700 * FlxG.elapsed * holdingShift;
				resetLittleFriends();
				
				if (FlxG.keys.pressed.W)
				{
					FlxG.sound.music.time -= daTime;
				}
				else FlxG.sound.music.time += daTime;
				
				for (m in [vocals, opponentVocals])
				{
					if (m != null)
					{
						m.pause();
						m.time = FlxG.sound.music.time;
					}
				}
			}
			
			if (!vortex)
			{
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
				{
					FlxG.sound.music.pause();
					
					updateCurStep();
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.keys.pressed.UP)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase; // (Math.floor((beat+snap) / snap) * snap);
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
					else
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase; // (Math.floor((beat+snap) / snap) * snap);
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
				}
			}
			
			var style = currentType;
			
			if (FlxG.keys.pressed.SHIFT)
			{
				style = 3;
			}
			
			var conductorTime = Conductor.songPosition; // + sectionStartTime();Conductor.songPosition / Conductor.stepCrotchet;
			
			// AWW YOU MADE IT SEXY <3333 THX SHADMAR
			
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
			if (vortex && !blockInput)
			{
				var controlArray:Array<Bool> = [
					 FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR,
					FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN, FlxG.keys.justPressed.EIGHT
				];
				
				if (controlArray.contains(true))
				{
					var shit = (_song.keys * _song.lanes) + 1;
					
					for (i in 0...shit)
					{
						// if(controlArray[i])
						doANoteThing(conductorTime, i, style);
					}
				}
				
				var feces:Float;
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
				{
					FlxG.sound.music.pause();
					
					updateCurStep();
					// FlxG.sound.music.time = (Math.round(curStep/quants[curQuant])*quants[curQuant]) * Conductor.stepCrotchet;
					
					// (Math.floor((curStep+quants[curQuant]*1.5/(quants[curQuant]/2))/quants[curQuant])*quants[curQuant]) * Conductor.stepCrotchet;//snap into quantization
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.keys.pressed.UP)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
						feces = Conductor.beatToSeconds(fuck);
					}
					else
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase; // (Math.floor((beat+snap) / snap) * snap);
						feces = Conductor.beatToSeconds(fuck);
					}
					FlxTween.tween(FlxG.sound.music, {time: feces}, 0.1, {ease: FlxEase.circOut});
					for (m in [vocals, opponentVocals])
					{
						if (m != null)
						{
							m.pause();
							m.time = FlxG.sound.music.time;
						}
					}
					
					var dastrum = 0;
					
					if (curSelectedNote != null)
					{
						dastrum = curSelectedNote[0];
					}
					
					var secStart:Float = sectionStartTime();
					var datime = (feces - secStart) - (dastrum - secStart); // idk math find out why it doesn't work on any other section other than 0
					if (curSelectedNote != null)
					{
						var controlArray:Array<Bool> = [
							 FlxG.keys.pressed.ONE, FlxG.keys.pressed.TWO, FlxG.keys.pressed.THREE, FlxG.keys.pressed.FOUR,
							FlxG.keys.pressed.FIVE, FlxG.keys.pressed.SIX, FlxG.keys.pressed.SEVEN, FlxG.keys.pressed.EIGHT
						];
						
						if (controlArray.contains(true))
						{
							for (i in 0...controlArray.length)
							{
								if (controlArray[i]) if (curSelectedNote[1] == i) curSelectedNote[2] += datime - curSelectedNote[2] - Conductor.stepCrotchet;
							}
							updateGrid();
							updateNoteUI();
						}
					}
				}
			}
			var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT) shiftThing = 4;
			
			if (FlxG.keys.justPressed.D) changeSection(curSec + shiftThing);
			if (FlxG.keys.justPressed.A)
			{
				if (curSec <= 0)
				{
					changeSection(_song.notes.length - 1);
				}
				else
				{
					changeSection(curSec - shiftThing);
				}
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
		
		curRenderedNotes.forEach((note) -> {
			if (note.strumTime <= Conductor.songPosition)
			{
				var data:Int = note.noteData % _song.keys;
				if (note.strumTime >= lastConductorPos - 100 && FlxG.sound.music.playing && note.noteData > -1)
				{
					var char:OurLittleFriend = note.mustPress ? littleBF : littleDad;
					char.sing(data);
				}
			}
		});
		
		_song.bpm = tempBpm;
		
		strumLineNotes.visible = quant.visible = vortex;
		
		if (FlxG.sound.music.time < 0)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if (FlxG.sound.music.time > FlxG.sound.music.length)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		strumLineUpdateY();
		camPos.y = strumLine.y;
		for (i in 0...totalKeyCount)
		{
			strumLineNotes.members[i].y = strumLine.y;
			strumLineNotes.members[i].alpha = FlxG.sound.music.playing ? 1 : 0.35;
		}
		
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
		
		// bpmTxt.text = calculateTime(FlxMath.roundDecimal(FlxG.sound.music.time, 2))
		// 	+ " / "
		// 	+ calculateTime(FlxG.sound.music.length)
		// 	+ "\nSection: "
		// 	+ curSec
		// 	+ "\n\nBeat: "
		// 	+ Std.string(curDecBeat).substring(0, 4)
		// 	+ "\n\nStep: "
		// 	+ curStep
		// 	+ "\n\nBeat Snap: "
		// 	+ quantization
		// 	+ "th";
		bpmTxt.text = '${calculateTime(FlxMath.roundDecimal(FlxG.sound.music.time, 2))} / ${calculateTime(FlxG.sound.music.length)} - Beat Snap: ${quantization}th'
			+ '\nSection: $curSec - Step: $curStep - Beat: ${Std.string(curDecBeat).substring(0, 4)}';
			
		var playedSound:Array<Bool> = [false, false, false, false]; // Prevents ouchy GF sex sounds
		curRenderedNotes.forEachAlive(function(note:Note) {
			note.alpha = 1;
			if (curSelectedNote != null)
			{
				var noteDataToCheck:Int = note.noteData;
				if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += _song.keys;
				
				if (curSelectedNote[0] == note.strumTime
					&& ((curSelectedNote[2] == null && noteDataToCheck < 0)
						|| (curSelectedNote[2] != null && curSelectedNote[1] == noteDataToCheck)))
				{
					colorSine += elapsed;
					var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
					note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999); // Alpha can't be 100% or the color won't be updated for some reason, guess i will die
				}
			}
			
			if (note.strumTime <= Conductor.songPosition)
			{
				note.alpha = 0.4;
				if (note.strumTime > lastConductorPos && FlxG.sound.music.playing && note.noteData > -1)
				{
					var data:Int = note.noteData % _song.keys;
					var noteDataToCheck:Int = note.noteData;
					if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += _song.keys;
					strumLineNotes.members[noteDataToCheck].playAnim('confirm', true);
					strumLineNotes.members[noteDataToCheck].resetAnim = (note.sustainLength / 1000) + 0.15;
					if (!playedSound[data])
					{
						if ((playSoundBf.checked && note.mustPress) || (playSoundDad.checked && !note.mustPress))
						{
							var soundToPlay = 'hitsound';
							if (_song.player1 == 'gf')
							{ // Easter egg
								soundToPlay = 'GF_' + Std.string(data + 1);
							}
							
							FlxG.sound.play(Paths.sound(soundToPlay)).pan = note.noteData < 4 ? -0.3 : 0.3; // would be coolio
							playedSound[data] = true;
						}
						
						data = note.noteData;
						if (note.mustPress != _song.notes[curSec].mustHitSection)
						{
							data += _song.keys;
						}
					}
				}
			}
		});
		
		if (metronome.checked && lastConductorPos != Conductor.songPosition)
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
			if(FileSystem.exists(Paths.modFolders('songs/' + currentSongName + '/Inst.ogg'))) {
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
			if(FileSystem.exists(Paths.modFolders('songs/' + currentSongName + '/Voices.ogg'))) {
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
		totalKeyCount = (_song.keys * _song.lanes) + 1;
		
		if (strumLineNotes != null)
		{
			strumLineNotes.clear();
			for (i in 0...totalKeyCount)
			{
				var note:StrumNote = new StrumNote(0, GRID_SIZE * (i + 1), strumLine.y, i % 4);
				note.setGraphicSize(GRID_SIZE, GRID_SIZE);
				note.updateHitbox();
				note.playAnim('static', true);
				strumLineNotes.add(note);
				note.scrollFactor.set(1, 1);
			}
		}
	}
	
	var lastSecBeats:Float = 0;
	var lastSecBeatsNext:Float = 0;
	
	function reloadGridLayer()
	{
		gridLayer.clear();
		
		remove(strumLine);
		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * ((_song.keys * _song.lanes) + 1)), 4);
		insert(members.indexOf(strumLineNotes), strumLine);
		
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * ((_song.keys * _song.lanes) + 1), Std.int(GRID_SIZE * getSectionBeats() * 4 * zoomList[curZoom]), true,
			ClientPrefs.editorBoxColors[0], ClientPrefs.editorBoxColors[1]);
		#if desktop
		if (FlxG.save.data.chart_waveformInst || FlxG.save.data.chart_waveformVoices)
		{
			updateWaveform();
		}
		#end
		
		updateGrid();
		
		// events -> strum1 seperator
		
		var leHeight:Int = Std.int(gridBG.height) * -1;
		var foundPrevSec:Bool = false;
		if (sectionStartTime(-1) >= 0)
		{
			prevGridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * ((_song.keys * _song.lanes) + 1), Std.int(GRID_SIZE * getSectionBeats(curSec - 1) * 4 * zoomList[curZoom]), true,
				FlxColor.fromRGB(ClientPrefs.editorBoxColors[0].red - 40, ClientPrefs.editorBoxColors[0].green - 40, ClientPrefs.editorBoxColors[0].blue - 40),
				FlxColor.fromRGB(ClientPrefs.editorBoxColors[1].red - 40, ClientPrefs.editorBoxColors[1].green - 40, ClientPrefs.editorBoxColors[1].blue
					- 40));
			leHeight = Std.int(gridBG.y - prevGridBG.height);
			foundPrevSec = true;
		}
		else prevGridBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		prevGridBG.y = gridBG.y - prevGridBG.height;
		
		var leHeight2:Int = Std.int(gridBG.height);
		var foundNextSec:Bool = false;
		if (sectionStartTime(1) <= FlxG.sound.music.length)
		{
			nextGridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * ((_song.keys * _song.lanes) + 1), Std.int(GRID_SIZE * getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]), true,
				FlxColor.fromRGB(ClientPrefs.editorBoxColors[0].red - 40, ClientPrefs.editorBoxColors[0].green - 40, ClientPrefs.editorBoxColors[0].blue - 40),
				FlxColor.fromRGB(ClientPrefs.editorBoxColors[1].red - 40, ClientPrefs.editorBoxColors[1].green - 40, ClientPrefs.editorBoxColors[1].blue
					- 40));
			leHeight2 = Std.int(gridBG.height + nextGridBG.height);
			foundNextSec = true;
		}
		else nextGridBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		nextGridBG.y = gridBG.height;
		
		gridLayer.add(prevGridBG);
		gridLayer.add(nextGridBG);
		gridLayer.add(gridBG);
		
		var line = new FlxSprite().makeGraphic(5, FlxG.height, FlxColor.WHITE);
		line.setPosition(37.5, 0);
		line.scrollFactor.set(1, 0);
		gridLayer.add(line);
		for (i in 0...(lanes - 1))
		{
			var line = new FlxSprite().makeGraphic(5, FlxG.height, FlxColor.WHITE);
			line.setPosition(gridBG.x + ((((i + 1) * _song.keys) + 1) * GRID_SIZE), 0);
			line.scrollFactor.set(1, 0);
			gridLayer.add(line);
		}
		
		lastSecBeats = getSectionBeats();
		if (sectionStartTime(1) > FlxG.sound.music.length) lastSecBeatsNext = 0;
		else getSectionBeats(curSec + 1);
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
		
		if (!FlxG.save.data.chart_waveformInst && !FlxG.save.data.chart_waveformVoices)
		{
			// trace('Epic fail on the waveform lol');
			return;
		}
		
		wavData[0][0] = [];
		wavData[0][1] = [];
		wavData[1][0] = [];
		wavData[1][1] = [];
		
		var steps:Int = Math.round(getSectionBeats() * 4);
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
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}
		
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
		
		FlxG.sound.music.pause();
		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();
		
		resetLittleFriends();
		
		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSec = 0;
		}
		
		for (m in [vocals, opponentVocals])
		{
			if (m != null)
			{
				m.pause();
				m.time = FlxG.sound.music.time;
			}
		}
		updateCurStep();
		
		updateGrid();
		updateSectionUI();
		updateWaveform();
	}
	
	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		if (_song.notes[sec] != null)
		{
			curSec = sec;
			if (updateMusic)
			{
				FlxG.sound.music.pause();
				
				FlxG.sound.music.time = sectionStartTime();
				for (m in [vocals, opponentVocals])
				{
					if (m != null)
					{
						m.pause();
						m.time = FlxG.sound.music.time;
					}
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
		}
		else
		{
			changeSection();
		}
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
		var healthIconP1:String = loadHealthIconFromCharacter(_song.player1);
		var healthIconP2:String = loadHealthIconFromCharacter(_song.player2);
		
		if (_song.notes[curSec].mustHitSection)
		{
			leftIcon.changeIcon(healthIconP1);
			rightIcon.changeIcon(healthIconP2);
			if (_song.notes[curSec].gfSection) leftIcon.changeIcon('gf');
		}
		else
		{
			leftIcon.changeIcon(healthIconP2);
			rightIcon.changeIcon(healthIconP1);
			if (_song.notes[curSec].gfSection) leftIcon.changeIcon('gf');
		}
	}
	
	function loadHealthIconFromCharacter(char:String)
	{
		var characterPath:String = 'characters/' + char + '.json';
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path))
		{
			path = Paths.getPrimaryPath(characterPath);
		}
		
		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getPrimaryPath(characterPath);
		if (!OpenFlAssets.exists(path))
		#end
		{
			path = Paths.getPrimaryPath('characters/' + CharacterBuilder.DEFAULT_CHARACTER + '.json'); // If a character couldn't be found, change him to BF just to prevent a crash
		}
		
		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = OpenFlAssets.getText(path);
		#end
		
		var json:funkin.objects.character.CharacterBuilder.CharacterFile = cast Json.parse(rawJson);
		return json.healthicon;
	}
	
	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				stepperSusLength.value = curSelectedNote[2];
				if (curSelectedNote[3] != null)
				{
					currentType = noteTypeMap.get(curSelectedNote[3]);
					if (currentType <= 0)
					{
						noteTypeDropDown.selectedLabel = '';
					}
					else
					{
						noteTypeDropDown.selectedLabel = currentType + '. ' + curSelectedNote[3];
					}
				}
			}
			else
			{
				eventDropDown.selectedLabel = curSelectedNote[1][curEventSelected][0];
				var selected:Int = Std.parseInt(eventDropDown.selectedId);
				if (selected > 0 && selected < eventStuff.length)
				{
					descText.text = eventStuff[selected][1];
				}
				value1InputText.text = curSelectedNote[1][curEventSelected][1];
				value2InputText.text = curSelectedNote[1][curEventSelected][2];
			}
			strumTimeInputText.text = '' + curSelectedNote[0];
		}
	}
	
	function updateGrid():Void
	{
		curRenderedNotes.clear();
		curRenderedSustains.clear();
		curRenderedNoteType.clear();
		nextRenderedNotes.clear();
		nextRenderedSustains.clear();
		prevRenderedNotes.clear();
		prevRenderedSustains.clear();
		
		var skin:NoteSkinHelper = PlayState.noteSkin;
		if (_song.arrowSkin != 'default' && _song.arrowSkin != '' && _song.arrowSkin != null)
		{
			if (FileSystem.exists(Paths.modsNoteskin('${_song.arrowSkin}')))
			{
				skin = new NoteSkinHelper(Paths.modsNoteskin('${_song.arrowSkin}'));
			}
			else if (FileSystem.exists(Paths.noteskin('${_song.arrowSkin}')))
			{
				// Noteskin doesn't exist in assets, trying mods folder
				skin = new NoteSkinHelper(Paths.noteskin('${_song.arrowSkin}'));
			}
		}
		else
		{
			if (FileSystem.exists(Paths.modsNoteskin('default')))
			{
				skin = new NoteSkinHelper(Paths.modsNoteskin('default'));
			}
		}
		
		if (skin != null) NoteSkinHelper.setNoteHelpers(skin, _song.keys);
		
		if (_song.notes[curSec].changeBPM && _song.notes[curSec].bpm > 0)
		{
			Conductor.bpm = _song.notes[curSec].bpm;
			// trace('BPM of this section:');
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
			var note:Note = setupNoteData(i, false);
			curRenderedNotes.add(note);
			if (note.sustainLength > 0)
			{
				curRenderedSustains.add(setupSusNote(note, beats));
			}
			
			if (i[3] != null && note.noteType != null && note.noteType.length > 0)
			{
				var typeInt:Null<Int> = noteTypeMap.get(i[3]);
				var theType:String = '' + typeInt;
				if (typeInt == null) theType = '?';
				
				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, theType, 24);
				daText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				daText.xAdd = -32;
				daText.yAdd = 6;
				daText.borderSize = 1;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
			note.mustPress = _song.notes[curSec].mustHitSection;
			if (i[1] > (_song.keys - 1)) note.mustPress = !note.mustPress;
			
			note.player = note.mustPress ? 0 : 1;
		}
		
		// CURRENT EVENTS
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		for (i in _song.events)
		{
			if (endThing > i[0] && i[0] >= startThing)
			{
				var note:Note = setupNoteData(i, false);
				curRenderedNotes.add(note);
				
				var text:String = 'Event: ' + note.eventName + ' (' + Math.floor(note.strumTime) + ' ms)' + '\nValue 1: ' + note.eventVal1 + '\nValue 2: ' + note.eventVal2;
				if (note.eventLength > 1) text = note.eventLength + ' Events:\n' + note.eventName;
				
				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);
				daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
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
				var note:Note = setupNoteData(i, true, false);
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
		if (curSec > 1)
		{
			for (i in _song.notes[curSec - 1].sectionNotes)
			{
				var note:Note = setupNoteData(i, false, true);
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
				var note:Note = setupNoteData(i, true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
			}
		}
	}
	
	function setupNoteData(i:Array<Dynamic>, isNextSection:Bool, ?isPrevSection:Bool = false):Note
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
		
		var note:Note = new Note(daStrumTime, intendedData % _song.keys, null, null, true);
		note.lane = Std.int(Math.max(Math.floor(intendedData / _song.keys), 0));
		note.noteData = intendedData % _song.keys;
		note.alreadyShifted = true;
		
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
		if (isNextSection && _song.notes[curSec].mustHitSection != _song.notes[curSec + 1].mustHitSection)
		{
			if (intendedData > (_song.keys - 1))
			{
				note.x -= GRID_SIZE * _song.keys;
			}
			else if (daSus != null)
			{
				note.x += GRID_SIZE * _song.keys;
			}
		}
		if (isPrevSection && _song.notes[curSec].mustHitSection != _song.notes[curSec - 1].mustHitSection)
		{
			if (intendedData > (_song.keys - 1))
			{
				note.x -= GRID_SIZE * _song.keys;
			}
			else if (daSus != null)
			{
				note.x += GRID_SIZE * _song.keys;
			}
		}
		
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
	
	function setupSusNote(note:Note, beats:Float):FlxSprite
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
	
	private function addSection(sectionBeats:Float = 4):Void
	{
		var sec:SwagSection =
			{
				lengthInSteps: Std.int(sectionBeats * 4),
				sectionBeats: sectionBeats,
				bpm: _song.bpm,
				changeBPM: false,
				mustHitSection: true,
				gfSection: false,
				sectionNotes: [],
				typeOfSection: 0,
				altAnim: false
			};
			
		_song.notes.push(sec);
	}
	
	function selectNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		
		if (noteDataToCheck > -1)
		{
			if (note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += _song.keys;
			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i != curSelectedNote && i.length > 2 && i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					curSelectedNote = i;
					break;
				}
			}
		}
		else
		{
			for (i in _song.events)
			{
				if (i != curSelectedNote && i[0] == note.strumTime)
				{
					curSelectedNote = i;
					curEventSelected = Std.int(curSelectedNote[1].length) - 1;
					break;
				}
			}
		}
		changeEventSelected();
		
		updateGrid();
		updateNoteUI();
	}
	
	function deleteNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if (noteDataToCheck > -1)
		{
			if (note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += _song.keys;
			
			if (note.lane > 1) noteDataToCheck += _song.keys * (note.lane - 1);
		}
		
		if (note.noteData > -1) // Normal Notes
		{
			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					if (i == curSelectedNote) curSelectedNote = null;
					// FlxG.log.add('FOUND EVIL NOTE');
					_song.notes[curSec].sectionNotes.remove(i);
					break;
				}
			}
		}
		else // Events
		{
			for (i in _song.events)
			{
				if (i[0] == note.strumTime)
				{
					if (i == curSelectedNote)
					{
						curSelectedNote = null;
						changeEventSelected();
					}
					// FlxG.log.add('FOUND EVIL EVENT');
					_song.events.remove(i);
					break;
				}
			}
		}
		
		updateGrid();
	}
	
	public function doANoteThing(cs, d, style)
	{
		var delnote = false;
		if (strumLineNotes.members[d].overlaps(curRenderedNotes))
		{
			curRenderedNotes.forEachAlive(function(note:Note) {
				if (note.overlapsPoint(new FlxPoint(strumLineNotes.members[d].x + 1, strumLine.y + 1)) && note.noteData == d % _song.keys)
				{
					// trace('tryin to delete note...');
					if (!delnote) deleteNote(note);
					delnote = true;
				}
			});
		}
		
		if (!delnote)
		{
			addNote(cs, d, style);
		}
	}
	
	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}
		
		updateGrid();
	}
	
	private function addNote(strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null):Void
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
		
		if (noteData > -1)
		{
			_song.notes[curSec].sectionNotes.push([noteStrum, noteData, noteSus, noteTypeIntMap.get(daType), true]);
			curSelectedNote = _song.notes[curSec].sectionNotes[_song.notes[curSec].sectionNotes.length - 1];
		}
		else
		{
			var event = eventStuff[Std.parseInt(eventDropDown.selectedId)][0];
			var text1 = value1InputText.text;
			var text2 = value2InputText.text;
			_song.events.push([noteStrum, [[event, text1, text2]]]);
			curSelectedNote = _song.events[_song.events.length - 1];
			curEventSelected = 0;
		}
		changeEventSelected();
		
		if (FlxG.keys.pressed.CONTROL && noteData > -1)
		{
			_song.notes[curSec].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, noteTypeIntMap.get(daType), true]);
		}
		
		// trace(noteData + ', ' + noteStrum + ', ' + curSec);
		strumTimeInputText.text = '' + curSelectedNote[0];
		
		updateGrid();
		updateNoteUI();
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
		// shitty null fix, i fucking hate it when this happens
		// make it look sexier if possible
		reloadGridLayer();
		if (Difficulty.difficulties[PlayState.storyDifficulty] != Difficulty.defaultDifficulty)
		{
			if (Difficulty.difficulties[PlayState.storyDifficulty] == null)
			{
				PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
			}
			else
			{
				PlayState.SONG = Song.loadFromJson(song.toLowerCase() + "-" + Difficulty.difficulties[PlayState.storyDifficulty], song.toLowerCase());
			}
		}
		else
		{
			PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
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
			_file.save(data.trim(), Paths.formatToSongPath(_song.song) + ".json");
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
	
	function getSectionBeats(?section:Null<Int> = null)
	{
		if (section == null) section = curSec;
		var val:Null<Float> = null;
		
		if (_song.notes[section] != null) val = _song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}
	
	public static function enterSong()
	{
		autosaveSong();
		FlxG.mouse.visible = false;
		PlayState.SONG = _song;
		FlxG.sound.music.stop();
		if (vocals != null) vocals.stop();
		if (opponentVocals != null) opponentVocals.stop();
		
		// if(_song.stage == null) _song.stage = stageDropDown.selectedLabel;
		StageData.loadDirectory(_song);
		CoolUtil.loadAndSwitchState(PlayState.new);
	}
	
	public static function playSongFromTimestamp(time:Float)
	{
		autosaveSong();
		FlxG.mouse.visible = false;
		PlayState.SONG = _song;
		
		// if(_song.stage == null) _song.stage = stageDropDown.selectedLabel;
		StageData.loadDirectory(_song);
		PlayState.startOnTime = time;
		FlxG.sound.music.stop();
		if (vocals != null) vocals.stop();
		if (opponentVocals != null) opponentVocals.stop();
		CoolUtil.loadAndSwitchState(PlayState.new);
	}
	
	// why is this static
	public static function togglePause()
	{
		instance?.resetLittleFriends();
		
		if (FlxG.sound.music.playing)
		{
			FlxG.sound.music.pause();
			if (vocals != null) vocals.pause();
			if (opponentVocals != null) opponentVocals.pause();
		}
		else
		{
			for (m in [vocals, opponentVocals])
			{
				if (m != null)
				{
					m.play();
					m.pause();
					m.time = FlxG.sound.music.time;
					m.play();
				}
			}
			FlxG.sound.music.play();
		}
	}
	
	public static function pause()
	{
		if (FlxG.sound.music.playing)
		{
			FlxG.sound.music.pause();
			for (m in [vocals, opponentVocals])
			{
				if (m != null)
				{
					m.pause();
					m.time = FlxG.sound.music.time;
				}
			}
		}
	}
}

class AttachedFlxText extends FlxText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	
	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}

// class ChartingInfoSubstate extends MusicBeatSubstate
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
// 			tipText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
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
// 		ChartingState.textBox.updateHitbox();
// 		if (FlxG.keys.justPressed.ESCAPE)
// 		{
// 			for (text in textGrp)
// 			{
// 				FlxTween.cancelTweensOf(text);
// 				FlxTween.tween(text, {alpha: 0, y: text.y - 5}, 0.25, {ease: FlxEase.quadOut, startDelay: 0.01 * text.ID});
// 			}
// 			FlxTween.tween(ChartingState.clickForInfo, {alpha: 1}, 0.75, {ease: FlxEase.quartOut, startDelay: 0.25});
// 			FlxTween.tween(ChartingState.textBox, {x: ChartingState.bPos.x, y: ChartingState.bPos.y, alpha: 0.6}, 0.75, {ease: FlxEase.quartOut, startDelay: 0.25});
// 			FlxTween.color(ChartingState.textBox, 0.75, FlxColor.fromRGB(ClientPrefs.editorUIColor.red, ClientPrefs.editorUIColor.green, ClientPrefs.editorUIColor.blue), FlxColor.BLACK,
// 				{ease: FlxEase.quartOut, startDelay: 0.25});
// 			FlxTween.tween(ChartingState.textBox.scale, {x: 1, y: 1}, 0.75,
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

class ChartingOptionsSubmenu extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var menuItems:Array<String> = [
		'Resume',
		'Play from beginning',
		'Play from here',
		'Set start time',
		'Play from start time' /*, 'Botplay'*/,
		'Exit to main menu'
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
					ChartingState.enterSong();
				case 'Play from here':
					ChartingState.playSongFromTimestamp(FlxG.sound.music.time);
				case 'Play from start time':
					ChartingState.playSongFromTimestamp(ChartingState.startTime);
				case 'Set start time':
					ChartingState.startTime = FlxG.sound.music.time;
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
				case 'Exit to main menu':
					FlxG.switchState(() -> new MainMenuState());
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
