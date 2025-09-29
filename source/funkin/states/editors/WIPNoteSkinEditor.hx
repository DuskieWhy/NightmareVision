package funkin.states.editors;

import haxe.ui.components.Stepper;
import haxe.Json;
import haxe.ui.components.popups.ColorPickerPopup;
import haxe.ui.core.Screen;
import haxe.ui.components.CheckBox;
import haxe.ui.components.Button;
import haxe.ui.components.Slider;
import haxe.ui.backend.flixel.UIState;

import openfl.events.Event;
import openfl.events.KeyboardEvent;

import extensions.openfl.FileReferenceEx;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxBackdrop;

import funkin.states.editors.ui.NoteskinEditorKit.NoteEditorUI;
import funkin.data.*;
import funkin.objects.*;
import funkin.objects.note.*;

using funkin.states.editors.ui.ToolKitUtils;

class WIPNoteSkinEditor extends UIState
{
	var isCameraDragging:Bool = false;
	var camHUD:FlxCamera;
	var camBG:FlxCamera;
	
	var bg:FlxSprite;
	var scrollingBG:FlxBackdrop;
	
	public var keysArray:Array<Dynamic>;
	
	// used for refreshing the skin
	var curName:String = 'default';
	var helper:NoteSkinHelper;
	
	var playfields:FlxTypedGroup<PlayField>;
	
	var uiElements:NoteEditorUI;
	
	public function new(file:String = 'default', ?t_helper:NoteSkinHelper = null)
	{
		super();
		
		if (t_helper == null) setupHandler(file);
		else helper = t_helper;
	}
	
	override function create()
	{
		super.create();
		
		FlxG.cameras.reset();
		FlxG.cameras.add(camHUD = new FlxCamera(), false);
		FlxG.cameras.insert(camBG = new FlxCamera(), 0, false);
		FlxG.camera.bgColor = 0x0;
		camHUD.bgColor = 0x0;
		
		bg = new FlxSprite().loadGraphic(Paths.image('editors/notesbg'));
		bg.setGraphicSize(1280);
		bg.updateHitbox();
		bg.screenCenter();
		bg.alpha = 0.75;
		bg.scrollFactor.set();
		bg.camera = camBG;
		add(bg);
		
		scrollingBG = new FlxBackdrop(Paths.image('editors/arrowloop'));
		scrollingBG.setGraphicSize(1280 * 2);
		scrollingBG.updateHitbox();
		scrollingBG.screenCenter();
		scrollingBG.scrollFactor.set();
		scrollingBG.camera = camBG;
		scrollingBG.alpha = 0.8;
		add(scrollingBG);
		
		playfields = new FlxTypedGroup<PlayField>();
		playfields.camera = FlxG.camera;
		add(playfields);
		
		buildUI();
		buildNotes();
		setUpControls();
		
		FlxG.mouse.visible = true;
		
		FunkinSound.playMusic(Paths.music('offsetSong'), 1, true);
	}
	
