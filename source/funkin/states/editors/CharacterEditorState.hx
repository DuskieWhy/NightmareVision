package funkin.states.editors;

import extensions.openfl.FileReferenceEx;

import haxe.io.Path;

import flixel.group.FlxSpriteContainer;

import haxe.ui.components.Stepper;
import haxe.Json;
import haxe.ui.components.popups.ColorPickerPopup;
import haxe.ui.components.CheckBox;
import haxe.ui.components.Button;
import haxe.ui.components.Slider;
import haxe.ui.backend.flixel.UIState;

import openfl.events.Event;
import openfl.net.FileReference;

import flixel.group.FlxContainer;
import flixel.graphics.FlxGraphic;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxBackdrop;

import funkin.states.editors.ui.CharacterEditorKit.CharEditorUI;
import funkin.states.editors.ui.DebugBounds;
import funkin.data.CharacterData.CharacterParser;
import funkin.data.CharacterData.CharacterInfo;
import funkin.data.CharacterData.AnimationInfo;
import funkin.objects.HealthIcon;
import funkin.objects.Character;

using funkin.states.editors.ui.ToolKitUtils;

abstract UndoData(Dynamic)
{
	@:from static inline function fromCheckbox(obj:CheckBox):UndoData return cast obj;
	
	@:to public inline function toCheckbox():CheckBox return cast this;
	
	@:from static inline function fromSlider(obj:Slider):UndoData return cast obj;
	
	@:to public inline function toSlider():Slider return cast this;
	
	@:from static inline function fromStepper(obj:Stepper):UndoData return cast obj;
	
	@:to public inline function toStepper():Stepper return cast this;
	
	@:from static inline function fromFlxSprite(obj:FlxSprite):UndoData return cast obj;
	
	@:to public inline function toFlxSprite():FlxSprite return cast this;
}

@:structInit class UndoAction
{
	public var type:UndoType;
	public var object:UndoData;
	public var value:Dynamic;
}

enum abstract UndoType(String)
{
	var DRAGGED;
	var CHANGED_CHECKBOX;
	var MOVED_SLIDER;
	// var CHANGED_STEPPER; //idk...
}

@:bitmap("assets/excluded/images/cursorCross.png")
class Crosshair extends openfl.display.BitmapData {}

//	todo
// 	clean up?
// 	find possible crash scenarios
// 	add more keybinds
// 	improve tooltips/legend
// 	save dialogbox location
//
// if HAXEUI BREAKS ADD THIS TO FLAG -Dhaxeui_experimental_no_cache
class CharacterEditorState extends UIState // MUST EXTEND UI STATE needed for access to a root
{
	public static final MAX_REMEMBERED_ACTIONS:Int = 25;
	
	var undoActions:Array<UndoAction> = []; // perhaps this coud be made it into its own clipboard class but for now this is fine
	
	var redoActions:Array<UndoAction> = [];
	
	var pointerBounds:DebugBounds;
	
	var characterBounds:DebugBounds = null;
	
	var bgLayer:Null<FlxContainer> = null;
	
	var silhouettes:Null<FlxContainer> = null;
	var grid:FlxBackdrop;
	var charLayer:FlxContainer;
	
	var characterGhost:Null<Character> = null;
	var character:Null<Character> = null;
	var healthIcon:HealthIcon;
	
	var cameraPointer:FlxSprite;
	
	var uiElements:CharEditorUI;
	
	var camHUD:FlxCamera;
	
	var characterId:String = 'bf';
	
	final dadPos = new FlxPoint(100, 100);
	final bfPos = new FlxPoint(770, 100);
	
	var isCameraDragging:Bool = false;
	var isTextFieldFocused:Bool = false;
	
	var goToPlayState:Bool = false;
	
	public function new(?char:String, goToPlayState:Bool = false)
	{
		super();
		if (char != null) characterId = char;
		this.goToPlayState = goToPlayState;
	}
	
	override function create()
	{
		super.create();
		
		FlxG.cameras.reset();
		FlxG.cameras.add(camHUD = new FlxCamera(), false);
		camHUD.bgColor = 0x0;
		
		FlxG.mouse.visible = true;
		
		buildBG();
		
		silhouettes = new FlxContainer();
		add(silhouettes);
		
		try
		{
			var dad = new Character(dadPos.x, dadPos.y, 'dad', false);
			var bf = new Character(bfPos.x, bfPos.y, 'bf', true);
			dad.active = false;
			bf.active = false;
			dad.x += dad.positionArray[0];
			dad.y += dad.positionArray[1];
			bf.x += bf.positionArray[0];
			bf.y += bf.positionArray[1];
			dad.color = 0xFF000000;
			bf.color = 0xFF000000;
			dad.alpha = 0.2;
			bf.alpha = 0.2;
			silhouettes.add(dad);
			silhouettes.add(bf);
		}
		catch (e) {}
		
		charLayer = new FlxContainer();
		add(charLayer);
		
		characterBounds = new DebugBounds(character);
		add(characterBounds);
		characterBounds.visible = false;
		characterBounds.color = FlxColor.RED;
		
		healthIcon = new HealthIcon();
		add(healthIcon);
		healthIcon.visible = false;
		
		cameraPointer = new FlxSprite().loadGraphic(FlxGraphic.fromClass(Crosshair));
		cameraPointer.antialiasing = false;
		cameraPointer.setGraphicSize(40, 40);
		cameraPointer.updateHitbox();
		cameraPointer.color = FlxColor.WHITE;
		add(cameraPointer);
		
		buildUI();
		
		spawnCharacter();
		
		refreshCharDropDown();
		
		uiElements.toolBar.characterDropdown.selectItemBy((item) -> return item.id == characterId);
		
		dance();
		
		pointerBounds = new DebugBounds(cameraPointer);
		add(pointerBounds);
		pointerBounds.alpha = 0;
	}
	
	function exitState()
	{
		if (goToPlayState)
		{
			FlxG.switchState(PlayState.new);
		}
		else
		{
			FlxG.switchState(funkin.states.editors.MasterEditorMenu.new);
			FunkinSound.playMusic(Paths.music('freakyMenu'));
		}
		FlxG.mouse.visible = false;
	}
	
