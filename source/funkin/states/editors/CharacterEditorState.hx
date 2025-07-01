package funkin.states.editors;

import haxe.Json;

import lime.system.Clipboard;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.ui.FlxButton;
import flixel.animation.FlxAnimation;

import funkin.objects.*;
import funkin.objects.character.Character;
import funkin.objects.character.*;
import funkin.objects.character.CharacterBuilder.CharacterFile;

@:bitmap("assets/images/debugger/cursorCross.png")
class Crosshair extends openfl.display.BitmapData {}

/**
	*DEBUG MODE
 */
class CharacterEditorState extends MusicBeatState
{
	var char:Character;
	var ghostChar:Character;
	var charAtlas:Character;
	var ghostCharAtlas:Character;
	var curChar:Character;
	var curGhost:Character;

	var textAnim:FlxText;
	var bgLayer:FlxTypedGroup<FlxSprite>;
	var charLayer:FlxTypedGroup<Character>;
	var dumbTexts:FlxTypedGroup<FlxText>;
	
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var goToPlayState:Bool = true;
	var camFollow:FlxObject;
	
	public function new(daAnim:String = 'spooky', goToPlayState:Bool = true)
	{
		super();
		this.daAnim = daAnim;
		this.goToPlayState = goToPlayState;
	}
	
	var UI_box:FlxUITabMenu;
	var UI_characterbox:FlxUITabMenu;
	
	var camEditor:FlxCamera;
	var camHUD:FlxCamera;
	var camMenu:FlxCamera;
	
	var leHealthIcon:HealthIcon;
	var characterList:Array<String> = [];
	
	var cameraFollowPointer:FlxSprite;
	var healthBarBG:FlxSprite;
	
	var healthBar:Bar;
	
	override function create()
	{
		FlxG.cameras.reset(camEditor = new FlxCamera());
		camHUD = new FlxCamera();
		camHUD.bgColor = 0x0;
		camMenu = new FlxCamera();
		camMenu.bgColor = 0x0;
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);
		
		bgLayer = new FlxTypedGroup<FlxSprite>();
		add(bgLayer);
		charLayer = new FlxTypedGroup<Character>();
		add(charLayer);
		
		cameraFollowPointer = new FlxSprite().loadGraphic(FlxGraphic.fromClass(Crosshair));
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;
		add(cameraFollowPointer);
		
		loadChar(!daAnim.startsWith('bf'), false);
		
		healthBar = new Bar(30, FlxG.height - 75);
		healthBar.scrollFactor.set();
		add(healthBar);
		healthBar.cameras = [camHUD];
		
