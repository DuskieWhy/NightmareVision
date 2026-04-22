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

import flixel.group.FlxContainer;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxBackdrop;

import funkin.states.editors.ui.NoteskinEditorKit.NoteEditorUI;
import funkin.states.editors.ui.DebugBounds;
import funkin.data.*;
import funkin.objects.*;
import funkin.objects.note.*;
//
import funkin.utils.NoteUtil;
import funkin.data.NoteSkin.Animation;
import funkin.data.NoteSkin.ColorList;

using funkin.states.editors.ui.ToolKitUtils;

enum abstract Mode(Int)
{
	var RECEPTORS;
	var SPLASHES;
	var NOTES;
}

class WIPNoteSkinEditor extends UIState
{
	var isCameraDragging:Bool = false;
	var camHUD:FlxCamera;
	var camBG:FlxCamera;
	
	var mode:Mode;
	var bg:FlxSprite;
	var scrollingBG:FlxBackdrop;
	
	var field:PlayField;
	// var ghostfields:FlxTypedGroup<PlayField>;
	// var playfields:FlxTypedGroup<PlayField>;
	var fieldLayering:FlxContainer;
	var fieldBounds:Array<DebugBounds> = [];
	
	var uiElements:NoteEditorUI;
	
	var curName:String = 'default';
	
	var skin:NoteSkin;
	
	var keysArray:Array<Dynamic>;
	var keys:Int = 4;
	var receptorAnimArray = [];
	
	var curColorString:String = "Red";
	var curSelectedNote:Dynamic;
	
	function setMode(_mode:Mode)
	{
		mode = _mode;
		// ui switching stuff will go here i promise
	}
	
	public function new(file:String = 'default', ?_skin:NoteSkin = null)
	{
		super();
		if (_skin == null) loadingSkin(file);
		else skin = _skin;
	}
	
	override function create()
	{
		super.create();
		FlxG.cameras.reset();
		FlxG.cameras.add(camHUD = new FlxCamera(), false);
		FlxG.cameras.insert(camBG = new FlxCamera(), 0, false);
		FlxG.camera.bgColor = 0x0;
		camHUD.bgColor = 0x0;
		setMode(RECEPTORS);
		
		bg = new FlxSprite().loadGraphic(Paths.image('editors/notesbg'));
		bg.setGraphicSize(1280);
		bg.updateHitbox();
		bg.screenCenter();
		bg.alpha = 0.7;
		bg.scrollFactor.set();
		bg.camera = camBG;
		add(bg);
		
		scrollingBG = new FlxBackdrop(Paths.image('editors/arrowloop'));
		scrollingBG.setGraphicSize(1280 * 2);
		scrollingBG.updateHitbox();
		scrollingBG.screenCenter();
		scrollingBG.scrollFactor.set();
		scrollingBG.camera = camBG;
		scrollingBG.alpha = 0.75;
		add(scrollingBG);
		
		fieldLayering = new FlxContainer();
		fieldLayering.camera = FlxG.camera;
		add(fieldLayering);
		
		// ghostfields = new FlxTypedGroup<PlayField>();
		
		// fieldLayering.add(ghostfields);
		
		// playfields = new FlxTypedGroup<PlayField>();
		// field = new PlayField();
		// fieldLayering.add(field);
		
		buildUI();
		buildNotes();
		setUpControls();
		
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
		var noteskin:Null<NoteSkin> = null;
		noteskin = new NoteSkin(file);
		
		return noteskin;
	}
	
	function loadingSkin(n:String = 'default')
	{
		skin = helperLoading(n);
		
		keys = skin.keys;
		curName = skin.name;
	}
	
	var resettingColor = false;
	