	public function buildUI()
	{
		root.cameras = [camHUD]; // this tells every single component to use this camera
		
		uiElements = new CharEditorUI();
		add(uiElements);
		
		uiElements.characterDialogBox.bindDialogToView(); // so u cant push it off screen
		
		uiElements.toolBar.exitMenuButton.onClick = (ui) -> {
			exitState();
		}
		
		uiElements.toolBar.redoButton.onClick = (ui) -> {
			triggerClipboardAction(false);
		}
		uiElements.toolBar.undoButton.onClick = (ui) -> {
			triggerClipboardAction(true);
		}
		
		uiElements.toolBar.toggleCharBounds.onClick = (ui) -> {
			characterBounds.visible = !characterBounds.visible;
			characterBounds.target = character;
		}
		
		uiElements.toolBar.openHelpWindow.onClick = (ui) -> {
			uiElements.legendWindow?.destroy();
			uiElements.spawnLegend();
		}
		
		uiElements.toolBar.findComponent('stageBGCheckbox', CheckBox).onChange = (ui) -> {
			bgLayer.visible = ui.value.toBool();
			
			if (bgLayer.visible)
			{
				uiElements.toolBar.gridBGCheckbox.value = false;
				grid.visible = false;
			}
		}
		
		uiElements.toolBar.showSilhouettes.onChange = (ui) -> {
			silhouettes.visible = ui.value.toBool();
		}
		
		uiElements.toolBar.gridBGCheckbox.onChange = (ui) -> {
			final val = ui.value.toBool();
			if (val)
			{
				uiElements.toolBar.stageBGCheckbox.value = false;
				bgLayer.visible = false;
			}
			
			grid.visible = val;
		}
		
		uiElements.toolBar.bgView.findComponent('bgColour', ColorPickerPopup).onChange = (ui) -> {
			final newColour = FlxColor.fromString(ui.value.toString());
			if (FlxG.camera.bgColor != newColour)
			{
				uiElements.toolBar.findComponent('stageBGCheckbox', CheckBox).value = false;
				uiElements.toolBar.gridBGCheckbox.value = false;
			}
			
			FlxG.camera.bgColor = newColour;
		}
		
		uiElements.toolBar.refreshCharButton.onClick = (ui) -> {
			refreshCharDropDown();
			spawnCharacter(true);
		}
		
		uiElements.toolBar.isPlayerCheckBox.onChange = (ui) -> {
			character.isPlayer = ui.value.toBool();
			character.flipX = (character.originalFlipX != character.isPlayer);
			
			positionCharacter();
		}
		
		uiElements.toolBar.isPlayerCheckBox.onClick = (ui) -> {
			addUndoAction(CHANGED_CHECKBOX, uiElements.toolBar.isPlayerCheckBox, !uiElements.toolBar.isPlayerCheckBox.value);
		}
		
		// opened the dropdown
		uiElements.toolBar.characterDropdown.onClick = (ui) -> {
			refreshCharDropDown();
		}
		
		// we selected a new char
		uiElements.toolBar.characterDropdown.onChange = (ui) -> {
			if (ui.data.isDropDownItem())
			{
				characterId = ui.data.id;
				
				spawnCharacter();
				
				resetActions();
			}
		}
		
		uiElements.toolBar.saveCharacterButton.onClick = (ui) -> {
			saveCharToFile();
		}
		
		uiElements.animationList.onClick = (ui) -> {
			if (uiElements.animationList.animationList.selectedItem != null)
			{
				final anim = uiElements.animationList.animationList.selectedItem.id;
				if (character.hasAnim(anim))
				{
					character.playAnim(anim);
				}
				else
				{
					FlxG.sound.play(Paths.sound('ui/error'));
				}
			}
		}
		
		uiElements.toolBar.loadTemplateButton.onClick = (ui) -> {
			if (character == null)
			{
				character = new Character(0, 0, 'dad');
				charLayer.add(character);
			}
			
			character.loadFile(templateCharacterFile);
			
			positionCharacter();
			
			character.debugMode = true;
			
			character.recalculateDanceIdle();
			character.dance();
			
			characterId = 'dad';
			
			updateAnimList();
			updateDialogBox();
			resetActions();
		}
		
		// GHOST SETTINGS
		var slider = uiElements.toolBar.ghostSettings.findComponent('ghostAlphaSlider', Slider);
		if (slider != null)
		{
			slider.onChange = (ui) -> {
				if (characterGhost != null)
				{
					characterGhost.alpha = ui.value.toFloat();
				}
			}
			
			slider.onDragStart = (ui) -> {
				addUndoAction(MOVED_SLIDER, slider, slider.value);
			}
		}
		
		var ghostEnabledButton = uiElements.toolBar.ghostSettings.findComponent('enableGhost', Button);
		if (ghostEnabledButton != null)
		{
			ghostEnabledButton.onClick = (ui) -> {
				spawnGhost();
			}
		}
		
		var ghostBlend = uiElements.toolBar.ghostSettings.findComponent('ghostBlend', CheckBox);
		if (ghostBlend != null)
		{
			ghostBlend.onChange = (ui) -> {
				if (characterGhost != null)
				{
					final offset = ui.value.toBool() ? 125 : 0;
					
					characterGhost.colorTransform.redOffset = offset;
					characterGhost.colorTransform.greenOffset = offset;
					characterGhost.colorTransform.blueOffset = offset;
				}
			}
			
			ghostBlend.onClick = (ui) -> {
				addUndoAction(CHANGED_CHECKBOX, ghostBlend, !ghostBlend.value);
			}
		}
		
		uiElements.toolBar.ghostInFront.onClick = (ui) -> {
			updateGhostLayering();
			addUndoAction(CHANGED_CHECKBOX, uiElements.toolBar.ghostInFront, !uiElements.toolBar.ghostInFront.value);
		}
		
		// dialogebox stuff
		
		uiElements.characterDialogBox.danceEveryStepper.onChange = (ui) -> {
			character.danceEveryNumBeats = ui.value.toInt();
		}
		
		uiElements.characterDialogBox.flipXCheckbox.onChange = (ui) -> {
			if (character.originalFlipX == ui.value.toBool()) return;
			character.originalFlipX = !character.originalFlipX;
			character.flipX = (character.originalFlipX != character.isPlayer);
		}
		
		uiElements.characterDialogBox.antialiasingCheckbox.onChange = (ui) -> {
			character.noAntialiasing = !ui.value.toBool();
			character.antialiasing = !character.noAntialiasing;
		}
		
		uiElements.characterDialogBox.scaledOffsetsCheckbox.onChange = (ui) -> {
			character.scalableOffsets = ui.value.toBool();
		}
		
		for (i in [uiElements.characterDialogBox.flipXCheckbox, uiElements.characterDialogBox.antialiasingCheckbox, uiElements.characterDialogBox.scaledOffsetsCheckbox, uiElements.characterDialogBox.flipXAnimCheckbox, uiElements.characterDialogBox.flipYAnimCheckbox, uiElements.characterDialogBox.animationLoopCheckbox])
		{
			i.onClick = (ui) -> {
				addUndoAction(CHANGED_CHECKBOX, i, !i.value);
			}
		}
		
		uiElements.characterDialogBox.scaleStepper.onChange = (ui) -> {
			final newScale = ui.value.toFloat();
			character.scale.set(newScale, newScale);
			character.updateHitbox();
			character.jsonScale = newScale;
		}
		
		uiElements.characterDialogBox.singLengthStepper.onChange = (ui) -> {
			character.singDuration = ui.value.toFloat();
		}
		
		uiElements.characterDialogBox.characterXStepper.onChange = (ui) -> {
			character.positionArray[0] = ui.value.toFloat();
			positionCharacter();
		}
		
		uiElements.characterDialogBox.characterYStepper.onChange = (ui) -> {
			character.positionArray[1] = ui.value.toFloat();
			positionCharacter();
		}
		
		uiElements.characterDialogBox.characterCamXStepper.onChange = (ui) -> {
			character.cameraPosition[0] = ui.value.toFloat();
		}
		
		uiElements.characterDialogBox.characterCamYStepper.onChange = (ui) -> {
			character.cameraPosition[1] = ui.value.toFloat();
		}
		
		uiElements.characterDialogBox.healthColourPicker.onChange = (ui) -> {
			final colour = FlxColor.fromString(ui.value.toString());
			character.healthColour = colour;
			
			var bgColour = FlxColor.interpolate(0xFF3D3F41, colour, 0.1);
			
			uiElements.characterDialogBox.iconDisplay.backgroundColor = cast bgColour;
		}
		
		uiElements.characterDialogBox.clearGameoverOptions.onClick = (ui) -> {
			uiElements.characterDialogBox.gameoverCharTextField.value = '';
			uiElements.characterDialogBox.gameoverConfirmDeathSoundTextField.value = '';
			uiElements.characterDialogBox.gameoverLoopDeathSoundTextField.value = '';
			uiElements.characterDialogBox.gameoverInitialDeathSoundTextField.value = '';
			@:privateAccess
			{
				uiElements.characterDialogBox.gameoverInitialDeathSoundTextField.focus = false;
				uiElements.characterDialogBox.gameoverConfirmDeathSoundTextField.focus = false;
				uiElements.characterDialogBox.gameoverLoopDeathSoundTextField.focus = false;
				uiElements.characterDialogBox.gameoverInitialDeathSoundTextField.focus = false;
			}
		}
		
		uiElements.characterDialogBox.gameoverCharTextField.onChange = (ui) -> {
			var val:String = uiElements.characterDialogBox.gameoverCharTextField.value;
			
			character.gameoverCharacter = val.trim().length == 0 ? null : val.trim();
		}
		
		uiElements.characterDialogBox.gameoverConfirmDeathSoundTextField.onChange = (ui) -> {
			var val:String = uiElements.characterDialogBox.gameoverConfirmDeathSoundTextField.value;
			
			character.gameoverConfirmDeathSound = val.trim().length == 0 ? null : val.trim();
		}
		
		uiElements.characterDialogBox.gameoverInitialDeathSoundTextField.onChange = (ui) -> {
			var val:String = uiElements.characterDialogBox.gameoverInitialDeathSoundTextField.value;
			
			character.gameoverInitialDeathSound = val.trim().length == 0 ? null : val.trim();
		}
		
		uiElements.characterDialogBox.gameoverLoopDeathSoundTextField.onChange = (ui) -> {
			var val:String = uiElements.characterDialogBox.gameoverLoopDeathSoundTextField.value;
			
			character.gameoverLoopDeathSound = val.trim().length == 0 ? null : val.trim();
		}
		
		uiElements.characterDialogBox.healthIconTextField.onChange = (ui) -> {
			character.healthIcon = uiElements.characterDialogBox.healthIconTextField.value;
			updateHealthIcon();
		}
		
		uiElements.characterDialogBox.getIconColourButton.onClick = (ui) -> {
			final newColour = CoolUtil.dominantColor(healthIcon);
			uiElements.characterDialogBox.healthColourPicker.value = newColour;
			character.healthColour = newColour;
		}
		
		uiElements.characterDialogBox.reloadCharacterImageButton.onClick = (ui) -> {
			reloadCharacter();
		}
		
		uiElements.characterDialogBox.removeAnimationButton.onClick = (ui) -> {
			if (uiElements.characterDialogBox.animationsDropdown.selectedItem == null
				|| !uiElements.characterDialogBox.animationsDropdown.selectedItem.isDropDownItem()) return;
				
			final anim = uiElements.characterDialogBox.animationsDropdown.selectedItem.id;
			
			var destroyedAllAnims:Bool = false;
			
			if (character.hasAnim(anim))
			{
				// jank but removeAnim would crash //im just gonna leave this as is
				@:privateAccess
				if ((character.animateAtlas != null && Lambda.count(character.animateAtlas.anim._animations) == 1)
					|| Lambda.count(character.animation._animations) == 1)
				{
					if (character.animateAtlas != null) character.animateAtlas.anim.destroyAnimations();
					else character.animation.destroyAnimations();
					
					destroyedAllAnims = true;
				}
				else
				{
					character.removeAnim(anim);
				}
			}
			
			var previousIndex = -1;
			for (k => i in character.animations)
			{
				if (i.anim == anim)
				{
					character.animations.remove(i);
					character.animOffsets.remove(i.anim);
					previousIndex = k;
					FlxG.sound.play(Paths.sound('ui/success'));
					
					ToolKitUtils.makeNotification('Animation Removal', 'Animation "$anim" successfully removed', Success);
					
					break;
				}
			}
			
			if (previousIndex != -1 && character.animations.length != 0)
			{
				final index = FlxMath.wrap(previousIndex, 0, character.animations.length - 1);
				character.playAnim(character.animations[index].anim);
				uiElements.animationList.animationList.selectItemBy((item) -> return item.id == character.getAnimName());
				uiElements.characterDialogBox.animationsDropdown.selectItemBy((item) -> return item.id == character.getAnimName());
			}
			
			if (destroyedAllAnims)
			{
				fillAnimationFields();
			}
			
			updateAnimList();
		}
		
		uiElements.characterDialogBox.addAnimationButton.onClick = (ui) -> {
			//
			final animName = uiElements.characterDialogBox.animationNameTextField.value;
			final prefix = uiElements.characterDialogBox.animationPrefixTextField.value;
			final indicesTxt = uiElements.characterDialogBox.animationIndicesTextField.getTextInput().text.trim().split(',');
			final flipX = uiElements.characterDialogBox.flipXAnimCheckbox.value;
			final flipY = uiElements.characterDialogBox.flipYAnimCheckbox.value;
			
			final indices:Array<Int> = [];
			
			if (indicesTxt.length > 1)
			{
				for (i in 0...indicesTxt.length)
				{
					var index:Int = Std.parseInt(indicesTxt[i]);
					if (indicesTxt[i] != null && indicesTxt[i] != '' && !Math.isNaN(index) && index > -1)
					{
						indices.push(index);
					}
				}
			}
			
			var hadAnim = false;
			var previousOffsets:Array<Int> = [0, 0];
			
			for (anim in character.animations)
			{
				if (anim.anim == animName)
				{
					previousOffsets = anim.offsets;
					if (character.hasAnim(animName))
					{
						@:privateAccess
						{
							character.removeAnim(animName);
							var animController = character.animateAtlas != null ? character.animateAtlas.anim : character.animation;
							
							animController._curAnim = null; // ok
						}
						hadAnim = true;
					}
					character.animations.remove(anim);
					break;
				}
			}
			
			final newAnim:AnimationInfo =
				{
					anim: animName,
					name: prefix,
					fps: Math.round(uiElements.characterDialogBox.animationFramerateStepper.value),
					loop: uiElements.characterDialogBox.animationLoopCheckbox.selected,
					indices: indices,
					offsets: previousOffsets,
					flipX: flipX,
					flipY: flipY
				};
				
			addAnim(newAnim.anim, newAnim.name, newAnim.fps, newAnim.loop, newAnim.indices, newAnim.flipX, newAnim.flipY);
			character.animations.push(newAnim);
			character.addOffset(newAnim.anim, newAnim.offsets[0], newAnim.offsets[1]);
			
			if (character.hasAnim(animName))
			{
				FlxG.sound.play(Paths.sound('ui/success'));
				
				character.playAnim(animName, true);
				
				ToolKitUtils.makeNotification('Animation Addition', 'Successfully ' + (hadAnim ? 'updated' : 'added') + ' "$animName" to character.', Success);
			}
			else
			{
				FlxG.sound.play(Paths.sound('ui/warn'));
				ToolKitUtils.makeNotification('Animation Addition', 'Could not add "$animName" to character.', Warning);
			}
			
			updateAnimList();
			
			uiElements.characterDialogBox.animationsDropdown.selectItemBy((item) -> return item.id == animName);
			uiElements.animationList.animationList.selectItemBy((item) -> return item.id == animName);
		}
		
		uiElements.characterDialogBox.animationsDropdown.onChange = (ui) -> {
			if (ui.data.isDropDownItem()) fillAnimationFields(ui.data.id);
		}
		
		// textfield fuckery
		final dialog = uiElements.characterDialogBox;
		
		// UGHHHHHHH
		for (i in [dialog.imageFileTextField, dialog.healthIconTextField, dialog.animationNameTextField, dialog.animationPrefixTextField, dialog.animationIndicesTextField, dialog.gameoverCharTextField, dialog.gameoverConfirmDeathSoundTextField, dialog.gameoverInitialDeathSoundTextField, dialog.gameoverLoopDeathSoundTextField])
		{
			i.onClick = (ui) -> {
				isTextFieldFocused = true;
			}
		}
	}
	
