package funkin.states.editors;

import funkin.data.Chart;

import haxe.ds.IntMap;
import haxe.Json;
import haxe.io.Bytes;

import lime.media.AudioBuffer;

import openfl.events.Event;
import openfl.events.IOErrorEvent;
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
import flixel.util.FlxAxes;

import funkin.objects.Character;
import funkin.data.StageData;
import funkin.data.CharacterData;
import funkin.backend.Difficulty;
import funkin.data.Song;
import funkin.states.substates.Prompt;
import funkin.backend.Conductor.BPMChangeEvent;
import funkin.data.Song;
import funkin.scripts.*;
import funkin.states.*;
import funkin.objects.*;
import funkin.objects.note.*;
import funkin.states.editors.ui.*;
import funkin.backend.MusicBeatSubstate;
import funkin.states.editors.ui.ChartEditorKit;
import funkin.audio.SyncedFlxSoundGroup;

#if sys
import openfl.media.Sound;

import sys.FileSystem;
import sys.io.File;
#end

using funkin.states.editors.ui.ToolKitUtils;

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
		if (FunkinAssets.exists(Paths.getCorePath('$basePath.png')))
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
		if (FunkinAssets.exists(Paths.getCorePath('$path.txt'))) for (k => i in File.getContent(Paths.getCorePath('$path.txt')).trim().split('\n'))
		{
			var value = i.trim().split(',');
			offsets.set(k, [Std.parseFloat(value[0]), Std.parseFloat(value[1])]);
		}
		
		_offsetPath = path;
	}
	
	public function sing(dir:Int)
	{
		animation.play(_dances[dir], true);
		
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
class ChartEditorState extends haxe.ui.backend.flixel.UIState
{
	public static var instance:ChartEditorState;
	
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
	
	public var audio:PlayableSong;
	
	public var ignoreWarnings = false;
	
	public static var camHUD:FlxCamera;
	
	var undos = [];
	var redos = [];
	var eventStuff:Array<Array<String>> = [
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
	
	public var ui:ChartEditorUI;
	
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
	
	var selectionBox:DebugBounds;
	
	var gridBG:FlxSprite;
	var nextGridBG:FlxSprite;
	var prevGridBG:FlxSprite;
	
	var daquantspot = 0;
	var curEventSelected:Int = 0;
	var curUndoIndex = 0;
	var curRedoIndex = 0;
	
	public static var song:Song = null;
	
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNotes:Array<Array<Dynamic>> = [];
	var holdingNotes:Array<Array<Dynamic>> = [null, null, null, null, null, null, null, null];
	
	var tempBpm:Float = 0;
	var playbackSpeed:Float = 1;
	
	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;
	var cameraIcon:FlxSprite;
	
	var currentSongName:String;
	
	var zoomTxt:FlxText;
	
	var zoomList:Array<Float> = [0.25, 0.5, 1, 2, 3, 4, 6, 8, 12, 16, 24];
	var curZoom:Int = 2;
	
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
	
	var littleBF:OurLittleFriend;
	var littleDad:OurLittleFriend;
	var littleStage:FlxSprite;
	
	var dadIcon:String = 'dad';
	var bfIcon:String = 'bf';
	var gfIcon:String = 'gf';
	
	public static var endOffset:Int = 17;
	
	var songEnded:Bool = false;
	
	override function create()
	{
		super.create();
		
		instance = this;
		
		if (song == null)
		{
			Difficulty.reset();
			
			song = getDefaultSong();
			addSection();
		}
		
		initialKeyCount = song.keys;
		ClientPrefs.load();
		
		FlxG.sound.music?.stop();
		
		add(audio = new PlayableSong());
		
		// if (PlayState.noteSkin != null)
		// {
		// 	NoteSkinHelper.keys = song.keys;
		// }
		
		// Updating Discord Rich Presence
		// DiscordClient.changePresence("Chart Editor", StringTools.replace(song.song, '-', ' '));
		DiscordClient.changePresence("Chart Editor", "Uhm idk mane burp");
		
		FlxG.cameras.reset();
		camHUD = new FlxCamera();
		camHUD.bgColor = 0x0;
		FlxG.cameras.add(camHUD, false);
		
		camPos = new FlxObject(0, 0, 1, 1);
		FlxG.camera.follow(camPos);
		
		vortex = (FlxG.save.data.chart_vortex ?? false);
		mouseQuant = (FlxG.save.data.mouseScrollingQuant ?? false);
		ignoreWarnings = (FlxG.save.data.ignoreWarnings ?? false);
		
		gradient = new FlxBackdrop(null, Y);
		add(gradient);
		
		bg = new FlxSprite().loadGraphic(Paths.image('menus/menuDesat'));
		bg.scrollFactor.set();
		add(bg);
		createFriends();
		
		gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);
		
		waveformSprite = new FlxSprite(GRID_SIZE, 0);
		waveformSprite.antialiasing = false;
		add(waveformSprite);
		
		bfIcon = CharacterParser.fetchInfo(song.player1).healthicon;
		dadIcon = CharacterParser.fetchInfo(song.player2).healthicon;
		gfIcon = CharacterParser.fetchInfo(song.gfVersion).healthicon;
		
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
		
		if (curSec >= song.notes.length) curSec = song.notes.length - 1;
		
		FlxG.mouse.visible = true;
		
		tempBpm = song.bpm;
		
		addSection();
		
		currentSongName = Paths.sanitize(song.song);
		loadSong();
		reloadGradient();
		reloadGridLayer();
		Conductor.bpm = song.bpm;
		Conductor.mapBPMChanges(song);
		
		gridZoom(true);
		
		bpmTxt = new FlxText(10, 30, 0, "", 16);
		bpmTxt.scrollFactor.set();
		bpmTxt.camera = camHUD;
		add(bpmTxt);
		
		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * ((song.keys * song.lanes) + 1)), 4);
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
		
		zoomTxt = new FlxText(10, 20 + 380 + 10, 0, "Zoom: 1 / 1", 16);
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
		
		buildUI();
		
		prepareNotesUI();
		prepareEventsUI();
		
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
		
		selectionBox = new DebugBounds();
		selectionBox.negativeSize = true;
		selectionBox.bgAlpha = .5;
		selectionBox.kill();
		add(selectionBox);
		
		if (lastSong != currentSongName)
		{
			changeSection();
		}
		lastSong = currentSongName;
		
		updateGrid();
	}
	
	public static function getDefaultSong():Song
	{
		return {
			song: 'test',
			trackSwap: false,
			notes: [],
			events: [],
			bpm: 150,
			needsVoices: true,
			arrowSkins: ['default', 'default'],
			player1: 'bf',
			player2: 'dad',
			gfVersion: 'gf',
			speed: 1,
			stage: 'stage',
			keys: 4,
			lanes: 2
		};
	}
	
	public override function destroy():Void
	{
		FlxG.mouse.visible = false;
		
		super.destroy();
	}
	
	public function buildUI():Void
	{
		root.cameras = [camHUD];
		
		add(ui = new ChartEditorUI(this));
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
	
	var bfHitsound:Bool = false;
	var dadHitsound:Bool = false;
	
	/*
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
	 */
	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic> = [];
	
	function copySection():Void
	{
		notesCopied.resize(0);
		sectionToCopy = curSec;
		
		for (i in 0...song.notes[curSec].sectionNotes.length)
		{
			var note:Array<Dynamic> = song.notes[curSec].sectionNotes[i];
			notesCopied.push(note);
		}
		
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		for (event in song.events)
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
	}
	
	function pasteSection():Void
	{
		if (notesCopied.length < 1) return;
		
		var addToTime:Float = Conductor.stepCrotchet * (getSectionBeats() * 4 * (curSec - sectionToCopy));
		// ADDTOTIME HAS TO BE REWRITTEN
		
		for (note in notesCopied)
		{
			var copiedNote:Array<Dynamic> = [];
			var newStrumTime:Float = note[0] + addToTime;
			
			if (note[1] < 0 && ui.songDialog.sectionEventsCheckbox.selected)
			{
				var copiedEventArray:Array<Dynamic> = [];
				for (i in 0...note[2].length)
				{
					var eventToPush:Array<Dynamic> = note[2][i];
					copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
				}
				song.events.push([newStrumTime, copiedEventArray]);
			}
			else if (note[1] >= 0 && ui.songDialog.sectionNotesCheckbox.selected)
			{
				if (note[4] != null)
				{
					copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
				}
				else
				{
					copiedNote = [newStrumTime, note[1], note[2], note[3]];
				}
				song.notes[curSec].sectionNotes.push(copiedNote);
			}
		}
		updateGrid();
	}
	
	function clearSection():Void
	{
		if (ui.songDialog.sectionNotesCheckbox.selected) song.notes[curSec].sectionNotes.resize(0);
		
		if (ui.songDialog.sectionEventsCheckbox.selected)
		{
			var i:Int = song.events.length - 1;
			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);
			while (i > -1)
			{
				var event:Array<Dynamic> = song.events[i];
				if (event != null && endThing > event[0] && event[0] >= startThing)
				{
					song.events.remove(event);
				}
				--i;
			}
		}
		
		updateGrid();
		updateNoteUI();
	}
	
	function cloneSection(before:Int):Void
	{
		var copySec:Int = (curSec - before);
		
		if (before == 0 || song.notes[copySec] == null) return;
		
		for (note in song.notes[copySec].sectionNotes)
		{
			var strum = note[0] + Conductor.stepCrotchet * (getSectionBeats(curSec) * 4 * before);
			
			var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
			song.notes[curSec].sectionNotes.push(copiedNote);
		}
		
		var startThing:Float = sectionStartTime(-before);
		var endThing:Float = sectionStartTime(-before + 1);
		for (event in song.events)
		{
			var strumTime:Float = event[0];
			if (endThing > event[0] && event[0] >= startThing)
			{
				strumTime += Conductor.stepCrotchet * (getSectionBeats(curSec) * 4 * before);
				var copiedEventArray:Array<Dynamic> = [];
				for (i in 0...event[1].length)
				{
					var eventToPush:Array<Dynamic> = event[1][i];
					copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
				}
				song.events.push([strumTime, copiedEventArray]);
			}
		}
		updateGrid();
	}
	
	var currentType:Int = 0;
	
	function prepareNotesUI():Void
	{
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
		
		for (directory in directories)
		{
			if (!FunkinAssets.exists(directory)) continue;
			
			for (file in FunkinAssets.readDirectory(directory))
			{
				var path = haxe.io.Path.join([directory, file]);
				if (FunkinAssets.isDirectory(path)) continue;
				
				for (ext in FunkinScript.H_EXTS)
				{
					if (!file.endsWith(ext)) continue;
					
					var fileToCheck:String = file.substr(0, file.length - ext.length - 1);
					
					if (noteTypeMap.exists(fileToCheck)) continue;
					
					displayNameList.push(fileToCheck);
					noteTypeMap.set(fileToCheck, key);
					noteTypeIntMap.set(key, fileToCheck);
					
					key++;
				}
			}
		}
		
		for (i => name in displayNameList)
			displayNameList[i] = (name.length == 0 ? 'None' : '$i. $name');
			
		ui.songDialog.noteTypeDropdown.populateList([for (name in displayNameList) ToolKitUtils.makeSimpleDropDownItem(name)]);
		ui.songDialog.noteTypeDropdown.selectedItem = displayNameList[0];
	}
	
	function prepareEventsUI():Void
	{
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
			if (!FunkinAssets.exists(directory)) continue;
			
			for (file in FunkinAssets.readDirectory(directory))
			{
				var path = haxe.io.Path.join([directory, file]);
				for (ext in 0...eventexts.length)
				{
					if (FunkinAssets.isDirectory(path) || file == 'readme.txt' || !file.endsWith(eventexts[ext])) continue;
					
					var fileToCheck:String = file.substr(0, file.length - removeShit[ext]);
					
					if (eventPushedMap.exists(fileToCheck)) break;
					
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
					
					break;
				}
			}
		}
		eventPushedMap.clear();
		eventPushedMap = null;
		#end
		
		ui.songDialog.eventDropdown.populateList([for (ev in eventStuff) {id: ev[0], text: (ev[0].length == 0 ? 'None' : ev[0])}]);
		ui.songDialog.eventDropdown.selectedIndex = 0;
		
		ui.updateEventUI();
	}
	
	function changeEventSelected(change:Int = 0)
	{
		updateNoteUI();
	}
	
	function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
	{
		for (point in button.labelOffsets)
		{
			point.set(x, y);
		}
	}
	
	function loadSong():Void
	{
		final instVolume:Float = (audio.inst?.volume ?? 1), playerVolume:Float = audio.playerVolume, opponentVolume:Float = audio.opponentVolume;
		
		audio.stop();
		audio.populate(song);
		audio.pause();
		
		audio.inst.volume = instVolume;
		audio.playerVolume = playerVolume;
		audio.opponentVolume = opponentVolume;
		
		generateSong();
		audio.pause();
		Conductor.songPosition = sectionStartTime();
		audio.time = Conductor.songPosition;
	}
	
	function generateSong()
	{
		audio.inst.onComplete = function() {
			Conductor.songPosition = (audio.songLength - endOffset);
			songEnded = true;
			
			toggleMusic(false);
		};
	}
	
	inline function getSelectedEvents():Array<Array<Dynamic>>
	{
		return [for (note in curSelectedNotes) if (note[2] == null) note];
	}
	
	inline function getSelectedNotes():Array<Array<Dynamic>>
	{
		return [for (note in curSelectedNotes) if (note[2] != null) note];
	}
	
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
		var daBPM:Float = song.bpm;
		var daPos:Float = 0;
		
		for (i in 0...curSec + add)
		{
			if (song.notes[i]?.changeBPM) daBPM = song.notes[i].bpm;
			
			daPos += (getSectionBeats(i) * (60000 / daBPM));
		}
		
		return daPos;
	}
	
	function getSectionIndex(time:Float = 0):Int
	{
		var daBPM:Float = song.bpm, daPos:Float = 0, i:Int = 0;
		
		while (true)
		{
			if (song.notes[i]?.changeBPM) daBPM = song.notes[i].bpm;
			
			daPos += (getSectionBeats(i++) * (60000 / daBPM));
			
			if (daPos >= time) return i;
		}
	}
	
	var lastConductorPos:Float;
	var colorSine:Float = 0;
	
	override function update(elapsed:Float)
	{
		final mouseControl:Bool = (!ToolKitUtils.isHaxeUIHovered(camHUD));
		
		ToolKitUtils.update();
		
		var keyboardControl:Bool = (ToolKitUtils.currentFocus == null);
		
		if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.SPACE && ui.songDialog.hidden)
		{
			ui.songDialog.show();
			keyboardControl = false;
		}
		
		if (audio.time < 0)
		{
			Conductor.songPosition = 0;
			toggleMusic(false);
		}
		else if (songEnded || audio.time > (audio.songLength - endOffset)) // fuck gou
		{
			Conductor.songPosition = (audio.songLength - endOffset);
			toggleMusic(false);
			songEnded = false;
		}
		
		Conductor.bpm = Conductor.getBPMFromSeconds(Conductor.songPosition = audio.time).bpm;
		
		super.update(elapsed);
		
		camPos?.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);
		
		bg.scale.x = bg.scale.y = (1 / FlxG.camera.zoom);
		
		if (gradient.alive)
		{
			gradient.scale.x = FlxG.camera.viewWidth;
			gradient.y = FlxMath.lerp(gradient.y, gradient.y - 10, 1 - Math.exp(-elapsed * 3));
		}
		
		strumLineUpdateY();
		for (strum in strumLineNotes)
		{
			strum.y = strumLine.y;
			strum.alpha = MathUtil.fpsLerp(strum.alpha, audio.playing ? 1 : .35, .35);
		}
		
		FlxG.mouse.visible = true; // cause reasons. trust me
		camPos.y = strumLine.y;
		
		if (Math.ceil(strumLine.y) >= gridBG.height)
		{
			if (song.notes[curSec + 1] == null) addSection();
			
			changeSection(curSec + 1, false);
		}
		else if (strumLine.y <= -1)
		{
			changeSection(curSec - 1, false);
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
		
		if (mouseControl) mouseInput(elapsed);
		
		if (keyboardControl)
		{
			FlxG.sound.muteKeys = ClientPrefs.muteKeys;
			FlxG.sound.volumeUpKeys = ClientPrefs.volumeUpKeys;
			FlxG.sound.volumeDownKeys = ClientPrefs.volumeDownKeys;
			
			keyboardInput(elapsed);
		}
		else if (FlxG.sound.muteKeys.length > 0)
		{
			FlxG.sound.muteKeys = FlxG.sound.volumeUpKeys = FlxG.sound.volumeDownKeys = [];
		}
		
		strumLineNotes.visible = quant.visible = vortex;
		
		audio.pitch = playbackSpeed;
		
		bpmTxt.text = '${calculateTime(FlxMath.roundDecimal(audio.time, 2))} / ${calculateTime(audio.songLength)} - Beat Snap: ${quantization}th'
			+ '\nSection: $curSec - Step: $curStep - Beat: ${FlxMath.roundDecimal(curDecBeat, 2)}';
			
		var playedSound:Array<Bool> = [for (_ in 0...song.lanes) false]; // Prevents ouchy sex sounds
		
		colorSine += elapsed;
		
		curRenderedNotes.forEachAlive(function(note:EditorNote) {
			note.alpha = 1;
			
			if (curSelectedNotes.contains(note.chartData))
			{
				var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
				note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999); // Alpha can't be 100% or the color won't be updated for some reason, guess i will die
			}
			
			var time:Float = (note.strumTime + 1.6);
			
			if (time <= Conductor.songPosition)
			{
				note.alpha = 0.4;
				
				if (lastConductorPos <= time && audio.playing && note.noteData > -1)
				{
					var fullData:Int = (note.noteData + note.lane * song.keys);
					
					var strum = strumLineNotes.members[fullData];
					if (strum != null)
					{
						strum.lastNote = note;
						strum.playAnim('confirm', true);
						strum.resetAnim = (note.sustainLength / 1000) + 0.15;
					}
					
					var char:OurLittleFriend = note.mustPress ? littleBF : littleDad;
					char.sing(note.noteData % 4);
					
					if (!playedSound[note.lane] && ((bfHitsound && note.mustPress) || (dadHitsound && !note.mustPress)))
					{
						var soundToPlay = 'hitsound';
						if (song.player1 == 'gf') soundToPlay = ('GF_' + Std.string(note.noteData + 1)); // Easter egg
						
						FlxG.sound.play(Paths.sound(soundToPlay)).pan = (note.noteData < (song.keys * .5) ? -0.3 : 0.3); // would be coolio
						playedSound[note.lane] = true;
					}
				}
			}
		});
		
		if (metronomeVolume > 0 && Math.floor(Conductor.getBeat(lastConductorPos)) != Math.floor(Conductor.getBeat(Conductor.songPosition))) FlxG.sound.play(Paths.sound('Metronome_Tick'),
			metronomeVolume);
			
		playbackSpeed = FlxMath.bound(playbackSpeed, .5, 3);
		
		lastConductorPos = Conductor.songPosition;
	}
	
	public function mouseInput(elapsed:Float):Void
	{
		if (!selectionBox.alive && FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				for (note in curRenderedNotes)
				{
					if (!FlxG.mouse.overlaps(note)) continue;
					
					if (FlxG.keys.pressed.CONTROL)
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
		
		if (!selectionBox.alive && FlxG.mouse.justPressedRight)
		{
			selectionBox.revive();
			selectionBox.setPosition(FlxG.mouse.x, FlxG.mouse.y);
		}
		if (selectionBox.alive)
		{
			if (!FlxG.mouse.pressedRight) deselect();
			else selectionBox.setSize(FlxG.mouse.x - selectionBox.x, FlxG.mouse.y - selectionBox.y);
		}
		
		if (FlxG.mouse.wheel != 0)
		{
			toggleMusic(false);
			
			var delta:Float = (FlxG.mouse.wheel * Conductor.stepCrotchet * .8);
			
			if (!mouseQuant) audio.time = FlxMath.bound(audio.time - delta, 0, audio.songLength - endOffset);
			else scrollQuantized(FlxG.mouse.wheel > 0);
		}
	}
	
	public function deselect():Void
	{
		if (!selectionBox.alive) return;
		
		selectionBox.kill();
		
		if (!FlxG.keys.pressed.SHIFT) curSelectedNotes.resize(0);
		
		final pad:Float = (GRID_SIZE / 4);
		final hitbox = selectionBox.getHitbox();
		final testRect = flixel.math.FlxRect.get();
		
		for (note in curRenderedNotes)
		{
			testRect.set(note.x + pad, note.y + pad, note.width - pad * 2, note.height - pad * 2);
			
			if (!hitbox.overlaps(testRect)) continue;
			
			if (!curSelectedNotes.contains(note.chartData)) curSelectedNotes.push(note.chartData);
		}
		
		testRect.put();
		hitbox.put();
		
		updateGrid();
		updateNoteUI();
	}
	
	public function keyboardInput(elapsed:Float):Void
	{
		var prevControlArray:Array<Dynamic> = vortexControlArray;
		if (vortex)
		{
			vortexControlArray = [ // TODO : make this better im crying
				FlxG.keys.pressed.ONE, FlxG.keys.pressed.TWO, FlxG.keys.pressed.THREE, FlxG.keys.pressed.FOUR,
				FlxG.keys.pressed.FIVE, FlxG.keys.pressed.SIX, FlxG.keys.pressed.SEVEN, FlxG.keys.pressed.EIGHT
			];
		}
		
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S) return saveLevel();
		
		if (FlxG.keys.justPressed.ENTER) return enterSong();
		
		if (FlxG.keys.justPressed.E) changeNoteSustain(Conductor.stepCrotchet);
		if (FlxG.keys.justPressed.Q) changeNoteSustain(-Conductor.stepCrotchet);
		
		if (FlxG.keys.justPressed.BACKSPACE)
		{
			PlayState.chartingMode = false;
			FlxG.switchState(funkin.states.editors.MasterEditorMenu.new);
			FunkinSound.playMusic(Paths.music('freakyMenu'));
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
		
		if (FlxG.keys.justPressed.ESCAPE && FlxG.keys.pressed.SHIFT) enterSong(startTime > 0 ? startTime : audio.time);
		if (FlxG.keys.justPressed.ESCAPE)
		{
			autosaveSong();
			toggleMusic(false);
			openSubState(new ChartingOptionsSubmenu());
		}
		
		if (FlxG.keys.justPressed.SPACE && audio.time < (audio.songLength - endOffset)) togglePause();
		
		if (!FlxG.keys.pressed.ALT && FlxG.keys.justPressed.R)
		{
			if (FlxG.keys.pressed.SHIFT) resetSection(true);
			else resetSection();
		}
		
		// ARROW VORTEX SHIT NO DEADASS
		
		if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
		{
			toggleMusic(false);
			
			var holdingShift:Float = 1;
			if (FlxG.keys.pressed.CONTROL) holdingShift = 0.25;
			else if (FlxG.keys.pressed.SHIFT) holdingShift = 4;
			
			var delta:Float = (700 * FlxG.elapsed * holdingShift);
			
			audio.time = FlxMath.bound(audio.time + delta * (FlxG.keys.pressed.W ? -1 : 1), 0, audio.songLength - endOffset);
		}
		
		if (FlxG.keys.justPressed.RIGHT) changeQuantization(1);
		if (FlxG.keys.justPressed.LEFT) changeQuantization(-1);
		
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
		
		if (FlxG.keys.justPressed.DELETE)
		{
			var deleteNotes:Array<Array<Dynamic>> = [];
			
			for (note in curSelectedNotes)
			{
				if (note[2] != null) deleteNotes.push(note);
				else song.events.remove(note);
			}
			
			if (deleteNotes.length > 0)
			{
				for (section in song.notes)
				{
					final secnotes = section.sectionNotes;
					for (note in deleteNotes)
						secnotes.remove(note);
				}
			}
			
			curSelectedNotes.resize(0);
			
			updateGrid();
		}
		
		if (vortex)
		{
			for (i in 0...vortexControlArray.length)
			{
				if (!vortexControlArray[i])
				{
					holdingNotes[i] = null;
				}
				else if (prevControlArray != null && vortexControlArray[i] != prevControlArray[i])
				{
					doANoteThing(quantize(audio.time), i, style);
				}
			}
			
			stretchNotes();
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
	}
	
	public function changeQuantization(mod:Int = 0):Int
	{
		curQuant = Std.int(MathUtil.euclideanMod(curQuant + mod, quantizations.length));
		
		quant.animation.play('q', true, false, curQuant);
		
		return quantization = quantizations[curQuant];
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
				
				if (vortexControlArray[i] && holdingNotes[i] == null) doANoteThing(quantize(audio.time), i, FlxG.keys.pressed.SHIFT ? 3 : currentType);
			}
		}
		
		updateCurStep();
		var beat:Float = (curDecStep / 4);
		var increase:Float = (1 / (quantization / 4));
		var nextBeat:Float = ((up ? Math.ceil : Math.floor)((beat + (increase * leniency) * (up ? -1 : 1)) / increase) * increase);
		
		var time:Float = Conductor.beatToSeconds(nextBeat);
		time = FlxMath.bound(time, 0, audio.songLength - endOffset);
		
		if (!vortex)
		{
			audio.time = time;
		}
		else
		{
			FlxTween.cancelTweensOf(audio, ['time']);
			FlxTween.tween(audio, {time: time}, .07, {ease: FlxEase.circOut});
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
			
			var newLength:Float = Math.max(quantize(audio.time) - note[0], 0);
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
	
	var metronomeVolume:Float = 1;
	
	function updateVolume():Void
	{
		metronomeVolume = (ui.songDialog.metronomeMuteCheckbox.value ? 0 : ui.songDialog.metronomeVolumeStepper.value);
		
		audio.inst.volume = (ui.songDialog.instrumentalMuteCheckbox.value ? 0 : ui.songDialog.instrumentalVolumeStepper.value);
		
		audio.opponentVolume = (ui.songDialog.opponentMuteCheckbox.value ? 0 : ui.songDialog.opponentVolumeStepper.value);
		
		audio.playerVolume = (ui.songDialog.playerMuteCheckbox.value ? 0 : ui.songDialog.playerVolumeStepper.value);
	}
	
	function reloadStrumShit()
	{
		if (strumLineNotes != null)
		{
			// rewriting noteskin shit i will add this back later
			// var noteSkin = new NoteSkinHelper(Paths.noteskin(song.arrowSkin));
			
			// NoteSkinHelper.arrowSkins = [noteSkin.data.playerSkin, noteSkin.data.opponentSkin];
			// if (song.lanes > 2) for (i in 2...song.lanes)
			// 	NoteSkinHelper.arrowSkins.push(noteSkin.data.extraSkin);
			
			// noteSkin.destroy();
			
			strumLineNotes.clear();
			
			for (i in 0...(song.keys * song.lanes))
			{
				var note:StrumNote = new StrumNote(0, 0, 0, i % song.keys);
				
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
		
		strumLine.makeGraphic(Std.int(GRID_SIZE * ((song.keys * song.lanes) + 1)), 4);
		
		// this is all kind of cringe but its okay
		final rowsPerBeat:Int = Std.int(4 * zoomList[curZoom]);
		
		final prevRows:Int = ((getSectionBeats(curSec - 1) ?? 0) * rowsPerBeat);
		final curRows:Int = ((getSectionBeats() ?? 0) * rowsPerBeat);
		final nextRows:Int = ((getSectionBeats(curSec + 1) ?? 0) * rowsPerBeat);
		
		final columns:Int = Std.int((song.keys * song.lanes) + 1);
		
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
					
					if ((!song.notes[curSec].mustHitSection && (x < (song.keys + 1) || x >= (song.keys * 2 + 1))) ||
						(song.notes[curSec].mustHitSection && (x < 1 || x >= (song.keys + 1)))) sub ??= 50;
						
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
		
		if (curSec < song.notes.length)
		{
			nextGridBG = gridLayer.add(prepareGrid(new FlxSprite(), columns, nextRows, 'charterNextGrid', 50, 128));
			nextGridBG.y += gridBG.height;
		}
		
		#if desktop
		updateWaveform();
		#end
		
		updateGrid();
		
		// events -> strum1 seperator
		gridLayer.add(gridBG);
		
		for (i in 0...lanes)
		{
			var line = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
			
			line.x = (gridBG.x + (i * song.keys + 1) * GRID_SIZE - 2);
			line.y = (prevGridBG?.y ?? gridBG.y);
			
			line.scale.set(4, (prevGridBG?.height ?? 0) + gridBG.height + (nextGridBG?.height ?? 0));
			line.updateHitbox();
			
			gridLayer.add(line);
		}
		
		lastSecBeats = getSectionBeats();
		if (sectionStartTime(1) >= audio.songLength) lastSecBeatsNext = 0;
		else getSectionBeats(curSec + 1);
		
		updateHeads();
	}
	
	inline function strumLineUpdateY()
	{
		strumLine.y = getYfromStrum(Conductor.songPosition);
	}
	
	var waveformPrinted:Bool = true;
	var wavData:Array<Array<Array<Float>>> = [[[], []], [[], []]];
	
	function updateWaveform(hard:Bool = false)
	{
		#if desktop
		final instWave:Bool = (FlxG.save.data.chart_waveformInst ?? false);
		final vocalsWave:Bool = (FlxG.save.data.chart_waveformVoices ?? false);
		final opponentVocalsWave:Bool = (FlxG.save.data.chart_waveformOpponentVoices ?? false);
		
		waveformSprite.makeGraphic(Std.int(GRID_SIZE * 8), Std.int(GRID_SIZE * 16), 0, 'wave');
		waveformSprite.setGraphicSize(Std.int(GRID_SIZE * song.keys * 2), Std.int(gridBG.height));
		waveformSprite.updateHitbox();
		
		if (!hard && !instWave && !vocalsWave && !opponentVocalsWave) return;
		
		waveformSprite.pixels.fillRect(new Rectangle(0, 0, waveformSprite.pixels.width, waveformSprite.pixels.height), 0);
		
		waveformPrinted = false;
		
		var st:Float = sectionStartTime(),
			et:Float = (st + Conductor.crotchet * getSectionBeats());
			
		inline function drawWave(sound:FlxSound, fromX:Float = 0, ?toX:Float, amp:Float = 1)
		{
			var buffer = sound?._sound?.__buffer;
			if (buffer == null) return;
			
			toX ??= waveformSprite.frameWidth;
			
			wavData[0][0].resize(0);
			wavData[0][1].resize(0);
			wavData[1][0].resize(0);
			wavData[1][1].resize(0);
			
			var bytes:Bytes = buffer.data.toBytes();
			wavData = waveformData(buffer, bytes, st, et, amp, wavData, Std.int(waveformSprite.frameHeight));
			
			final gSize:Float = (toX - fromX);
			final hSize:Float = (gSize / 2);
			
			var lmin:Float = 0, lmax:Float = 0;
			var rmin:Float = 0, rmax:Float = 0;
			
			final leftLength:Int = (wavData[0][0].length > wavData[0][1].length ? wavData[0][0].length : wavData[0][1].length);
			final rightLength:Int = (wavData[1][0].length > wavData[1][1].length ? wavData[1][0].length : wavData[1][1].length);
			final length:Int = leftLength > rightLength ? leftLength : rightLength;
			
			for (i in 0...length)
			{
				lmin = FlxMath.bound((wavData[0][0][i] ?? 0) * (gSize / 1.12), -hSize, hSize) / 2;
				lmax = FlxMath.bound((wavData[0][1][i] ?? 0) * (gSize / 1.12), -hSize, hSize) / 2;
				
				rmin = FlxMath.bound((wavData[1][0][i] ?? 0) * (gSize / 1.12), -hSize, hSize) / 2;
				rmax = FlxMath.bound((wavData[1][1][i] ?? 0) * (gSize / 1.12), -hSize, hSize) / 2;
				
				final w:Float = ((lmin + rmin + lmax + rmax) * amp);
				final x:Float = (hSize - w * .5 + fromX);
				
				waveformSprite.pixels.fillRect(new Rectangle(x, i, w, 1), FlxColor.BLUE);
			}
		}
		
		final both:Bool = (instWave && (vocalsWave || opponentVocalsWave));
		final scale:Float = waveformSprite.frameWidth;
		
		if (instWave) drawWave(audio.inst, scale * (both ? 1 / 3 : 0), scale * (both ? 2 / 3 : 1));
		if (vocalsWave) drawWave(audio.playerVocals?.getFirstAlive(), 0, scale * (both ? 1 / 3 : .5));
		if (opponentVocalsWave) drawWave(audio.opponentVocals?.getFirstAlive(), scale * (both ? 2 / 3 : .5), null);
		
		waveformPrinted = true;
		#end
	}
	
	static function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>, ?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null) return (array ?? [[[], []], [[], []]]);
		
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
		
		if (array == null) array = [[[], []], [[], []]];
		
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
		return [[[], []], [[], []]];
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
	
	function resetSection(songBeginning:Bool = false, pause:Bool = true):Void
	{
		updateGrid();
		
		toggleMusic(false);
		// Basically old shit from changeSection???
		audio.time = sectionStartTime();
		
		if (songBeginning)
		{
			audio.time = 0;
			curSec = 0;
		}
		
		updateCurStep();
		
		updateGrid();
		updateSectionUI();
		updateWaveform();
	}
	
	public function toggleMusic(play:Bool):Void
	{
		if (play && !audio.playing)
		{
			audio.play(true, audio.time);
			
			Conductor.songPosition = audio.time;
		}
		else if (!play && audio.playing)
		{
			resetLittleFriends();
			
			audio.pause();
			
			audio.time = Conductor.songPosition;
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
				newTime = audio.songLength - endOffset;
				
				curSec = getSectionIndex(newTime);
			}
			
			if (newTime <= audio.songLength - endOffset)
			{
				audio.time = newTime;
				
				if (song.notes.length <= curSec)
				{
					var old:Int = song.notes.length;
					
					while (song.notes.length <= curSec)
						addSection();
						
					trace('populated ${song.notes.length - old} sections');
				}
			}
			else
			{
				audio.time = curSec = 0;
			}
			
			Conductor.songPosition = audio.time;
			
			updateCurStep();
		}
		
		var blah1:Float = getSectionBeats();
		var blah2:Float = getSectionBeats(curSec + 1);
		if (sectionStartTime(1) > audio.songLength) blah2 = 0;
		
		if (blah1 != lastSecBeats || blah2 != lastSecBeatsNext)
		{
			reloadGridLayer();
		}
		else
		{
			updateGrid();
			updateWaveform();
		}
		updateSectionUI();
	}
	
	function updateSectionUI():Void
	{
		var sec = song.notes[curSec];
		
		ui.songDialog.sectionBeatsStepper.value = getSectionBeats();
		ui.songDialog.mustHitCheckbox.value = sec.mustHitSection;
		ui.songDialog.gfSectionCheckbox.value = sec.gfSection;
		ui.songDialog.bpmCheckbox.value = sec.changeBPM;
		ui.songDialog.bpmStepper.value = sec.bpm;
		
		updateHeads();
	}
	
	function updateHeads():Void
	{
		var mustHit:Bool = song.notes[curSec].mustHitSection;
		var isGF:Bool = song.notes[curSec].gfSection;
		
		rightIcon.visible = (song.lanes > 1);
		
		leftIcon.updateOffset = rightIcon.updateOffset = false;
		
		leftIcon.changeIcon((isGF && mustHit) ? gfIcon : bfIcon);
		rightIcon.changeIcon((isGF && !mustHit) ? gfIcon : dadIcon);
		
		leftIcon.setGraphicSize(0, 45);
		leftIcon.updateHitbox(); // absolute duct tape
		rightIcon.setGraphicSize(0, 45);
		rightIcon.updateHitbox();
		
		leftIcon.x = (GRID_SIZE * (song.keys * .5 + 1) - leftIcon.width * .5);
		rightIcon.x = (GRID_SIZE * (song.keys * 1.5 + 1) - rightIcon.width * .5);
		
		leftIcon.y = (-leftIcon.height);
		rightIcon.y = (-rightIcon.height);
		
		var focusedIcon:HealthIcon = (mustHit ? leftIcon : rightIcon);
		
		cameraIcon.scale.copyFrom(leftIcon.scale);
		cameraIcon.updateHitbox();
		cameraIcon.setPosition(focusedIcon.x - 20, focusedIcon.y - 20);
	}
	
	function updateNoteUI():Void
	{
		var notes = getSelectedNotes();
		
		var minTime:Float = Lambda.fold(curSelectedNotes, (note, r) -> Math.min(note[0], r), Math.POSITIVE_INFINITY);
		var minLength:Float = Lambda.fold(notes, (note, r) -> Math.max(note[2], r), 0);
		
		ui.songDialog.strumTimeStepper.changeSilent(minTime);
		ui.songDialog.sustainLengthStepper.changeSilent(minLength);
		
		if (notes.length == 1)
		{
			currentType = (noteTypeMap.get(notes[0][3]) ?? 0);
			
			ui.songDialog.noteTypeDropdown.selectedIndex = currentType;
		}
		
		ui.updateEventUI();
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
		
		// CURRENT SECTION
		var beats:Float = getSectionBeats();
		for (i in song.notes[curSec].sectionNotes)
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
		for (i in song.events)
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
		if (curSec < song.notes.length - 1)
		{
			for (i in song.notes[curSec + 1].sectionNotes)
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
			for (i in song.notes[curSec - 1].sectionNotes)
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
		for (i in song.events)
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
			if (daNoteInfo % song.keys != daNoteInfo % initialKeyCount)
			{
				shifted = true;
				intendedData = daNoteInfo + (song.keys - initialKeyCount);
			}
		}
		else
		{
			intendedData = daNoteInfo;
		}
		
		if (daNoteInfo != intendedData && (!isNextSection && !isPrevSection))
		{
			for (p in song.notes[curSec].sectionNotes)
			{
				if (p[0] == daStrumTime && p[1] == daNoteInfo && !p[4])
				{
					song.notes[curSec].sectionNotes[song.notes[curSec].sectionNotes.indexOf(p)][1] = intendedData;
					song.notes[curSec].sectionNotes[song.notes[curSec].sectionNotes.indexOf(p)][4] = true;
					trace('previous data: $daNoteInfo | new data: $intendedData | song.notes data: ${song.notes[curSec].sectionNotes[song.notes[curSec].sectionNotes.indexOf(p)][1]} | youre not gonna shift again..? ${song.notes[curSec].sectionNotes[song.notes[curSec].sectionNotes.indexOf(p)][4]}');
				}
			}
		}
		
		var note:EditorNote = new EditorNote(daStrumTime, intendedData % song.keys, null, null, true);
		note.lane = Std.int(Math.max(Math.floor(intendedData / song.keys), 0));
		note.noteData = intendedData % song.keys;
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
				if (i.length > (song.keys - 1) && (i[song.keys - 1] == null || i[song.keys - 1].length < 1))
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
				bpm: song.bpm,
				changeBPM: false,
				mustHitSection: true,
				gfSection: false,
				sectionNotes: [],
				altAnim: false
			};
			
		song.notes.push(sec);
	}
	
	function selectNote(note:EditorNote):Void
	{
		if (!FlxG.keys.pressed.SHIFT) curSelectedNotes.resize(0);
		if (!curSelectedNotes.contains(note.chartData)) curSelectedNotes.push(note.chartData);
		
		if (note.noteData >= 0)
		{
			var noteDataToCheck:Int = (note.noteData + note.lane * song.keys);
		}
		else if (curSelectedNotes.length == 1)
		{
			curEventSelected = Std.int(curSelectedNotes[0][1].length) - 1;
		}
		changeEventSelected();
		
		updateGrid();
		updateNoteUI();
	}
	
	function deleteNote(note:EditorNote, update:Bool = true):Void
	{
		var noteDataToCheck:Int = note.noteData;
		
		if (note.noteData > -1) // Normal Notes
		{
			noteDataToCheck = (note.noteData + note.lane * song.keys);
			
			// FlxG.log.add('FOUND EVIL NOTE');
			song.notes[curSec].sectionNotes.remove(note.chartData);
		}
		else // Events
		{
			song.events.remove(note.chartData);
		}
		
		if (update)
		{
			curSelectedNotes.remove(note.chartData);
			
			updateGrid();
		}
	}
	
	public function doANoteThing(cs:Float, d:Int, style:Int)
	{
		for (note in curRenderedNotes)
		{
			if (Math.abs(cs - quantize(note.strumTime)) < 3 && d == (note.noteData + note.lane * song.keys)) return deleteNote(note);
		}
		
		holdingNotes[d] = addNote(cs, d, style);
	}
	
	function clearSong():Void
	{
		for (daSection in 0...song.notes.length)
		{
			song.notes[daSection].sectionNotes = [];
		}
		
		updateGrid();
	}
	
	private function addNote(strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null):Array<Dynamic>
	{
		// curUndoIndex++;
		// var newsong = song.notes;
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
			song.notes[curSec].sectionNotes.push(newNote);
			
			if (FlxG.keys.pressed.CONTROL) choirNotes([newNote]);
		}
		else
		{
			var event = eventStuff[ui.songDialog.eventDropdown.selectedIndex][0];
			var text1 = ui.songDialog.value1Field.value;
			var text2 = ui.songDialog.value2Field.value;
			
			newNote = [noteStrum, [[event, text1, text2]]];
			song.events.push(newNote);
			
			if (!FlxG.keys.pressed.SHIFT || curSelectedNotes.length == 0) curEventSelected = 0;
		}
		
		curSelectedNotes.push(newNote);
		
		changeEventSelected();
		
		updateGrid();
		updateNoteUI();
		
		return newNote;
	}
	
	function choirNotes(notesArray:Array<Dynamic>):Void
	{
		final notes:Array<Dynamic> = song.notes[curSec].sectionNotes;
		final duetNotes:Array<Array<Dynamic>> = [];
		
		if (notesArray.length == 0) notesArray = notes;
		
		for (note in notesArray)
		{
			if (note[1] < 0) continue;
			
			for (i in 0...song.lanes)
			{
				var newData:Int = Std.int((note[1] % song.keys) + i * song.keys);
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
	
	function mirrorNotes(notesArray:Array<Dynamic>, axes:flixel.util.FlxAxes = X):Void
	{
		if (notesArray.length > 0)
		{
			if (axes.x)
			{
				var minData:Int = Lambda.fold(notesArray, (note:Array<Dynamic>, r:Int) -> (note[1] > -1 ? FlxMath.minInt(note[1], r) : r), 9999);
				var maxData:Int = Lambda.fold(notesArray, (note:Array<Dynamic>, r:Int) -> FlxMath.maxInt(note[1], r), 0);
				
				for (note in notesArray)
				{
					if (note[1] < 0) continue;
					
					note[1] = (maxData - note[1] + minData);
				}
			}
			
			if (axes.y)
			{
				var minTime:Float = Lambda.fold(notesArray, (note:Array<Dynamic>, r:Float) -> Math.min(note[0], r), Math.POSITIVE_INFINITY);
				var maxTime:Float = Lambda.fold(notesArray, (note:Array<Dynamic>, r:Float) -> Math.max(note[0], r), Math.NEGATIVE_INFINITY);
				
				for (note in notesArray)
				{
					if (note[1] < 0) continue;
					
					note[0] = (maxTime - note[0] + minTime);
				}
			}
		}
		else
		{
			final minTime:Float = sectionStartTime();
			final maxTime:Float = (startTime + getSectionBeats() * Conductor.crotchet);
			
			for (note in song.notes[curSec].sectionNotes)
			{
				if (note[1] < 0) continue;
				
				if (axes.x) note[1] = ((song.keys - (note[1] % song.keys) - 1) + Std.int(note[1] / song.keys) * song.keys);
				
				if (axes.y) note[0] = (maxTime - note[0] + minTime);
			}
		}
	}
	
	function transformNoteStrumlines(notesArray:Array<Dynamic>, fun:(noteStrumline:Int, minStrumline:Int, maxStrumline:Int) -> Int):Void
	{
		var minStrumline:Int, maxStrumline:Int;
		
		if (notesArray.length == 0)
		{
			minStrumline = 0;
			maxStrumline = (song.lanes - 1);
			notesArray = song.notes[curSec].sectionNotes;
		}
		else
		{
			minStrumline = Lambda.fold(notesArray, (note:Array<Dynamic>, r:Int) -> (note[1] > -1 ? FlxMath.minInt(getStrumline(note[1]), r) : r), 9999);
			maxStrumline = Lambda.fold(notesArray, (note:Array<Dynamic>, r:Int) -> FlxMath.maxInt(getStrumline(note[1]), r), 0);
		}
		
		for (note in notesArray)
		{
			if (note[1] < 0) continue;
			
			var newStrumline:Int = fun(getStrumline(note[1]), minStrumline, maxStrumline);
			note[1] = ((note[1] % song.keys) + newStrumline * song.keys);
		}
	}
	
	function shiftStrumlineTransform(noteStrumline:Int, minStrumline:Int, maxStrumline:Int):Int
	{
		return ((noteStrumline + 1) % (maxStrumline - minStrumline + 1) + minStrumline);
	}
	
	function swapStrumlineTransform(noteStrumline:Int, minStrumline:Int, maxStrumline:Int):Int
	{
		return (maxStrumline - noteStrumline + minStrumline);
	}
	
	inline function getStrumline(index:Int):Int return Std.int(index / song.keys);
	
	// will figure this out l8r
	// lol you didnt so i had to
	function redo()
	{
		// song = redos[curRedoIndex];
	}
	
	function undo()
	{
		// redos.push(song);
		undos.pop();
		// song.notes = undos[undos.length - 1];
		///trace(song.notes);
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
		
		return (gridBG.y + (Conductor.getStep(strumTime) - Conductor.getStep(sectionStartTime())) * leZoom * GRID_SIZE);
	}
	
	function getYfromStrumNotes(strumTime:Float, beats:Float):Float
	{
		var value:Float = strumTime / (beats * 4 * Conductor.stepCrotchet);
		return (GRID_SIZE * beats * 4 * zoomList[curZoom] * value + gridBG.y);
	}
	
	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];
		
		for (i in song.notes)
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
			PlayState.SONG = Chart.fromPath(Paths.json('$songName/charts/${Difficulty.getDifficultyFilePath()}'));
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
				"song": song
			});
		FlxG.save.flush();
	}
	
	function clearEvents()
	{
		song.events = [];
		updateGrid();
	}
	
	private function saveLevel()
	{
		if (song.events != null && song.events.length > 1) song.events.sort(sortByTime);
		var json =
			{
				"song": song
			};
			
		var data:String = Json.stringify(json, "\t");
		
		if ((data != null) && (data.length > 0))
		{
			FileUtil.saveFile(data.trim(), Paths.sanitize(song.song) + '.json', onSaveComplete, onSaveCancel);
		}
	}
	
	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}
	
	private function saveEvents()
	{
		if (song.events != null && song.events.length > 1) song.events.sort(sortByTime);
		var eventsSong:Dynamic =
			{
				events: song.events
			};
		var json =
			{
				"song": eventsSong
			}
			
		var data:String = Json.stringify(json, "\t");
		
		if ((data != null) && (data.length > 0))
		{
			FileUtil.saveFile(data.trim(), "events.json", onSaveComplete, onSaveCancel);
		}
	}
	
	function onSaveComplete(path:String):Void
	{
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}
	
	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel():Void {}
	
	function getSectionBeats(?section:Int):Null<Int>
	{
		return (song.notes[section ?? curSec]?.sectionBeats ?? 4);
	}
	
	public static function enterSong(?time:Float)
	{
		autosaveSong();
		
		if (time != null) PlayState.startOnTime = time;
		PlayState.SONG = song;
		
		instance?.audio.stop();
		
		FlxG.switchState(PlayState.new);
	}
	
	public inline function togglePause()
	{
		toggleMusic(!audio.playing);
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
	
	override function draw():Void
	{
		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
		
		super.draw();
	}
}

class ChartingOptionsSubmenu extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var menuItems:Array<String> = [
		'Resume',
		'Play from beginning',
		'Play from here',
		'Set start time',
		'Play from start time',
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
		super.update(elapsed);
		
		if (FlxG.keys.justPressed.ESCAPE && canexit) close();
		
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
					ChartEditorState.enterSong();
				case 'Play from here':
					ChartEditorState.enterSong(ChartEditorState.instance.audio.time);
				case 'Play from start time':
					ChartEditorState.enterSong(ChartEditorState.startTime);
				case 'Set start time':
					ChartEditorState.startTime = ChartEditorState.instance.audio.time;
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
			
			if (item.targetY == 0) item.alpha = 1;
		}
	}
}