	function buildUI()
	{
		root.cameras = [camHUD]; // this tells every single component to use this camera
		uiElements = new NoteEditorUI();
		uiElements.camera = camHUD;
		add(uiElements);
		refreshUIValues();
		
		uiElements.toolBar.showBounds.value = false;
		
		refreshSkinDropdown();
		uiElements.toolBar.skinDropdown.onChange = (ui) -> {
			if (ui.data.isDropDownItem())
			{
				loadingSkin(ui.data.id);
				trace(skin.noteTexture);
				
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
			loadingSkin(curName);
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
		
		uiElements.toolBar.showBounds.onChange = (ui) -> {
			final show = ui.value.toBool();
			if (fieldBounds.length > 0 && fieldBounds != null)
			{
				for (i in fieldBounds)
				{
					if (i != null) i.visible = show;
				}
			}
		}
		
		// uiElements.toolBar.enableGhost.onClick = (ui) -> {
		// 	spawnGhostField();
		// }
		
		// uiElements.toolBar.ghostInFront.onChange = (ui) -> {
		// 	// ghostfields.zIndex = ui.value.toBool() ? 999 : -1;
		// 	fieldLayering.sort(SortUtil.sortByZ, flixel.util.FlxSort.ASCENDING);
		// }
		
		// var slider = uiElements.toolBar.ghostSettings.findComponent('ghostAlphaSlider', Slider);
		// if (slider != null)
		// {
		// 	slider.onChange = (ui) -> {
		// 		for (i in ghostfields.members)
		// 		{
		// 			final a = ui.value.toFloat();
		// 			for (j in i.members)
		// 				j.targetAlpha = a;
		// 		}
		// 	}
		// }
		
		uiElements.settingsBox.animationsDropdown.onChange = (ui) -> {
			refreshAnimFields(uiElements.settingsBox.animationsDropdown.selectedIndex);
			// trace(ui.value);
		}
		
		uiElements.settingsBox.addAnimationButton.onClick = (ui) -> {
			addAnim();
		}
		
		uiElements.settingsBox.reloadTextures.onClick = (ui) -> {
			skin.noteTexture = skin.data.noteTexture = uiElements.settingsBox.noteTexture.value;
			// helper.data.playerSkin = uiElements.settingsBox.playerTexture.value;
			// helper.data.opponentSkin = uiElements.settingsBox.opponentTexture.value;
			// helper.data.extraSkin = uiElements.settingsBox.extraTexture.value;
			// NoteSkinHelper.arrowSkins = [helper.data.playerSkin, helper.data.opponentSkin];
			buildNotes(true);
			FlxG.sound.play(Paths.sound('ui/success'));
			ToolKitUtils.makeNotification('Reloaded Textures', 'Reloaded textures successfully', Success);
		}
		uiElements.settingsBox.scalecount.onChange = (ui) ->
			{
				// dont do shit for now
				
				// final newScale = ui.value.toFloat();
				// for (i in playfields.members)
				// {
				// 	for (j in i.members)
				// 	{
				// 		j.scale.set(newScale, newScale);
				// 		j.updateHitbox();
				// 	}
				// }
				// skin.receptorScale.scale = newScale;
			}
			
		uiElements.settingsBox.keycount.onChange = (ui) -> {
			final newKeyCount = ui.value.toInt();
			if (newKeyCount > skin.data.noteAnimations.length && newKeyCount > skin.data.receptorAnimations.length)
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
				skin.data.noteAnimations.push(skin.data.noteAnimations[0]);
				skin.data.receptorAnimations.push(skin.data.receptorAnimations[0]);
			}
			if (newKeyCount < skin.data.noteAnimations.length && newKeyCount < skin.data.receptorAnimations.length)
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
				skin.data.noteAnimations.pop();
				skin.data.receptorAnimations.pop();
			}
			keys = newKeyCount;
			skin.noteAnims = skin.data.noteAnimations;
			skin.receptorAnims = skin.data.receptorAnimations;
			
			buildNotes(true);
		}
		uiElements.settingsBox.shaderColoringBox.onClick = (ui) -> {
			skin.inEngineColoring = skin.data.inGameColoring = ui.value.toBool();
			buildNotes(true);
			trace(ui.value.toBool());
		}
		uiElements.settingsBox.splashBox.onChange = (ui) -> {
			// do more shit here abt not going to splashes mode if theyre disabled. or smth. idk
			skin.data.splashesEnabled = ui.value.toBool();
		}
		uiElements.settingsBox.antialiasingBox.onChange = (ui) -> {
			skin.data.antialiasing = ui.value.toBool();
			for (i in field.members)
				i.antialiasing = skin.data.antialiasing;
				
			skin.antialiasing = skin.data.antialiasing;
		}
		uiElements.settingsBox.noteColorPicker.onChange = (ui) -> {
			final colour = FlxColor.fromString(ui.value.toString());
			var id = curSelectedNote.noteData;
			switch (curColorString)
			{
				case 'Red':
					skin.data.arrowRGB[id].r = colour;
				case 'Green':
					skin.data.arrowRGB[id].g = colour;
				case 'Blue':
					skin.data.arrowRGB[id].b = colour;
			}
			skin.colors[id] = skin.data.arrowRGB[id];
			
			updateStrumColors();
		}
		uiElements.settingsBox.resetDefColors.onClick = (ui) -> {
			resetColorValues('Default');
		};
		uiElements.settingsBox.resetJsonColors.onClick = (ui) -> {
			resetColorValues('File');
		};
	}
	