	function triggerClipboardAction(isUndo:Bool = true)
	{
		if (undoActions.length == 0 && redoActions.length == 0) return;
		
		final arrayToUse = isUndo ? undoActions : redoActions;
		
		final action = arrayToUse.shift();
		
		if (action == null) return;
		
		var popupText = '';
		switch (action.type)
		{
			case DRAGGED:
				var obj = action.object.toFlxSprite();
				
				if (obj == pointerBounds.target)
				{
					if (isUndo) addRedoAction(action.type, obj, [for (i in character.cameraPosition) i]);
					else addUndoAction(action.type, obj, [for (i in character.cameraPosition) i]);
					
					character.cameraPosition[0] = action.value[0];
					character.cameraPosition[1] = action.value[1];
					
					uiElements.characterDialogBox.characterCamXStepper.value = character.cameraPosition[0];
					uiElements.characterDialogBox.characterCamYStepper.value = character.cameraPosition[1];
					
					popupText = 'Changed Camera Position to ${character.cameraPosition}';
				}
				else if (obj == character)
				{
					if (isUndo) addRedoAction(action.type, obj, [character.offset.x, character.offset.y]);
					else addUndoAction(action.type, obj, [character.offset.x, character.offset.y]);
					
					character.offset.x = action.value[0];
					character.offset.y = action.value[1];
					
					updateCurrentAnimOffsets();
					
					popupText = 'Changed Character offset to ${character.offset}';
				}
				
			case MOVED_SLIDER:
				if (isUndo) addRedoAction(action.type, action.object, action.object.toSlider().value);
				else addUndoAction(action.type, action.object, action.object.toSlider().value);
				
				action.object.toSlider().value = action.value;
				popupText = 'Changed (${action.object.toSlider().id}) to ${Math.round(action.value * 100)}%';
				
			case CHANGED_CHECKBOX:
				if (isUndo) addRedoAction(action.type, action.object, action.object.toCheckbox().value);
				else addUndoAction(action.type, action.object, action.object.toCheckbox().value);
				
				action.object.toCheckbox().value = action.value;
				popupText = 'Changed (${action.object.toCheckbox().id}) to ${action.value}';
				
			default:
		}
		
		FlxG.sound.play(Paths.sound('ui/openPopup'), 0.5);
		
		ToolKitUtils.makeNotification((isUndo ? 'Undo' : 'Redo') + ' Action', popupText, Info);
	}
	