		leHealthIcon = new HealthIcon(curChar.healthIcon, false);
		leHealthIcon.y = FlxG.height - 150;
		add(leHealthIcon);
		leHealthIcon.cameras = [camHUD];
		
		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);
		dumbTexts.cameras = [camHUD];
		
		textAnim = new FlxText(300, 16);
		textAnim.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		textAnim.borderSize = 1;
		textAnim.size = 32;
		textAnim.scrollFactor.set();
		textAnim.cameras = [camHUD];
		add(textAnim);
		
		genBoyOffsets();
		
		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);
		
		final tipTextArray:Array<String> = "E/Q - Camera Zoom In/Out
		\nR - Reset Camera Zoom
		\nJKLI - Move Camera
		\nW/S - Previous/Next Animation
		\nSpace - Play Animation
		\nArrow Keys - Move Character Offset
		\nT - Reset Current Offset
		\nHold Shift to Move 10x faster\n".split('\n');
		
		for (i in 0...tipTextArray.length - 1)
		{
			var tipText:FlxText = new FlxText(FlxG.width - 320, FlxG.height - 15 - 16 * (tipTextArray.length - i), 300, tipTextArray[i], 12);
			tipText.cameras = [camHUD];
			tipText.setFormat(null, 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
			tipText.scrollFactor.set();
			tipText.borderSize = 1;
			add(tipText);
		}
		
		FlxG.camera.follow(camFollow);
		
		var tabs = [
			{name: 'Settings', label: 'Settings'},
		];
		
		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camMenu];
		
		UI_box.resize(250, 120);
		UI_box.x = FlxG.width - 275;
		UI_box.y = 25;
		UI_box.scrollFactor.set();
		
		var tabs = [
			{name: 'Character', label: 'Character'},
			{name: 'Animations', label: 'Animations'},
		];
		UI_characterbox = new FlxUITabMenu(null, tabs, true);
		UI_characterbox.cameras = [camMenu];
		
		UI_characterbox.resize(400, 250);
		UI_characterbox.x = UI_box.x - 150;
		UI_characterbox.y = UI_box.y + UI_box.height;
		UI_characterbox.scrollFactor.set();
		add(UI_characterbox);
		add(UI_box);
		
		addSettingsUI();
		
		addCharacterUI();
		addAnimationsUI();
		UI_characterbox.selected_tab_id = 'Character';
		
		FlxG.mouse.visible = true;
		reloadCharacterOptions();
		
		super.create();
	}
	
	var onPixelBG:Bool = false;
	var OFFSET_X:Float = 300;
	
	function reloadBGs()
	{
		var i:Int = bgLayer.members.length - 1;
		while (i >= 0)
		{
			var memb:FlxSprite = bgLayer.members[i];
			if (memb != null)
			{
				memb.kill();
				bgLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		bgLayer.clear();
		
		var playerXDifference = 0;
		if (curChar.isPlayer) playerXDifference = 670;
		
		var bg:BGSprite = new BGSprite('stageback', -600 + OFFSET_X - playerXDifference, -300, 0.9, 0.9);
		bgLayer.add(bg);
		
		var stageFront:BGSprite = new BGSprite('stagefront', -650 + OFFSET_X - playerXDifference, 500, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		bgLayer.add(stageFront);
	}
	
	final TemplateCharacter:String = '{
			"animations": [
				{
					"loop": false,
					"offsets": [
						0,
						0
					],
					"fps": 24,
					"anim": "idle",
					"indices": [],
					"name": "Dad idle dance"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singLEFT",
					"loop": false,
					"name": "Dad Sing Note LEFT"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singDOWN",
					"loop": false,
					"name": "Dad Sing Note DOWN"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singUP",
					"loop": false,
					"name": "Dad Sing Note UP"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singRIGHT",
					"loop": false,
					"name": "Dad Sing Note RIGHT"
				}
			],
			"no_antialiasing": false,
			"image": "characters/DADDY_DEAREST",
			"position": [
				0,
				0
			],
			"healthicon": "face",
			"flip_x": false,
			"healthbar_colors": [
				161,
				161,
				161
			],
			"camera_position": [
				0,
				0
			],
			"sing_duration": 6.1,
			"scale": 1
		}';
	
	var charDropDown:FlxUIDropDownMenuEx;
	
	function addSettingsUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Settings";
		
		var check_player = new FlxUICheckBox(10, 60, null, null, "Playable Character", 100);
		check_player.checked = daAnim.startsWith('bf');
		check_player.callback = function() {
			curChar.isPlayer = !curChar.isPlayer;
			curChar.flipX = !curChar.flipX;
			updatePointerPos();
			reloadBGs();
			curGhost.flipX = curChar.flipX;
		};
		
		charDropDown = new FlxUIDropDownMenuEx(10, 30, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(character:String) {
			daAnim = characterList[Std.parseInt(character)];
			check_player.checked = daAnim.startsWith('bf');
			loadChar(!check_player.checked);
			updatePresence();
			reloadCharacterDropDown();
		});
		charDropDown.selectedLabel = daAnim;
		reloadCharacterDropDown();
		
		var reloadCharacter:FlxButton = new FlxButton(140, 20, "Reload Char", function() {
			loadChar(!check_player.checked);
			reloadCharacterDropDown();
		});
		
		var templateCharacter:FlxButton = new FlxButton(140, 50, "Load Template", function() {
			var parsedJson:CharacterFile = cast Json.parse(TemplateCharacter);
			var characters:Array<Character> = [curChar, curGhost];
			for (character in characters)
			{
				character.animOffsets.clear();
				character.animationsArray = parsedJson.animations;
				for (anim in character.animationsArray)
				{
					character.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				}
				if (character.animationsArray[0] != null)
				{
					character.playAnim(character.animationsArray[0].anim, true);
				}
				
				character.singDuration = parsedJson.sing_duration;
				character.positionArray = parsedJson.position;
				character.cameraPosition = parsedJson.camera_position;
				
				character.imageFile = parsedJson.image;
				character.jsonScale = parsedJson.scale;
				character.noAntialiasing = parsedJson.no_antialiasing;
				character.originalFlipX = parsedJson.flip_x;
				character.healthIcon = parsedJson.healthicon;
				character.healthColorArray = parsedJson.healthbar_colors;
				character.setPosition(character.positionArray[0] + OFFSET_X + 100, character.positionArray[1]);
			}
			
			reloadCharacterImage();
			reloadCharacterDropDown();
			reloadCharacterOptions();
			resetHealthBarColor();
			updatePointerPos();
			genBoyOffsets();
		});
		templateCharacter.color = FlxColor.RED;
		templateCharacter.label.color = FlxColor.WHITE;
		
		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 0, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(charDropDown);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		UI_box.addGroup(tab_group);
	}
	
	var imageInputText:FlxUIInputText;
	var healthIconInputText:FlxUIInputText;
	
	var singDurationStepper:FlxUINumericStepper;
	var scaleStepper:FlxUINumericStepper;
	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;
	
	var flipXCheckBox:FlxUICheckBox;
	var noAntialiasingCheckBox:FlxUICheckBox;
	
	var healthColorStepperR:FlxUINumericStepper;
	var healthColorStepperG:FlxUINumericStepper;
	var healthColorStepperB:FlxUINumericStepper;
	
	function addCharacterUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Character";
		
		imageInputText = new extensions.FlxUIInputTextEx(15, 30, 200, 'characters/BOYFRIEND', 8);
		var reloadImage:FlxButton = new FlxButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function() {
			curChar.imageFile = imageInputText.text;
			reloadCharacterImage();
			if (!curChar.isAnimNull())
			{
				curChar.playAnim(curChar.getAnimName(), true);
			}
		});
		
		var decideIconColor:FlxButton = new FlxButton(reloadImage.x, reloadImage.y + 30, "Get Icon Color", function() {
			var coolColor = FlxColor.fromInt(CoolUtil.dominantColor(leHealthIcon));
			healthColorStepperR.value = coolColor.red;
			healthColorStepperG.value = coolColor.green;
			healthColorStepperB.value = coolColor.blue;
			getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperR, null);
			getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperG, null);
			getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperB, null);
		});
		
		healthIconInputText = new extensions.FlxUIInputTextEx(15, imageInputText.y + 35, 75, leHealthIcon.getCharacter(), 8);
		
		singDurationStepper = new FlxUINumericStepper(15, healthIconInputText.y + 45, 0.1, 4, 0, 999, 1);
		
		scaleStepper = new FlxUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 1);
		
		flipXCheckBox = new FlxUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, null, null, "Flip X", 50);
		flipXCheckBox.checked = curChar.flipX;
		if (curChar.isPlayer) flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.callback = function() {
			curChar.originalFlipX = !curChar.originalFlipX;
			curChar.flipX = curChar.originalFlipX;
			if (curChar.isPlayer) curChar.flipX = !curChar.flipX;
			
			curGhost.flipX = curChar.flipX;
		};
		
		noAntialiasingCheckBox = new FlxUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, null, null, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = curChar.noAntialiasing;
		noAntialiasingCheckBox.callback = function() {
			curChar.antialiasing = false;
			if (!noAntialiasingCheckBox.checked && ClientPrefs.globalAntialiasing)
			{
				curChar.antialiasing = true;
			}
			curChar.noAntialiasing = noAntialiasingCheckBox.checked;
			curGhost.antialiasing = curChar.antialiasing;
		};
		
		positionXStepper = new FlxUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, curChar.positionArray[0], -9000, 9000, 0);
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, curChar.positionArray[1], -9000, 9000, 0);
		
		positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, curChar.cameraPosition[0], -9000, 9000, 0);
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, curChar.cameraPosition[1], -9000, 9000, 0);
		
		var saveCharacterButton:FlxButton = new FlxButton(reloadImage.x, noAntialiasingCheckBox.y + 40, "Save Character", function() {
			saveCharacter();
		});
		
		healthColorStepperR = new FlxUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, curChar.healthColorArray[0], 0, 255, 0);
		healthColorStepperG = new FlxUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, curChar.healthColorArray[1], 0, 255, 0);
		healthColorStepperB = new FlxUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, curChar.healthColorArray[2], 0, 255, 0);
		
		tab_group.add(new FlxText(15, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 0, 'Health icon name:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 0, 'Sing Animation length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Camera X/Y:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 0, 'Health bar R/G/B:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(healthColorStepperR);
		tab_group.add(healthColorStepperG);
		tab_group.add(healthColorStepperB);
		tab_group.add(saveCharacterButton);
		UI_characterbox.addGroup(tab_group);
	}
	
	var ghostDropDown:FlxUIDropDownMenuEx;
	var animationDropDown:FlxUIDropDownMenuEx;
	var animationInputText:FlxUIInputText;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationNameFramerate:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;
	
	function addAnimationsUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Animations";
		
		animationInputText = new extensions.FlxUIInputTextEx(15, 85, 80, '', 8);
		animationNameInputText = new extensions.FlxUIInputTextEx(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new extensions.FlxUIInputTextEx(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationNameFramerate = new FlxUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new FlxUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, null, null, "Should it Loop?", 100);
		
		animationDropDown = new FlxUIDropDownMenuEx(15, animationInputText.y - 55, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(pressed:String) {
			var selectedAnimation:Int = Std.parseInt(pressed);
			var anim:AnimArray = curChar.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationNameFramerate.value = anim.fps;
			updatePointerPos();
			
			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});
		
		ghostDropDown = new FlxUIDropDownMenuEx(animationDropDown.x + 150, animationDropDown.y, FlxUIDropDownMenu.makeStrIdLabelArray([''], true), function(pressed:String) {
			var selectedAnimation:Int = Std.parseInt(pressed);
			curGhost.visible = false;
			curChar.alpha = 1;
			if (selectedAnimation > 0)
			{
				curGhost.visible = true;
				curGhost.playAnim(curGhost.animationsArray[selectedAnimation - 1].anim, true);
				curChar.alpha = 0.85;
			}
		});
		
		var addUpdateButton:FlxButton = new FlxButton(70, animationIndicesInputText.y + 30, "Add/Update", function() {
			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
			if (indicesStr.length > 1)
			{
				for (i in 0...indicesStr.length)
				{
					var index:Int = Std.parseInt(indicesStr[i]);
					if (indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1)
					{
						indices.push(index);
					}
				}
			}
			
			var lastAnim:String = '';
			if (curChar.animationsArray[curAnim] != null)
			{
				lastAnim = curChar.animationsArray[curAnim].anim;
			}
			
			var lastOffsets:Array<Int> = [0, 0];
			for (anim in curChar.animationsArray)
			{
				if (animationInputText.text == anim.anim)
				{
					lastOffsets = anim.offsets;
					if (curChar.animation.exists(animationInputText.text))
					{
						curChar.animation.remove(animationInputText.text);
					}
					curChar.animationsArray.remove(anim);
				}
			}
			
			var newAnim:AnimArray =
				{
					anim: animationInputText.text,
					name: animationNameInputText.text,
					fps: Math.round(animationNameFramerate.value),
					loop: animationLoopCheckBox.checked,
					indices: indices,
					offsets: lastOffsets,
				};
				
			if (indices != null && indices.length > 0)
			{
				curChar.animation.addByIndices(newAnim.anim, newAnim.name, newAnim.indices, "", newAnim.fps, newAnim.loop);
			}
			else
			{
				curChar.animation.addByPrefix(newAnim.anim, newAnim.name, newAnim.fps, newAnim.loop);
			}
			
			if (!curChar.animOffsets.exists(newAnim.anim))
			{
				curChar.addOffset(newAnim.anim, 0, 0);
			}
			curChar.animationsArray.push(newAnim);
			
			if (lastAnim == animationInputText.text)
			{
				var leAnim:FlxAnimation = curChar.getAnimByName(lastAnim);
				if (leAnim != null && leAnim.frames.length > 0)
				{
					curChar.playAnim(lastAnim, true);
				}
				else
				{
					for (i in 0...curChar.animationsArray.length)
					{
						if (curChar.animationsArray[i] != null)
						{
							leAnim = curChar.getAnimByName(curChar.animationsArray[i].anim);
							if (leAnim != null && leAnim.frames.length > 0)
							{
								curChar.playAnim(curChar.animationsArray[i].anim, true);
								curAnim = i;
								break;
							}
						}
					}
				}
			}
			
			reloadAnimationDropDown();
			genBoyOffsets();
			trace('Added/Updated animation: ' + animationInputText.text);
		});
		
		var removeButton:FlxButton = new FlxButton(180, animationIndicesInputText.y + 30, "Remove", function() {
			for (anim in curChar.animationsArray)
			{
				if (animationInputText.text == anim.anim)
				{
					var resetAnim:Bool = false;
					if (!curChar.isAnimNull() && anim.anim == curChar.getAnimName()) resetAnim = true;
					
					if (curChar.getAnimByName(anim.anim) != null)
					{
						curChar.animation.remove(anim.anim);
					}
					if (curChar.animOffsets.exists(anim.anim))
					{
						curChar.animOffsets.remove(anim.anim);
					}
					curChar.animationsArray.remove(anim);
					
					if (resetAnim && curChar.animationsArray.length > 0)
					{
						curChar.playAnim(curChar.animationsArray[0].anim, true);
					}
					reloadAnimationDropDown();
					genBoyOffsets();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
			}
		});
		
		// tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(ghostDropDown.x, ghostDropDown.y - 18, 0, 'Animation Ghost:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(animationNameFramerate.x, animationNameFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation on .XML/.TXT file:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));
		
		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationNameFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(ghostDropDown);
		tab_group.add(animationDropDown);
		
		updatePointerPos();
		UI_characterbox.addGroup(tab_group);
	}
	
	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == healthIconInputText)
			{
				leHealthIcon.changeIcon(healthIconInputText.text);
				curChar.healthIcon = healthIconInputText.text;
				updatePresence();
			}
			else if (sender == imageInputText)
			{
				curChar.imageFile = imageInputText.text;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			if (sender == scaleStepper)
			{
				reloadCharacterImage();
				curChar.jsonScale = sender.value;
				curChar.setGraphicSize(Std.int(curChar.width * curChar.jsonScale));
				curChar.updateHitbox();
				curGhost.setGraphicSize(Std.int(curGhost.width * curChar.jsonScale));
				curGhost.updateHitbox();
				reloadGhost();
				updatePointerPos();
				
				if (!curChar.isAnimNull())
				{
					curChar.playAnim(curChar.getAnimName(), true);
				}
			}
			else if (sender == positionXStepper)
			{
				curChar.positionArray[0] = positionXStepper.value;
				curChar.x = curChar.positionArray[0] + OFFSET_X + 100;
				updatePointerPos();
			}
			else if (sender == singDurationStepper)
			{
				curChar.singDuration = singDurationStepper.value; // ermm you forgot this??
			}
			else if (sender == positionYStepper)
			{
				curChar.positionArray[1] = positionYStepper.value;
				curChar.y = curChar.positionArray[1];
				updatePointerPos();
			}
			else if (sender == positionCameraXStepper)
			{
				curChar.cameraPosition[0] = positionCameraXStepper.value;
				updatePointerPos();
			}
			else if (sender == positionCameraYStepper)
			{
				curChar.cameraPosition[1] = positionCameraYStepper.value;
				updatePointerPos();
			}
			else if (sender == healthColorStepperR)
			{
				curChar.healthColorArray[0] = Math.round(healthColorStepperR.value);
				resetHealthBarColor();
			}
			else if (sender == healthColorStepperG)
			{
				curChar.healthColorArray[1] = Math.round(healthColorStepperG.value);
				resetHealthBarColor();
			}
			else if (sender == healthColorStepperB)
			{
				curChar.healthColorArray[2] = Math.round(healthColorStepperB.value);
				resetHealthBarColor();
			}
		}
	}
	
	function reloadCharacterImage()
	{
		var lastAnim:String = '';
		if (!curChar.isAnimNull()) lastAnim = curChar.getAnimName();
		var tex = imageInputText.text;
		
		if (Paths.fileExists('images/${curChar.imageFile}/Animation.json', TEXT))
		{
			if (curChar is AnimateCharacter) curChar.loadGraphicFromType(curChar.imageFile, 'atlas');
			else
			{
				char.visible = false;
				ghostChar.visible = false;
				
				ghostCharAtlas = new AnimateCharacter(0, 0, ghostChar.curCharacter, !ghostChar.isPlayer);
				ghostCharAtlas.loadGraphicFromType(tex, 'atlas');
				ghostCharAtlas.debugMode = true;
				ghostCharAtlas.alpha = 0.6;
				
				charAtlas = new AnimateCharacter(0, 0, char.curCharacter, !char.isPlayer);
				charAtlas.loadGraphicFromType(tex, 'atlas');
				if (charAtlas.animationsArray[0] != null)
				{
					charAtlas.playAnim(charAtlas.animationsArray[0].anim, true);
				}
				charAtlas.debugMode = true;
				
				charLayer.add(ghostCharAtlas);
				charLayer.add(charAtlas);
				
				curGhost = ghostCharAtlas;
				curChar = charAtlas;
			}
		}
		else
		{
			if (curChar is AnimateCharacter)
			{
				charAtlas.visible = false;
				ghostCharAtlas.visible = false;
				
				ghostChar = new Character(ghostCharAtlas.x, ghostCharAtlas.y, ghostCharAtlas.curCharacter, !ghostCharAtlas.isPlayer, true);
				ghostChar.skipJsonStuff = true;
				ghostChar.imageFile = tex;
				ghostChar.createNow();
				ghostChar.debugMode = true;
				ghostChar.alpha = 0.6;
				
				char = new Character(charAtlas.x, charAtlas.y, charAtlas.curCharacter, !charAtlas.isPlayer, true);
				char.skipJsonStuff = true;
				char.imageFile = tex;
				char.createNow();
				if (char.animationsArray[0] != null)
				{
					char.playAnim(char.animationsArray[0].anim, true);
				}
				char.debugMode = true;
				
				charLayer.add(ghostChar);
				charLayer.add(char);
				
				curGhost = ghostChar;
				curChar = char;
			}
			else
			{
				if (Paths.fileExists('images/' + curChar.imageFile + '.txt', TEXT)) curChar.frames = Paths.getPackerAtlas(curChar.imageFile);
				else curChar.frames = Paths.getMultiAtlas(curChar.imageFile.split(','));
			}
		}
		
		if (curChar.animationsArray != null && curChar.animationsArray.length > 0)
		{
			for (anim in curChar.animationsArray)
			{
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; // Bruh
				var animIndices:Array<Int> = anim.indices;
				if (animIndices != null && animIndices.length > 0)
				{
					curChar.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				}
				else
				{
					curChar.animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
			}
		}
		else
		{
			curChar.animation.addByPrefix('idle', 'BF idle dance', 24, false);
		}
		
		if (lastAnim != '')
		{
			curChar.playAnim(lastAnim, true);
		}
		else
		{
			curChar.dance();
		}
		ghostDropDown.selectedLabel = '';
		reloadGhost();
	}
	
	function genBoyOffsets():Void
	{
		var daLoop:Int = 0;
		
		var i:Int = dumbTexts.members.length - 1;
		while (i >= 0)
		{
			var memb:FlxText = dumbTexts.members[i];
			if (memb != null)
			{
				memb.kill();
				dumbTexts.remove(memb);
				memb.destroy();
			}
			--i;
		}
		dumbTexts.clear();
		
		for (anim => offsets in curChar.animOffsets)
		{
			var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, anim + ": " + offsets, 15);
			text.setFormat(null, 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1;
			dumbTexts.add(text);
			text.cameras = [camHUD];
			
			daLoop++;
		}
		
		textAnim.visible = true;
		if (dumbTexts.length < 1)
		{
			var text:FlxText = new FlxText(10, 38, 0, "ERROR! No animations found.", 15);
			text.scrollFactor.set();
			text.borderSize = 1;
			dumbTexts.add(text);
			textAnim.visible = false;
		}
	}
	
	function loadChar(isDad:Bool, blahBlahBlah:Bool = true)
	{
		var i:Int = charLayer.members.length - 1;
		while (i >= 0)
		{
			var memb:Dynamic = charLayer.members[i];
			if (memb != null)
			{
				memb.kill();
				charLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		charLayer.clear();
		final charFile = CharacterBuilder.getCharacterFile(daAnim);
		trace(FunkinAssets.exists(Paths.textureAtlas(charFile.image + '/Animation.json')));
		
		if (FunkinAssets.exists(Paths.textureAtlas(charFile.image + '/Animation.json')))
		{
			ghostCharAtlas = new AnimateCharacter(0, 0, daAnim, !isDad);
			ghostCharAtlas.debugMode = true;
			ghostCharAtlas.alpha = 0.6;
			
			charAtlas = new AnimateCharacter(0, 0, daAnim, !isDad);
			if (charAtlas.animationsArray[0] != null)
			{
				charAtlas.playAnim(charAtlas.animationsArray[0].anim, true);
			}
			charAtlas.debugMode = true;
			
			charLayer.add(ghostCharAtlas);
			charLayer.add(charAtlas);
			
			curGhost = ghostCharAtlas;
			curChar = charAtlas;
		}
		else
		{
			ghostChar = new Character(0, 0, daAnim, !isDad);
			ghostChar.debugMode = true;
			ghostChar.alpha = 0.6;
			
			char = new Character(0, 0, daAnim, !isDad);
			if (char.animationsArray[0] != null)
			{
				char.playAnim(char.animationsArray[0].anim, true);
			}
			char.debugMode = true;
			
			charLayer.add(ghostChar);
			charLayer.add(char);
			curGhost = ghostChar;
			curChar = char;
		}
		
		
		curChar.setPosition(curChar.positionArray[0] + OFFSET_X + 100, curChar.positionArray[1]);
		
		if (blahBlahBlah)
		{
			genBoyOffsets();
		}
		reloadCharacterOptions();
		reloadBGs();
		updatePointerPos();
	}

	
	function updatePointerPos()
	{
		var x:Float = curChar.getMidpoint().x;
		var y:Float = curChar.getMidpoint().y;
		if (!curChar.isPlayer)
		{
			x += 150 + curChar.cameraPosition[0];
		}
		else
		{
			x -= 100 + curChar.cameraPosition[0];
		}
		y -= 100 - curChar.cameraPosition[1];
		
		x -= cameraFollowPointer.width / 2;
		y -= cameraFollowPointer.height / 2;
		cameraFollowPointer.setPosition(x, y);
	}
	
	function findAnimationByName(name:String):AnimArray
	{
		for (anim in curChar.animationsArray)
		{
			if (anim.anim == name)
			{
				return anim;
			}
		}
		return null;
	}
	function changeType(type:String, file:String)
	{
		for (i in [char /*, ghostChar*/])
		{
			charLayer.remove(i);
			i = CharacterBuilder.changeTypeReload([i.x, i.y, i.curCharacter, i.isPlayer], type, file);
			charLayer.add(i);
		}
	}
	
	function reloadCharacterOptions()
	{
		if (UI_characterbox != null)
		{
			imageInputText.text = curChar.imageFile;
			healthIconInputText.text = curChar.healthIcon;
			singDurationStepper.value = curChar.singDuration;
			scaleStepper.value = curChar.jsonScale;
			flipXCheckBox.checked = curChar.originalFlipX;
			noAntialiasingCheckBox.checked = curChar.noAntialiasing;
			resetHealthBarColor();
			leHealthIcon.changeIcon(healthIconInputText.text);
			positionXStepper.value = curChar.positionArray[0];
			positionYStepper.value = curChar.positionArray[1];
			positionCameraXStepper.value = curChar.cameraPosition[0];
			positionCameraYStepper.value = curChar.cameraPosition[1];
			reloadAnimationDropDown();
			updatePresence();
		}
	}
	
	function reloadAnimationDropDown()
	{
		var anims:Array<String> = [];
		var ghostAnims:Array<String> = [''];
		for (anim in curChar.animationsArray)
		{
			anims.push(anim.anim);
			ghostAnims.push(anim.anim);
		}
		if (anims.length < 1) anims.push('NO ANIMATIONS'); // Prevents crash
		
		animationDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(anims, true));
		ghostDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(ghostAnims, true));
		reloadGhost();
	}
	
	function reloadGhost()
	{
		curGhost.frames = curChar.frames;
		for (anim in curChar.animationsArray)
		{
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; // Bruh
			var animIndices:Array<Int> = anim.indices;
			if (animIndices != null && animIndices.length > 0)
			{
				curGhost.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
			}
			else
			{
				curGhost.animation.addByPrefix(animAnim, animName, animFps, animLoop);
			}
			
			if (anim.offsets != null && anim.offsets.length > 1)
			{
				curGhost.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
			}
		}
		
		curChar.alpha = 0.85;
		curGhost.visible = true;
		if (ghostDropDown.selectedLabel == '')
		{
			curGhost.visible = false;
			curChar.alpha = 1;
		}
		curGhost.color = 0xFF666688;
		curGhost.antialiasing = curChar.antialiasing;
	}
	
	function reloadCharacterDropDown()
	{
		var charsLoaded:Map<String, Bool> = new Map();
		
		#if MODS_ALLOWED
		characterList = [];
		var directories:Array<String> = [
			Paths.mods('characters/'),
			Paths.mods(Mods.currentModDirectory + '/characters/'),
			Paths.getPrimaryPath('characters/')
		];
		for (mod in Mods.globalMods)
			directories.push(Paths.mods(mod + '/characters/'));
		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						var charToCheck:String = file.substr(0, file.length - 5);
						if (!charsLoaded.exists(charToCheck))
						{
							characterList.push(charToCheck);
							charsLoaded.set(charToCheck, true);
						}
					}
				}
			}
		}
		#else
		characterList = CoolUtil.coolTextFile(Paths.txt('characterList'));
		#end
		
		charDropDown.setData(FlxUIDropDownMenu.makeStrIdLabelArray(characterList, true));
		charDropDown.selectedLabel = daAnim;
	}
	
	function resetHealthBarColor()
	{
		healthColorStepperR.value = curChar.healthColorArray[0];
		healthColorStepperG.value = curChar.healthColorArray[1];
		healthColorStepperB.value = curChar.healthColorArray[2];
		healthBar.leftBar.color = healthBar.rightBar.color = FlxColor.fromRGB(curChar.healthColorArray[0], curChar.healthColorArray[1], curChar.healthColorArray[2]);
		
		// healthIcon.changeIcon(character.healthIcon, false);
		
		updatePresence();
	}
	
	function updatePresence()
	{
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + daAnim, leHealthIcon.getCharacter());
		#end
	}
	
	override function update(elapsed:Float)
	{
		if (curChar.animationsArray[curAnim] != null)
		{
			textAnim.text = curChar.animationsArray[curAnim].anim;
			
			var curAnim:FlxAnimation = curChar.getAnimByName(curChar.animationsArray[curAnim].anim);
			if (curAnim != null || curAnim != null && curAnim.frames.length < 1) textAnim.text += ' (ERROR!)';
		}
		else
		{
			textAnim.text = '';
		}
		
		var inputTexts:Array<FlxUIInputText> = [
			animationInputText,
			imageInputText,
			healthIconInputText,
			animationNameInputText,
			animationIndicesInputText
		];
		for (i in 0...inputTexts.length)
		{
			if (inputTexts[i].hasFocus)
			{
				// if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V && Clipboard.text != null)
				// { // Copy paste
				// 	inputTexts[i].text = ClipboardAdd(inputTexts[i].text);
				// 	inputTexts[i].caretIndex = inputTexts[i].text.length;
				// 	getEvent(FlxUIInputText.CHANGE_EVENT, inputTexts[i], null, []);
				// }
				if (FlxG.keys.justPressed.ENTER)
				{
					inputTexts[i].hasFocus = false;
				}
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				super.update(elapsed);
				return;
			}
		}
		FlxG.sound.muteKeys = Init.muteKeys;
		FlxG.sound.volumeDownKeys = Init.volumeDownKeys;
		FlxG.sound.volumeUpKeys = Init.volumeUpKeys;
		
		if (!charDropDown.dropPanel.visible)
		{
			if (FlxG.keys.justPressed.ESCAPE)
			{
				if (goToPlayState)
				{
					FlxG.switchState(PlayState.new);
				}
				else
				{
					FlxG.switchState(funkin.states.editors.MasterEditorMenu.new);
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
				FlxG.mouse.visible = false;
				return;
			}
			
			if (FlxG.keys.justPressed.R)
			{
				FlxG.camera.zoom = 1;
			}
			
			if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3)
			{
				FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
				if (FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
			}
			if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1)
			{
				FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
				if (FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
			}
			
			if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
			{
				var addToCam:Float = 500 * elapsed;
				if (FlxG.keys.pressed.SHIFT) addToCam *= 4;
				
				if (FlxG.keys.pressed.I) camFollow.y -= addToCam;
				else if (FlxG.keys.pressed.K) camFollow.y += addToCam;
				
				if (FlxG.keys.pressed.J) camFollow.x -= addToCam;
				else if (FlxG.keys.pressed.L) camFollow.x += addToCam;
			}
			
			if (curChar.animationsArray.length > 0)
			{
				if (FlxG.keys.justPressed.W)
				{
					curAnim -= 1;
				}
				
				if (FlxG.keys.justPressed.S)
				{
					curAnim += 1;
				}
				
				if (curAnim < 0) curAnim = curChar.animationsArray.length - 1;
				
				if (curAnim >= curChar.animationsArray.length) curAnim = 0;
				
				if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE)
				{
					curChar.playAnim(curChar.animationsArray[curAnim].anim, true);
					genBoyOffsets();
				}
				if (FlxG.keys.justPressed.T)
				{
					curChar.animationsArray[curAnim].offsets = [0, 0];
					
					curChar.addOffset(curChar.animationsArray[curAnim].anim, curChar.animationsArray[curAnim].offsets[0], curChar.animationsArray[curAnim].offsets[1]);
					curGhost.addOffset(curChar.animationsArray[curAnim].anim, curChar.animationsArray[curAnim].offsets[0], curChar.animationsArray[curAnim].offsets[1]);
					genBoyOffsets();
				}
				
				var controlArray:Array<Bool> = [
					FlxG.keys.justPressed.LEFT,
					FlxG.keys.justPressed.RIGHT,
					FlxG.keys.justPressed.UP,
					FlxG.keys.justPressed.DOWN
				];
				
				for (i in 0...controlArray.length)
				{
					if (controlArray[i])
					{
						var holdShift = FlxG.keys.pressed.SHIFT;
						var multiplier = 1;
						if (holdShift) multiplier = 10;
						
						var arrayVal = 0;
						if (i > 1) arrayVal = 1;
						
						var negaMult:Int = 1;
						if (i % 2 == 1) negaMult = -1;
						curChar.animationsArray[curAnim].offsets[arrayVal] += negaMult * multiplier;
						
						curChar.addOffset(curChar.animationsArray[curAnim].anim, curChar.animationsArray[curAnim].offsets[0], curChar.animationsArray[curAnim].offsets[1]);
						curGhost.addOffset(curChar.animationsArray[curAnim].anim, curChar.animationsArray[curAnim].offsets[0], curChar.animationsArray[curAnim].offsets[1]);
						
						curChar.playAnim(curChar.animationsArray[curAnim].anim, false);
						if (!curGhost.isAnimNull() && !curChar.isAnimNull() && curChar.getAnimName() == curGhost.animation.curAnim.name)
						{
							curGhost.playAnim(curChar.getAnimName(), false);
						}
						genBoyOffsets();
					}
				}
			}
		}
		curGhost.setPosition(curChar.x, curChar.y);
		super.update(elapsed);
	}
	
	var _file:FileReference;
	
	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
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
		FlxG.log.error("Problem saving file");
	}
	
	function saveCharacter()
	{
		var json =
			{
				"animations": curChar.animationsArray,
				"image": curChar.imageFile,
				"scale": curChar.jsonScale,
				"sing_duration": curChar.singDuration,
				"healthicon": curChar.healthIcon,
				
				"position": curChar.positionArray,
				"camera_position": curChar.cameraPosition,
				
				"flip_x": curChar.originalFlipX,
				"no_antialiasing": curChar.noAntialiasing,
				"healthbar_colors": curChar.healthColorArray
			};
			
		var data:String = Json.stringify(json, "\t");
		
		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, daAnim + ".json");
		}
	}
	
	function ClipboardAdd(prefix:String = ''):String
	{
		if (prefix.toLowerCase().endsWith('v')) // probably copy paste attempt
		{
			prefix = prefix.substring(0, prefix.length - 1);
		}
		
		var text:String = prefix + Clipboard.text.replace('\n', '');
		return text;
	}
}