	function refreshUIValues()
	{
		uiElements.settingsBox.noteTexture.value = skin.data.noteTexture;
		uiElements.settingsBox.splashTexture.value = skin.data.splashTexture;
		//
		uiElements.settingsBox.opponentTexture.value = 'unused';
		uiElements.settingsBox.extraTexture.value = 'unused';
		//
		uiElements.settingsBox.scalecount.value = skin.data.receptorScale;
		uiElements.settingsBox.keycount.value = skin.data.noteAnimations.length;
		uiElements.settingsBox.splashBox.value = skin.data.splashesEnabled;
		uiElements.settingsBox.antialiasingBox.value = skin.data.antialiasing;
		// uiElements.settingsBox.pixSus.value = skin.data.sustainSuffix;
		// uiElements.settingsBox.isPixel.value = skin.data.isPixel;
		// uiElements.settingsBox.widthDiv.value = skin.data.pixelSize[0];
		// uiElements.settingsBox.heightDiv.value = skin.data.pixelSize[1];
		uiElements.toolBar.coolBGCheckbox.value = true;
		uiElements.settingsBox.shaderColoringBox.value = skin.data.inGameColoring;
		uiElements.settingsBox.noteColorPicker.value = skin.data.arrowRGB[0].r;
		uiElements.settingsBox.curColorDropdown.value = "Red";
	}
	
	function resetColorValues(type:String = 'Default')
	{
		trace(type);
		switch (type)
		{
			case 'File':
				var json = helperLoading(curName);
				trace(json.data.arrowRGB.copy());
				skin.data.arrowRGB = json.data.arrowRGB.copy();
			default:
				skin.data.arrowRGB = NoteUtil.defaultColors.copy();
		}
		refreshUIValues();
		updateStrumColors();
	}
	
	function updateStrumColors()
	{
		if (!skin.inEngineColoring) return;
		
		for (strumnote in field.members)
		{
			if (strumnote.animation.curAnim.name != 'static') strumnote.rgbShader.setColors(NoteUtil.colorToArray(skin.data.arrowRGB[strumnote.noteData]));
		}
	}
	
	// function spawnGhostField()
	// {
	// 	if (ghostfields.members.length > 0)
	// 	{
	// 		for (i in ghostfields.members)
	// 			i = FlxDestroyUtil.destroy(i);
	// 		ghostfields.clear();
	// 	}
	// 	for (i in playfields.members)
	// 	{
	// 		var field = new PlayField(i.baseX, i.baseY, i.keyCount, null, true, false, true, i.player, 'default', skin);
	// 		field.baseAlpha = uiElements.toolBar.ghostAlphaSlider.value;
	// 		field.generateReceptors();
	// 		field.fadeIn(true);
	// 		field.quants = false;
	// 		ghostfields.add(field);
	// 		for (j in field.members)
	// 		{
	// 			final ogNote = i.members[j.noteData];
	// 			j.scrollFactor.set(1, 1);
	// 			j.antialiasing = ogNote.antialiasing;
	// 			j.useRGBShader = ogNote.useRGBShader;
	// 			j.playAnim(ogNote.getAnimName(), true);
	// 		}
	// 	}
	// }
	