	function resetActions()
	{
		while (undoActions.length > 0)
		{
			var undo = undoActions.pop();
			undo = null;
		}
		
		while (redoActions.length > 0)
		{
			var redo = redoActions.pop();
			redo = null;
		}
	}
	
	function addUndoAction(type:UndoType, object:UndoData, value:Dynamic)
	{
		undoActions.unshift({value: value, object: object, type: type});
		
		while (undoActions.length > MAX_REMEMBERED_ACTIONS)
		{
			var undo = undoActions.pop();
			undo = null;
		}
	}
	
	function addRedoAction(type:UndoType, object:UndoData, value:Dynamic) // THIS MAY BE WEIRD>?
	{
		redoActions.unshift({value: value, object: object, type: type});
		
		while (redoActions.length > MAX_REMEMBERED_ACTIONS)
		{
			var undo = redoActions.pop();
			undo = null;
		}
	}
	
	function updateHealthIcon()
	{
		if (character == null) return;
		
		healthIcon.changeIcon(character.healthIcon);
		uiElements.setHealthIcon(healthIcon.frame);
	}
	
	public function buildBG()
	{
		if (bgLayer != null) return;
		
		grid = new FlxBackdrop(FlxGridOverlay.create(100, 100, 200, 200).graphic);
		add(grid);
		grid.visible = false;
		
		bgLayer = new FlxContainer();
		add(bgLayer);
		
		var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
		bgLayer.add(bg);
		
		var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		bgLayer.add(stageFront);
	}
	