	function setUpControls()
	{
		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];
		
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		// FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
	}
	
	function helperLoading(file:String)
	{
		var noteskin:Null<NoteSkinHelper> = null;
		
		if (FunkinAssets.exists(Paths.noteskin(file)))
		{
			noteskin = new NoteSkinHelper(Paths.noteskin(file));
			curName = file;
		}
		if (noteskin == null)
		{
			noteskin = new NoteSkinHelper(Paths.noteskin('default'));
			curName = 'default';
		}
		
		return noteskin;
	}
	
	function setupHandler(n:String = 'default')
	{
		helper = helperLoading(n);
		
		NoteSkinHelper.instance = helper;
		NoteSkinHelper.keys = helper.data.noteAnimations.length;
		NoteSkinHelper.arrowSkins = [helper.data.playerSkin, helper.data.opponentSkin];
	}
	
	function buildUI()
	{
		root.cameras = [camHUD]; // this tells every single component to use this camera
		
		uiElements = new NoteEditorUI();
		uiElements.camera = camHUD;
		add(uiElements);
		
		refreshUIValues();
		
		refreshSkinDropdown();
		uiElements.toolBar.skinDropdown.onChange = (ui) -> {
			if (ui.data.isDropDownItem())
			{
				setupHandler(ui.data.id);
				uiElements.toolBar.skinName.value = ui.data.id;
				
				refreshUIValues();
				buildNotes(true);
				
				FlxG.sound.play(Paths.sound('ui/success'));
				ToolKitUtils.makeNotification('Skin Change', 'Successfullyu changed skin to ${ui.data.id}', Success);
			}
		}
		
		uiElements.toolBar.saveButton.onClick = (ui) -> {
			saveSkinToFile();
		}
		
		uiElements.toolBar.refreshButton.onClick = (ui) -> {
			setupHandler(curName);
			buildNotes(false);
			refreshUIValues();
			
			FlxG.sound.play(Paths.sound('ui/openPopup'));
			ToolKitUtils.makeNotification('Refreshed Skin', 'Refreshed current noteskin. Any changes may have been lost.', Info);
		}
		
		uiElements.toolBar.bgView.findComponent('bgColour', ColorPickerPopup).onChange = (ui) -> {
			final newColour = FlxColor.fromString(ui.value.toString());
			if (camBG.bgColor != newColour)
			{
				uiElements.toolBar.findComponent('coolBGCheckbox', CheckBox).value = false;
				uiElements.toolBar.gridBGCheckbox.value = false;
			}
			camBG.bgColor = newColour;
		}
		
		uiElements.toolBar.coolBGCheckbox.onChange = (ui) -> {
			bg.visible = ui.value.toBool();
			scrollingBG.visible = ui.value.toBool();
			if (bg.visible) camBG.bgColor = FlxColor.BLACK;
		}
		
		uiElements.settingsBox.reloadTextures.onClick = (ui) -> {
			helper.data.playerSkin = uiElements.settingsBox.playerTexture.value;
			helper.data.opponentSkin = uiElements.settingsBox.opponentTexture.value;
			helper.data.extraSkin = uiElements.settingsBox.extraTexture.value;
			
			NoteSkinHelper.arrowSkins = [helper.data.playerSkin, helper.data.opponentSkin];
			buildNotes(true);
			
			FlxG.sound.play(Paths.sound('ui/success'));
			ToolKitUtils.makeNotification('Reloaded Textures', 'Reloaded textures successfully', Success);
		}
		
		uiElements.settingsBox.scalecount.onChange = (ui) -> {
			final newScale = ui.value.toFloat();
			
			for (i in playfields.members)
			{
				for (j in i.members)
				{
					j.scale.set(newScale, newScale);
					j.updateHitbox();
				}
			}
			helper.data.scale = newScale;
		}
		
		uiElements.settingsBox.lanecount.onChange = (ui) -> {
			// SIGH
			buildNotes(true);
		}
		
		uiElements.settingsBox.keycount.onChange = (ui) -> {
			final newKeyCount = ui.value.toInt();
			
			if (newKeyCount > helper.data.noteAnimations.length && newKeyCount > helper.data.receptorAnimations.length)
			{
				if (newKeyCount >= 10)
				{
					ToolKitUtils.makeNotification('Key Warning', 'Above 10 keys is not recommended due to performance.', Warning);
					FlxG.sound.play(Paths.sound('ui/warn'));
				}
				else
				{
					ToolKitUtils.makeNotification('Key Addition', 'Key $newKeyCount was created (based on values from Key 1)', Success);
					FlxG.sound.play(Paths.sound('ui/success'));
				}
				
				helper.data.noteAnimations.push(helper.data.noteAnimations[0]);
				helper.data.receptorAnimations.push(helper.data.receptorAnimations[0]);
			}
			
			if (newKeyCount < helper.data.noteAnimations.length && newKeyCount < helper.data.receptorAnimations.length)
			{
				if (newKeyCount <= 1)
				{
					ToolKitUtils.makeNotification('Key Error', 'You can\'t have zero keys..', Warning);
					FlxG.sound.play(Paths.sound('ui/warn'));
				}
				else
				{
					ToolKitUtils.makeNotification('Key Removal', 'Key ${newKeyCount + 1} was removed', Success);
					FlxG.sound.play(Paths.sound('ui/success'));
				}
				
				helper.data.noteAnimations.pop();
				helper.data.receptorAnimations.pop();
			}
			
			buildNotes(true);
		}
		
		uiElements.settingsBox.shaderColoringBox.onChange = (ui) -> {
			helper.data.inGameColoring = ui.value.toBool();
			buildNotes(true);
		}
		
		uiElements.settingsBox.splashBox.onChange = (ui) -> {
			// do more shit here abt not going to splashes mode if theyre disabled. or smth. idk
			
			helper.data.splashesEnabled = ui.value.toBool();
		}
		
		uiElements.settingsBox.antialiasingBox.onChange = (ui) -> {
			helper.data.antialiasing = ui.value.toBool();
			for (i in playfields.members)
			{
				for (j in i.members)
					j.antialiasing = helper.data.antialiasing;
			}
		}
		
		uiElements.settingsBox.pixSus.onChange = (ui) -> {
			helper.data.sustainSuffix = ui.value;
		}
		
		uiElements.settingsBox.widthDiv.onChange = (ui) -> {
			helper.data.pixelSize[0] = ui.value.toInt();
		}
		uiElements.settingsBox.heightDiv.onChange = (ui) -> {
			helper.data.pixelSize[1] = ui.value.toInt();
		}
	}
	
	function refreshUIValues()
	{
		uiElements.settingsBox.splashTexture.value = helper.data.noteSplashSkin;
		uiElements.settingsBox.playerTexture.value = helper.data.playerSkin;
		uiElements.settingsBox.opponentTexture.value = helper.data.opponentSkin;
		uiElements.settingsBox.extraTexture.value = helper.data.extraSkin;
		
		uiElements.settingsBox.scalecount.value = helper.data.scale;
		uiElements.settingsBox.keycount.value = helper.data.noteAnimations.length;
		uiElements.settingsBox.lanecount.value = 1;
		
		uiElements.settingsBox.splashBox.value = helper.data.splashesEnabled;
		uiElements.settingsBox.shaderColoringBox.value = helper.data.inGameColoring;
		uiElements.settingsBox.antialiasingBox.value = helper.data.antialiasing;
		
		uiElements.settingsBox.pixSus.value = helper.data.sustainSuffix;
		uiElements.settingsBox.isPixel.value = helper.data.isPixel;
		uiElements.settingsBox.widthDiv.value = helper.data.pixelSize[0];
		uiElements.settingsBox.heightDiv.value = helper.data.pixelSize[1];
		
		uiElements.toolBar.coolBGCheckbox.value = true;
	}
	
	function buildNotes(?skipTween:Bool = false)
	{
		if (playfields.members.length > 0) playfields.clear();
		
		for (i in 0...Std.int(uiElements.settingsBox.lanecount.value))
		{
			var field = new PlayField(112 * 3, 112 * 2, uiElements.settingsBox.keycount.value, null, true, false, true, i);
			field.generateReceptors();
			field.fadeIn(skipTween);
			playfields.add(field);
			
			// annoying but whatever
			for (i in field.members)
			{
				i.scrollFactor.set(1, 1);
				i.antialiasing = helper.data.antialiasing;
			}
		}
	}
	
	function refreshSkinDropdown()
	{
		var skinList = [];
		#if MODS_ALLOWED
		for (file in Paths.listAllFilesInDirectory('noteskins/'))
		{
			if (file.endsWith('.json'))
			{
				var skinToCheck:String = file.withoutDirectory().withoutExtension();
				
				if (!skinList.contains(skinToCheck)) skinList.push(skinToCheck);
			}
		}
		#end
		
		uiElements.toolBar.skinDropdown.populateList([for (i in skinList) ToolKitUtils.makeSimpleDropDownItem(i)]);
		uiElements.toolBar.skinDropdown.dataSource.sort(null, ASCENDING);
	}
	
	override function update(elapsed)
	{
		super.update(elapsed);
		
		if (scrollingBG != null) scrollingBG.x += 0.25 * (elapsed * 240);
		
		controlCamera(elapsed);
		
		if ((ToolKitUtils.isHaxeUIHovered(camHUD) && FlxG.mouse.justPressed) || FlxG.mouse.justPressedRight)
		{
			FlxG.sound.play(Paths.sound('ui/mouseClick'));
		}
	}
	
	function controlCamera(elapsed:Float)
	{
		if (FlxG.keys.justPressed.R)
		{
			FlxG.camera.zoom = 1;
			FlxG.camera.scroll.x = 0;
			FlxG.camera.scroll.y = 0;
		}
		
		if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3)
		{
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
		}
		if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1)
		{
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
		}
		
		if (FlxG.mouse.justReleasedMiddle) isCameraDragging = false;
		
		if (ToolKitUtils.isHaxeUIHovered(camHUD) && !isCameraDragging) return;
		
		if (FlxG.mouse.justPressedMiddle)
		{
			isCameraDragging = true;
			FlxG.sound.play(Paths.sound('ui/mouseMiddleClick'));
		}
		
		if (FlxG.mouse.pressedMiddle && FlxG.mouse.justMoved)
		{
			var mult = FlxG.keys.pressed.SHIFT ? 2 : 1;
			FlxG.camera.scroll.x -= FlxG.mouse.deltaViewX * mult;
			FlxG.camera.scroll.y -= FlxG.mouse.deltaViewY * mult;
		}
		
		if (FlxG.mouse.wheel != 0)
		{
			FlxG.camera.zoom += FlxG.mouse.wheel * (0.1 * FlxG.camera.zoom);
		}
		
		FlxG.camera.zoom = FlxMath.bound(FlxG.camera.zoom, 0.1, 6);
	}
	
	var _fileReference:Null<FileReferenceEx> = null;
	
	function saveSkinToFile()
	{
		if (_fileReference != null) return;
		
		var json =
			{
				"globalSkin": helper.data.globalSkin,
				"playerSkin": helper.data.playerSkin,
				"opponentSkin": helper.data.opponentSkin,
				"extraSkin": helper.data.extraSkin,
				"noteSplashSkin": helper.data.noteSplashSkin,
				
				"isPixel": uiElements.settingsBox.isPixel.value,
				"pixelSize": helper.data.pixelSize,
				"antialiasing": uiElements.settingsBox.antialiasingBox.value,
				"sustainSuffix": helper.data.sustainSuffix,
				
				"noteAnimations": helper.data.noteAnimations,
				
				"receptorAnimations": helper.data.receptorAnimations,
				
				"noteSplashAnimations": helper.data.noteSplashAnimations,
				
				"singAnimations": helper.data.singAnimations,
				"scale": helper.data.scale,
				"splashesEnabled": helper.data.splashesEnabled,
				"inGameColoring": helper.data.inGameColoring
			}
			
		final dataToSave:String = Json.stringify(json, "\t");
		
		if (dataToSave.length > 0)
		{
			_fileReference = new FileReferenceEx(); // maybe do smth about this idk
			
			_fileReference.addEventListener(Event.SELECT, onFileSaveComplete);
			_fileReference.addEventListener(Event.CANCEL, onFileSaveCancel);
			_fileReference.save(dataToSave, '${uiElements.toolBar.skinName.value}.json');
		}
	}
	
	function cleanUpFileReference()
	{
		if (_fileReference == null) return;
		
		_fileReference.removeEventListener(Event.SELECT, onFileSaveComplete);
		_fileReference.removeEventListener(Event.CANCEL, onFileSaveCancel);
		
		_fileReference = null;
	}
	
	function onFileSaveComplete(_)
	{
		if (_fileReference == null) return;
		
		cleanUpFileReference();
		
		ToolKitUtils.makeNotification('Skin File Saving', 'Skin was successfully saved.', Success);
		FlxG.sound.play(Paths.sound('ui/success'));
	}
	
	function onFileSaveCancel(_)
	{
		if (_fileReference == null) return;
		
		cleanUpFileReference();
		
		ToolKitUtils.makeNotification('Skin File Saving', 'Skin saving was canceled.', Warning);
		FlxG.sound.play(Paths.sound('ui/warn'));
	}
	
	function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		// if (cpuControlled || paused || !startedCountdown) return;
		
		if (key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			for (field in playfields.members)
			{
				if (field.inControl && !field.autoPlayed && field.playerControls)
				{
					var spr:StrumNote = field.members[key];
					shuffleThroughAnims(spr);
				}
			}
		}
	}
	
	function shuffleThroughAnims(key:StrumNote)
	{
		if (key != null)
		{
			switch (key.animation.curAnim.name)
			{
				case 'static':
					key.playAnim('pressed');
				case 'pressed':
					key.playAnim('confirm');
				case 'confirm':
					key.playAnim('static');
			}
			key.resetAnim = 0;
		}
	}
	
	// function onKeyRelease(event:KeyboardEvent):Void
	// {
	// 	var eventKey:FlxKey = event.keyCode;
	// 	var key:Int = getKeyFromEvent(eventKey);
	// 	if (key > -1)
	// 	{
	// 		for (field in playfields.members)
	// 		{
	// 			if (field.inControl && !field.autoPlayed && field.playerControls)
	// 			{
	// 				var spr:StrumNote = field.members[key];
	// 				if (spr != null)
	// 				{
	// 					spr.playAnim('static');
	// 					spr.resetAnim = 0;
	// 				}
	// 			}
	// 		}
	// 	}
	// }
	
	function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
					if (key == keysArray[i][j]) return i;
			}
		}
		return -1;
	}
}