	function buildNotes(?skipTween:Bool = false)
	{
		NoteUtil.noteskins = [skin];
		
		if (fieldBounds.length > 0)
		{
			for (i in fieldBounds)
			{
				remove(i);
				i = FlxDestroyUtil.destroy(i);
			}
			fieldBounds = [];
		}
		
		if (field != null)
		{
			field._skin = skin;
			
			for (i in field.members)
			{
				i.texture = field._skin.noteTexture;
				i.useRGBShader = field._skin.inEngineColoring;
				i.rgbShader.enabled = i.useRGBShader;
				i.reloadNote();
			}
			// not necessary rn will do later
			// field.forEachAliveNote((note) -> {
			// 	note.skin = noteskin2;
			// 	note.texture = field._skin.noteTexture;
			// 	note.rgbEnabled = field._skin.inEngineColoring;
			// 	note.rgbShader.enabled = note.rgbEnabled;
			// 	note.loadNoteAnims();
			// });
			field.grpNoteSplashes.forEachAlive((splash) -> {
				splash.rgbShader.enabled = field._skin.inEngineColoring;
			});
			field.grpSusSplashes.forEachAlive((splash) -> {
				splash.rgbShader.enabled = field._skin.inEngineColoring;
			});
			
			field.generateReceptors();
			field.fadeIn(skipTween);
		}
		else
		{
			field = new PlayField(112 * 3, 112 * 2, uiElements.settingsBox.keycount.value, null, true, false, true, 0, curName, skin);
			// field.baseAlpha = 0.8;
			field.generateReceptors();
			field.fadeIn(skipTween);
			field.quants = false;
			field.camera = FlxG.camera;
			add(field);
		}
		
		// annoying but whatever
		for (i in field.members)
		{
			i.scrollFactor.set(1, 1);
			i.antialiasing = skin.antialiasing;
			i.useRGBShader = skin.inEngineColoring;
			i.playAnim('static', true);
			
			var bounds = new DebugBounds(i);
			bounds.visible = true;
			bounds.alpha = uiElements.toolBar.showBounds.value ? 1 : 0.00001;
			add(bounds);
			fieldBounds.push(bounds);
		}
		
		curSelectedNote = field.members[0];
	}
	
	function refreshAnimDropdown()
	{
		switch (mode)
		{
			case RECEPTORS:
				final tempAnimArray = [];
				final data = curSelectedNote != null ? curSelectedNote.noteData ?? 0 : 0;
				
				receptorAnimArray = skin.data.receptorAnimations[data];
				for (anim in skin.data.receptorAnimations[data])
				{
					tempAnimArray.push(ToolKitUtils.makeSimpleDropDownItem(anim.anim));
				}
				uiElements.settingsBox.animationsDropdown.populateList(tempAnimArray);
				uiElements.settingsBox.noteTexture.value = skin.data.noteTexture;
				// uiElements.settingsBox.opponentTexture.value = helper.data.opponentSkin;
				// uiElements.settingsBox.extraTexture.value = helper.data.extraSkin;
				refreshAnimFields(0);
			default:
				// lol
		}
	}
	
	function refreshAnimFields(data:Int = 0)
	{
		switch (mode)
		{
			case RECEPTORS:
				final anim = receptorAnimArray[data];
				if (anim != null)
				{
					uiElements.settingsBox.animationNameTextField.value = anim.anim;
					uiElements.settingsBox.animationPrefixTextField.value = anim.xmlName;
					uiElements.settingsBox.animationFramerateStepper.value = anim.fps;
				}
				else refreshAnimDropdown();
			default:
				// lol
		}
	}
	