	override function update(elapsed:Float)
	{
		updateBounds(elapsed);
		
		super.update(elapsed);
		
		if (!isTextFieldFocused)
		{
			if (FlxG.keys.pressed.CONTROL)
			{
				if (FlxG.keys.justPressed.X && redoActions.length > 0)
				{
					triggerClipboardAction(false);
				}
				else if (FlxG.keys.justPressed.Z && undoActions.length > 0)
				{
					triggerClipboardAction(true);
				}
			}
			else
			{
				controlCamera(elapsed);
				playSings();
			}
		}
		else
		{
			if (!ToolKitUtils.isHaxeUIHovered(camHUD)) isTextFieldFocused = false;
		}
		
		if ((ToolKitUtils.isHaxeUIHovered(camHUD) && FlxG.mouse.justPressed) || FlxG.mouse.justPressedRight)
		{
			FlxG.sound.play(Paths.sound('ui/mouseClick'));
		}
		
		uiElements.miscInfo.zoomText.text = 'Camera Zoom: ' + Std.string(FlxMath.roundDecimal(FlxG.camera.zoom, 2)) + 'x';
		var frameInfo = '?';
		if (character != null)
		{
			var maxFrames = character.getAnimNumFrames() - 1;
			if (maxFrames < 0) maxFrames = 0;
			frameInfo = '(' + character.animCurFrame + '/' + maxFrames + ')';
		}
		
		var animationText = 'Animation Frames: $frameInfo';
		
		uiElements.miscInfo.animationFramesText.color = FlxColor.WHITE;
		
		if (uiElements.animationList.animationList.selectedItem != null
			&& !character.hasAnim(uiElements.animationList.animationList.selectedItem.id))
		{
			animationText = 'Error playing animation';
			uiElements.miscInfo.animationFramesText.color = 0xffb82433;
		}
		
		uiElements.miscInfo.animationFramesText.text = animationText;
		
		if (controlOffsets(elapsed) && character != null && uiElements.animationList.animationList.selectedItem != null)
		{
			updateCurrentAnimOffsets();
		}
		
		positionPointer();
		
		if (!isTextFieldFocused)
		{
			FlxG.sound.muteKeys = Init.muteKeys;
			FlxG.sound.volumeDownKeys = Init.volumeDownKeys;
			FlxG.sound.volumeUpKeys = Init.volumeUpKeys;
		}
		else
		{
			FlxG.sound.muteKeys = [];
			FlxG.sound.volumeDownKeys = [];
			FlxG.sound.volumeUpKeys = [];
		}
		
		if (FlxG.keys.justPressed.ESCAPE)
		{
			exitState();
		}
	}
	
	var wasDraggingCursor:Bool = false;
	
	function updateBounds(elapsed:Float)
	{
		var pointerAlpha:Float = 0;
		
		if (pointerBounds.target != null
			&& (wasDraggingCursor
				|| (!ToolKitUtils.isHaxeUIHovered(camHUD)
					&& FlxG.mouse.overlaps(pointerBounds.target, pointerBounds.target.getDefaultCamera())))
			&& character != null)
		{
			pointerAlpha = 1;
			if (FlxG.mouse.justPressed)
			{
				FlxG.sound.play(Paths.sound('ui/mouseClick'));
				addUndoAction(DRAGGED, pointerBounds.target, [character.cameraPosition[0], character.cameraPosition[1]]);
			}
			
			if (FlxG.mouse.pressed)
			{
				wasDraggingCursor = true;
				
				var x = FlxG.mouse.deltaViewX;
				
				if (character.isPlayer) x *= -1;
				
				character.cameraPosition[0] += x;
				
				character.cameraPosition[1] += FlxG.mouse.deltaViewY;
				
				uiElements.characterDialogBox.characterCamXStepper.value = character.cameraPosition[0];
				uiElements.characterDialogBox.characterCamYStepper.value = character.cameraPosition[1];
			}
			
			if (FlxG.mouse.justReleased) wasDraggingCursor = false;
		}
		
		pointerBounds.alpha = FlxMath.lerp(pointerBounds.alpha, pointerAlpha, FlxMath.getElapsedLerp(0.4, elapsed));
	}
	