	function addAnim()
	{
		switch (mode)
		{
			case RECEPTORS:
				final data = uiElements?.settingsBox?.animationsDropdown?.selectedIndex ?? 0;
				final tempAnim = receptorAnimArray[data] ?? NoteUtil.fallbackReceptorAnims[0];
				final animName = uiElements?.settingsBox?.animationNameTextField?.value ?? tempAnim.anim;
				final anim:Animation =
					{
						anim: animName,
						xmlName: uiElements?.settingsBox?.animationPrefixTextField?.value ?? tempAnim.xmlName,
						offsets: getOffsetFromAnim(animName, data),
						looping: uiElements?.settingsBox?.animationLoopCheckbox?.value ?? false,
						fps: uiElements?.settingsBox?.animationFramerateStepper?.value ?? 24
					}
				final hadAnim = curSelectedNote.hasAnim(anim.anim);
				if (hadAnim)
				{
					curSelectedNote.animation._curAnim = null;
					curSelectedNote.removeAnim(animName);
				}
				curSelectedNote.addAnim(anim);
				curSelectedNote.playAnim(animName, true, null);
				FlxG.sound.play(Paths.sound('ui/success'));
				ToolKitUtils.makeNotification('Animation Addition', 'Successfully ${hadAnim ? 'updated' : 'added'} "$animName" to note skin.', Success);
			default:
				// lol
		}
	}
	
	function refreshSkinDropdown()
	{
		var skinList = [];
		#if MODS_ALLOWED
		var files = Paths.listAllFilesInDirectory('data/noteskins/');
		for (i in Paths.listAllFilesInDirectory('noteskins/'))
			files.push(i);
		for (file in files)
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
		FlxG.mouse.visible = true;
		controlCamera(elapsed);
		
		// only reason these r separate funcs is just for better readability & workflow
		// i dont want the giant block of code at the top of my func im sorry
		handleReceptorUpdate(elapsed);
		if ((ToolKitUtils.isHaxeUIHovered(camHUD) && FlxG.mouse.justPressed) || FlxG.mouse.justPressedRight)
		{
			FlxG.sound.play(Paths.sound('ui/mouseClick'));
		}
	}
	