	function updateCurrentAnimOffsets()
	{
		final offsets = [Std.int(character.offset.x), Std.int(character.offset.y)];
		
		character.addOffset(character.getAnimName(), offsets[0], offsets[1]);
		
		for (i in character.animations)
		{
			if (i.anim == character.getAnimName())
			{
				i.offsets[0] = offsets[0];
				i.offsets[1] = offsets[1];
				break;
			}
		}
		
		final text = character.getAnimName() + ': $offsets';
		
		uiElements.animationList.animationList.selectedItem.text = text;
		
		// call the freaking setter DIE
		uiElements.animationList.animationList.dataSource = uiElements.animationList.animationList.dataSource;
	}
	
	function controlOffsets(elapsed:Float):Bool
	{
		if (FlxG.mouse.pressedRight && !FlxG.mouse.pressedMiddle)
		{
			if (FlxG.mouse.justPressedRight)
			{
				addUndoAction(DRAGGED, character, [character.offset.x, character.offset.y]);
			}
			character.offset.x -= FlxG.mouse.deltaViewX;
			character.offset.y -= FlxG.mouse.deltaViewY;
			
			return true;
		}
		
		if (isTextFieldFocused) return false;
		
		final moveDistance = FlxG.keys.pressed.SHIFT ? 10 : 1;
		
		if (FlxG.keys.justPressed.LEFT)
		{
			character.offset.x += moveDistance;
			return true;
		}
		else if (FlxG.keys.justPressed.DOWN)
		{
			character.offset.y -= moveDistance;
			return true;
		}
		else if (FlxG.keys.justPressed.UP)
		{
			character.offset.y += moveDistance;
			return true;
		}
		else if (FlxG.keys.justPressed.RIGHT)
		{
			character.offset.x -= moveDistance;
			return true;
		}
		
		return false;
	}
	
	override function startOutro(onOutroComplete:() -> Void)
	{
		FlxG.sound.muteKeys = Init.muteKeys;
		FlxG.sound.volumeDownKeys = Init.volumeDownKeys;
		FlxG.sound.volumeUpKeys = Init.volumeUpKeys;
		
		super.startOutro(onOutroComplete);
	}
	
	function playSings()
	{
		final isAlt = FlxG.keys.pressed.SHIFT;
		final isCtrl = FlxG.keys.pressed.CONTROL;
		
		inline function playSing(anim)
		{
			if (isAlt || isCtrl) anim = anim + (isCtrl ? 'miss' : '-alt');
			
			if (!character.hasAnim(anim)) return;
			
			character.playAnim(anim, true);
			uiElements.animationList.animationList.selectItemBy((item) -> return item.id == anim);
		}
		
		if (FlxG.keys.justPressed.A)
		{
			playSing('singLEFT');
		}
		else if (FlxG.keys.justPressed.W)
		{
			playSing('singUP');
		}
		else if (FlxG.keys.justPressed.S)
		{
			playSing('singDOWN');
		}
		else if (FlxG.keys.justPressed.D)
		{
			playSing('singRIGHT');
		}
		else if (FlxG.keys.justPressed.SPACE)
		{
			dance();
		}
		
		if (character.isAnimNull()) return;
		
		if ((FlxG.keys.justPressed.Z || FlxG.keys.justPressed.X))
		{
			character.pauseAnim();
			character.animCurFrame = FlxMath.wrap(character.animCurFrame + (FlxG.keys.justPressed.Z ? -1 : 1), 0, character.getAnimNumFrames() - 1);
		}
		
		if (FlxG.keys.justPressed.C)
		{
			character.playAnim(character.getAnimName(), true);
		}
	}
	