	function handleReceptorUpdate(elapsed:Float)
	{
		if (field != null)
		{
			for (note in field.members)
			{
				if (FlxG.mouse.overlaps(note))
				{
					note.alphaMult = 0.9;
					
					if (FlxG.mouse.justPressed)
					{
						curSelectedNote = note;
						refreshAnimDropdown();
					}
				}
				else note.alphaMult = (note.noteData == curSelectedNote.noteData ? 1 : 0.4);
			}
		}
		
		if (curSelectedNote != null)
		{
			final animName = curSelectedNote.getAnimName();
			final baseOffset = getOffsetFromAnim(animName, curSelectedNote.noteData);
			final bounds = fieldBounds[curSelectedNote.noteData];
			
			trace(bounds);
			// moving offsets with ur mouse
			if (FlxG.mouse.overlaps(bounds.middle) && FlxG.mouse.pressedRight)
			{
				final newOffset = [baseOffset[0] - FlxG.mouse.deltaViewX, baseOffset[1] - FlxG.mouse.deltaViewY];
				addReceptorOffset(curSelectedNote, animName, newOffset);
			}
			// reset current offset to 0,0
			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.R)
			{
				addReceptorOffset(curSelectedNote, animName, [0, 0]);
				ToolKitUtils.makeNotification('Offsetting', 'Current animation offset reset to [0, 0].', Info);
				FlxG.sound.play(Paths.sound('ui/openPopup'));
			}
		}
	}
	
	function controlCamera(elapsed:Float)
	{
		// flagging ctrl so that if u reset a offset it doesnt also reset the camera
		if (FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL)
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
	
	function saveSkinToFile()
	{
		inline function getSusSplashOrigin() return [0, 0];
		
		var json =
			{
				"noteTexture": skin.noteTexture,
				"splashTexture": skin.splashTexture,
				"sustainSplashTexture": skin.sustainSplashTexture,
				
				"antialiasing": skin.antialiasing,
				"singAnimations": skin.singAnimations,
				
				"noteAnimations": skin.noteAnims,
				"receptorAnimations": skin.receptorAnims,
				"noteSplashAnimations": skin.splashAnims,
				
				"splashesEnabled": true,
				"susSplashesEnabled": true,
				
				"receptorAlpha": 1.0,
				"sustainAlpha": 1.0,
				"splashAlpha": 1.0,
				"susSplashAlpha": 1.0,
				
				"receptorScale": 0.7,
				"noteScale": 0.7,
				"splashScale": 1.0,
				"susSplashScale": 1.0,
				
				"susSplashOrigin": getSusSplashOrigin(),
				
				"inGameColoring": skin.inEngineColoring,
				"arrowRGB": skin.colors
			}
		final dataToSave:String = Json.stringify(json, "\t");
		
		if (dataToSave.length > 0)
		{
			FileUtil.saveFile(dataToSave, '${uiElements.toolBar.skinName.value}.json', onFileSaveComplete, onFileSaveCancel);
		}
	}
	
	function onFileSaveComplete(str:String)
	{
		ToolKitUtils.makeNotification('Skin File Saving', 'Skin was successfully saved.', Success);
		FlxG.sound.play(Paths.sound('ui/success'));
	}
	
	function onFileSaveCancel()
	{
		ToolKitUtils.makeNotification('Skin File Saving', 'Skin saving was canceled.', Warning);
		FlxG.sound.play(Paths.sound('ui/warn'));
	}
	
	function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		// if (cpuControlled || paused || !startedCountdown) return;
		if (key > -1 && FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
		{
			// this keeps crashing idk why
			try
			{
				if (field.inControl && !field.autoPlayed && field.playerControls && !FlxG.keys.pressed.CONTROL)
				{
					var spr:StrumNote = field.members[key];
					shuffleThroughAnims(spr);
				}
			}
			catch (e) {}
		}
	}
	
	function shuffleThroughAnims(key:StrumNote)
	{
		if (key != null)
		{
			switch (key.animation.curAnim.name)
			{
				case 'static':
					strumPlayAnim('pressed', key, 0);
				case 'pressed':
					strumPlayAnim('confirm', key, 0);
				case 'confirm':
					strumPlayAnim('static', key, 0);
			}
		}
	}
	
	function strumPlayAnim(anim:String, spr:StrumNote, time:Float = 1)
	{
		if (spr != null)
		{
			spr.playAnim(anim, true);
			spr.resetAnim = time;
		}
	}
	
	function addReceptorOffset(note:Dynamic, name:String = 'static', offsets:Array<Float>)
	{
		if (offsets == null || offsets.length < 2) offsets = [0, 0];
		if (note != null)
		{
			note.addOffset(name, offsets[0], offsets[1]);
			skin.data.receptorAnimations[note.noteData][getAnimIndex(name)].offsets = offsets;
			note.playAnim(name, true);
		}
	}
	
	function getAnimIndex(anim:String):Int
	{
		return switch (anim)
		{
			case 'pressed': 1;
			case 'confirm': 2;
			default: 0;
		}
	}
	
	// quick handler to get offsets quickly from an animation
	function getOffsetFromAnim(anim:String = 'static', data:Int)
	{
		var offset:Null<Array<Float>> = switch (mode)
		{
			default:
				[0, 0];
			case RECEPTORS:
				final animIndex = getAnimIndex(anim);
				skin.data.receptorAnimations[data][animIndex].offsets;
		}
		final _x = offset[0] ?? 0;
		final _y = offset[1] ?? 0;
		return [_x, _y];
	}
	
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