	function controlCamera(elapsed:Float)
	{
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
	
	function refreshCharDropDown() // rewrite this
	{
		var characterList:Array<String> = [];
		
		#if MODS_ALLOWED
		for (file in Paths.listAllFilesInDirectory('characters/'))
		{
			if (file.endsWith('.json') || file.endsWith('.xml'))
			{
				var charToCheck:String = file.withoutDirectory().withoutExtension();
				
				if (!characterList.contains(charToCheck)) characterList.push(charToCheck);
			}
		}
		#else
		characterList = CoolUtil.coolTextFile(Paths.txt('characterList'));
		#end
		
		uiElements.toolBar.characterDropdown.populateList([for (i in characterList) ToolKitUtils.makeSimpleDropDownItem(i)]);
		uiElements.toolBar.characterDropdown.dataSource.sort(null, ASCENDING);
	}
	
	function updateDialogBox()
	{
		if (character == null) return;
		
		uiElements.characterDialogBox.flipXCheckbox.selected = character.originalFlipX;
		uiElements.characterDialogBox.antialiasingCheckbox.value = !character.noAntialiasing;
		uiElements.characterDialogBox.scaledOffsetsCheckbox.value = character.scalableOffsets;
		
		uiElements.characterDialogBox.healthColourPicker.value = character.healthColour;
		
		uiElements.characterDialogBox.scaleStepper.value = character.jsonScale;
		uiElements.characterDialogBox.singLengthStepper.value = character.singDuration;
		uiElements.characterDialogBox.characterXStepper.value = character.positionArray[0];
		uiElements.characterDialogBox.characterYStepper.value = character.positionArray[1];
		
		uiElements.characterDialogBox.characterCamXStepper.value = character.cameraPosition[0];
		uiElements.characterDialogBox.characterCamYStepper.value = character.cameraPosition[1];
		
		uiElements.characterDialogBox.imageFileTextField.value = character.imageFile;
		uiElements.characterDialogBox.healthIconTextField.value = character.healthIcon;
		
		uiElements.characterDialogBox.danceEveryStepper.value = character.danceEveryNumBeats;
		
		updateHealthIcon();
		
		// extra tab
		uiElements.characterDialogBox.gameoverCharTextField.value = character.gameoverCharacter ?? '';
		uiElements.characterDialogBox.gameoverConfirmDeathSoundTextField.value = character.gameoverConfirmDeathSound ?? '';
		uiElements.characterDialogBox.gameoverInitialDeathSoundTextField.value = character.gameoverInitialDeathSound ?? '';
		uiElements.characterDialogBox.gameoverLoopDeathSoundTextField.value = character.gameoverLoopDeathSound ?? '';
		
		// animations tab
		uiElements.characterDialogBox.animationsDropdown.selectItemBy((item) -> return item.id == character.getAnimName());
		
		fillAnimationFields(character.getAnimName());
		
		// this isnt dialogbox!
		
		uiElements.animationList.animationList.selectItemBy((item) -> return item.id == character.getAnimName());
		
		uiElements.toolBar.isPlayerCheckBox.selected = character.isPlayer;
	}
	
	function fillAnimationFields(?animationName:String)
	{
		var anim:Null<AnimationInfo> = null;
		
		if (animationName != null)
		{
			for (i in character.animations)
			{
				if (i.anim == animationName)
				{
					anim = i;
					break;
				}
			}
		}
		
		final animName = anim?.anim ?? '';
		final prefix = anim?.name ?? '';
		final indices = anim?.indices ?? [];
		final loops = anim?.loop ?? false;
		final framerate = anim?.fps ?? 24;
		
		final flipX = anim?.flipX ?? false;
		final flipY = anim?.flipY ?? false;
		
		uiElements.characterDialogBox.animationNameTextField.value = animName;
		uiElements.characterDialogBox.animationPrefixTextField.value = prefix;
		uiElements.characterDialogBox.animationIndicesTextField.value = (indices.length > 0 ? indices.join(',') : '');
		uiElements.characterDialogBox.animationLoopCheckbox.value = loops;
		uiElements.characterDialogBox.animationFramerateStepper.value = framerate;
		
		uiElements.characterDialogBox.flipXAnimCheckbox.value = flipX;
		uiElements.characterDialogBox.flipYAnimCheckbox.value = flipY;
	}
	
	inline function dance()
	{
		if (character == null) return;
		
		character.debugMode = false;
		character.dance(true);
		character.debugMode = true;
		
		uiElements.animationList.animationList.selectItemBy((item) -> return item.id == character.getAnimName());
	}
	
	function updateAnimList()
	{
		if (character == null) return;
		
		final animListData:Array<DropDownItem> = [];
		final animDropdownData:Array<DropDownItem> = [];
		
		for (anim => offset in character.animOffsets)
		{
			animListData.push({id: anim, text: anim + ': $offset'});
			animDropdownData.push(ToolKitUtils.makeSimpleDropDownItem(anim));
		}
		
		uiElements.animationList.animationList.populateList(animListData);
		uiElements.characterDialogBox.animationsDropdown.populateList(animDropdownData);
		
		uiElements.animationList.animationList.dataSource.sort(null, ASCENDING);
		uiElements.characterDialogBox.animationsDropdown.dataSource.sort(null, ASCENDING);
	}
	
	// used to update the image file
	function reloadCharacter()
	{
		//
		final lastAnim = character.getAnimName();
		final oldAnims = character.animations.copy();
		
		character.imageFile = uiElements.characterDialogBox.imageFileTextField.value;
		
		character.loadAtlas(character.imageFile);
		
		for (anim in oldAnims)
		{
			final animAnim:String = anim.anim;
			final animName:String = anim.name;
			final animFps:Int = anim.fps;
			final animLoop:Bool = !!anim.loop;
			final animIndices:Array<Int> = anim.indices;
			final flipX:Bool = anim.flipX ?? false;
			final flipY:Bool = anim.flipY ?? false;
			
			addAnim(animAnim, animName, animFps, animLoop, animIndices, flipX, flipY);
		}
		
		if (lastAnim.length != 0 && character.hasAnim(lastAnim)) character.playAnim(lastAnim);
		else dance();
		
		updateAnimList();
	}
	
	function addAnim(name:String, prefix:String, fps:Int, loops:Bool, ?indices:Array<Int>, flipX:Bool = false, flipY:Bool = false)
	{
		if (character == null) return;
		
		if (indices != null && indices.length != 0) character.addAnimByIndices(name, prefix, indices, fps, loops, flipX, flipY);
		else character.addAnimByPrefix(name, prefix, fps, loops, flipX, flipY);
		
		if (!character.hasAnim(name)) character.addOffset(name, 0, 0);
	}
	
	function spawnCharacter(reload:Bool = false)
	{
		inline function tryToPredictisOpp(name:String)
		{
			return (name != 'bf' && !name.startsWith('bf-') && !name.endsWith('-player') && !name.endsWith('-playable') && !name.endsWith('-dead'))
				|| name.endsWith('-opponent')
				|| name.startsWith('gf-')
				|| name.endsWith('-gf')
				|| name == 'gf';
		}
		
		final isPlayer = (reload ? character.isPlayer : !tryToPredictisOpp(characterId));
		
		if (character == null)
		{
			character = new Character(characterId, isPlayer);
			charLayer.add(character);
			character.debugMode = true;
		}
		else
		{
			character.isPlayer = isPlayer;
			
			final file = CharacterParser.fetchInfo(characterId);
			character.loadFile(file);
		}
		
		if (!reload && character.isPlayerInEditor != null && isPlayer != character.isPlayerInEditor)
		{
			character.isPlayer = !character.isPlayer;
			character.flipX = (character.originalFlipX != character.isPlayer);
			
			uiElements.toolBar.isPlayerCheckBox.value = character.isPlayer;
		}
		
		character.alternatingDance = null;
		
		positionCharacter();
		
		updateAnimList();
		updateDialogBox();
		
		FlxTimer.wait(0, dance); // this is bandaid fix do a real one later
	}
	
	inline function positionCharacter()
	{
		if (character == null) return;
		
		final pos = character.isPlayer ? bfPos : dadPos;
		
		character.x = pos.x + character.positionArray[0];
		character.y = pos.y + character.positionArray[1];
	}
	
	inline function positionPointer()
	{
		if (character == null) return;
		
		final midPoint = character.getMidpoint();
		
		var x:Float = midPoint.x;
		var y:Float = midPoint.y;
		if (!character.isPlayer)
		{
			x += 100 + character.cameraPosition[0];
		}
		else
		{
			x -= 100 + character.cameraPosition[0];
		}
		y += -100 + character.cameraPosition[1];
		
		x -= cameraPointer.width / 2;
		y -= cameraPointer.height / 2;
		cameraPointer.setPosition(x, y);
		
		// i should be doing this right ?
		midPoint.put();
	}
	
	function spawnGhost()
	{
		if (character == null) return;
		
		if (characterGhost == null)
		{
			characterGhost = new Character(characterId, character.isPlayer);
			
			charLayer.insert(0, characterGhost);
			characterGhost.debugMode = true;
		}
		
		characterGhost.loadAtlas(character.imageFile);
		
		inline function addGhostAnim(name:String, prefix:String, fps:Int, loops:Bool, ?indices:Array<Int>, ?flipX:Bool, ?flipY:Bool)
		{
			flipX ??= false;
			flipY ??= false;
			if (indices != null && indices.length != 0) characterGhost.addAnimByIndices(name, prefix, indices, fps, loops, flipX, flipY);
			else characterGhost.addAnimByPrefix(name, prefix, fps, loops, flipX, flipY);
			
			if (!characterGhost.hasAnim(name)) characterGhost.addOffset(name, 0, 0);
		}
		
		for (i in character.animations)
		{
			addGhostAnim(i.anim, i.name, i.fps, i.loop, i.indices, i.flipX, i.flipY);
		}
		
		characterGhost.x = character.x;
		characterGhost.y = character.y;
		
		characterGhost.scale.copyFrom(character.scale);
		
		characterGhost.flipX = character.flipX;
		
		// this part isnt final...
		characterGhost.playAnim(character.getAnimName());
		characterGhost.pauseAnim();
		characterGhost.animCurFrame = character.animCurFrame;
		
		characterGhost.offset.copyFrom(character.offset);
		
		characterGhost.alpha = uiElements.toolBar.ghostAlphaSlider.value;
		updateGhostLayering();
		// copy highlight
		
		final offset = uiElements.toolBar.ghostBlend.value ? 125 : 0;
		
		characterGhost.colorTransform.redOffset = offset;
		characterGhost.colorTransform.greenOffset = offset;
		characterGhost.colorTransform.blueOffset = offset;
	}
	
	function updateGhostLayering()
	{
		if (characterGhost != null)
		{
			characterGhost.zIndex = uiElements.toolBar.ghostInFront.value ? 10 : -1;
		}
		
		charLayer.sort(SortUtil.sortByZ, flixel.util.FlxSort.ASCENDING);
	}
	
	var fileRef = new FileReferenceEx();
	
	function saveCharToFile()
	{
		final json =
			{
				"animations": character.animations,
				"image": character.imageFile,
				"scale": character.jsonScale,
				"sing_duration": character.singDuration,
				"healthicon": character.healthIcon,
				"position": character.positionArray,
				"camera_position": character.cameraPosition,
				"flip_x": character.originalFlipX,
				"no_antialiasing": character.noAntialiasing,
				"healthbar_colour": character.healthColour,
				"scalableOffsets": character.scalableOffsets,
				"dance_every": character.danceEveryNumBeats,
				"_editor_isPlayer": character.isPlayer,
				
				"gameover_character": character.gameoverCharacter,
				"gameover_intial_sound": character.gameoverInitialDeathSound,
				"gameover_loop_sound": character.gameoverLoopDeathSound,
				"gameover_confirm_sound": character.gameoverConfirmDeathSound
			};
			
		final dataToSave:String = Json.stringify(json, "\t");
		
		if (dataToSave.length > 0)
		{
			fileRef.onFileSave = (path) -> {
				final char = path.withoutDirectory().withoutExtension();
				ToolKitUtils.makeNotification('Character File Saving', 'Character ($char) was successfully saved.', Success);
				FlxG.sound.play(Paths.sound('ui/success'));
			};
			fileRef.onFileCancel = () -> {
				ToolKitUtils.makeNotification('Character File Saving', 'Character saving was canceled.', Warning);
				FlxG.sound.play(Paths.sound('ui/warn'));
			};
			
			fileRef.save(dataToSave, '$characterId.json');
		}
	}
	
	override function destroy()
	{
		fileRef?.destroy();
		super.destroy();
	}
	
	final templateCharacterFile:CharacterInfo =
		{
			animations: [
				{
					loop: false,
					offsets: [
						0,
						0
					],
					fps: 24,
					anim: "idle",
					indices: [],
					name: "Dad idle dance"
				},
				{
					offsets: [
						0,
						0
					],
					indices: [],
					fps: 24,
					anim: "singLEFT",
					loop: false,
					name: "Dad Sing Note LEFT"
				},
				{
					offsets: [
						0,
						0
					],
					indices: [],
					fps: 24,
					anim: "singDOWN",
					loop: false,
					name: "Dad Sing Note DOWN"
				},
				{
					offsets: [
						0,
						0
					],
					indices: [],
					fps: 24,
					anim: "singUP",
					loop: false,
					name: "Dad Sing Note UP"
				},
				{
					offsets: [
						0,
						0
					],
					indices: [],
					fps: 24,
					anim: "singRIGHT",
					loop: false,
					name: "Dad Sing Note RIGHT"
				}
			],
			no_antialiasing: false,
			image: "characters/DADDY_DEAREST",
			position: [
				0,
				0
			],
			healthicon: "face",
			flip_x: false,
			healthbar_colour: FlxColor.GRAY,
			camera_position: [
				0,
				0
			],
			sing_duration: 6.1,
			scale: 1,
			dance_every: 2,
			scalableOffsets: true
		};
}
