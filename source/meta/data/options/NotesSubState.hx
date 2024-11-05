package meta.data.options;

import meta.states.substate.MusicBeatSubstate;
import gameObjects.shader.HSLColorSwap;
import gameObjects.AttachedText;
import gameObjects.Alphabet;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.group.FlxGroup.FlxTypedGroup;

class NotesSubState extends MusicBeatSubstate
{
	var curSelected:Int = 0;
	var typeSelected:Int = 0;
	var curValue:Float = 0;
	var holdTime:Float = 0;
	var nextAccept:Int = 5;
	var changingNote:Bool = false;

	private var grpNumbers:FlxTypedGroup<Alphabet>;
	private var grpNotes:FlxTypedGroup<FlxSprite>;
	private var shaderArray:Array<HSLColorSwap> = [];
	
	var blackBG:FlxSprite;
	var hsbText:Alphabet;

	var posX = 230;

	////
	var valuesArray:Array<Array<Int>>; 
	var namesArray:Array<String>;
	var noteFrames:FlxFramesCollection; 
	var noteAnimations:Array<String>;
	var defaults:Array<Array<Int>>;

	public function new() {
		super();

		switch(ClientPrefs.noteSkin) {
			default:
				valuesArray = ClientPrefs.arrowHSV;
				noteFrames = Paths.getSparrowAtlas('NOTE_assets');
				noteAnimations = ['purple0', 'blue0', 'green0', 'red0'];
				namesArray = ["Left", "Down", "Up", "Right"];
				defaults = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];

			case "Quants":
				valuesArray = ClientPrefs.quantHSV;
				noteFrames = Paths.getSparrowAtlas('QUANTNOTE_assets');
				noteAnimations = ['purple0', 'blue0', 'green0', 'red0'];
				namesArray = [
					"4th",
					"8th",
					"12th",
					"16th",
					"20th",
					"24th",
					"32nd",
					"48th",
					"64th",
					"96th",
					"192nd"
				];
				defaults = [
					[0, -20, 0], // 4th
					[-130, -20, 0], // 8th
					[-80, -20, 0], // 12th
					[128, -30, 0], // 16th
					[-120, -70, -35], // 20th
					[-80, -20, 0], // 24th
					[50, -20, 0], // 32nd
					[-80, -20, 0], // 48th
					[160, -15, 0], // 64th
					[-120, -70, -35], // 96th
					[-120, -70, -35]// 192nd
				];

			case "QuantStep":
				valuesArray = ClientPrefs.quantStepmania;
				noteFrames = Paths.getSparrowAtlas('QUANTNOTE_assets');
				noteAnimations = ['purple0', 'blue0', 'green0', 'red0'];
				namesArray = [
					"4th",
					"8th",
					"12th",
					"16th",
					"20th",
					"24th",
					"32nd",
					"48th",
					"64th",
					"96th",
					"192nd"
				];
				defaults = [
					[10, -20, 0], // 4th
					[-110, -40, 0], // 8th
					[140, -20, 0], // 12th
					[50, 25, 0], // 16th
					[0, -100, -50], // 20th
					[-80, -40, 0], // 24th
					[-180, 10, -10], // 32nd
					[-35, 50, 30], // 48th
					[160, -15, 0], // 64th
					[-120, -70, -35], // 96th
					[-120, -70, -35]// 192nd
				];
		}
	}

	override public function create() {
		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		blackBG = new FlxSprite(posX - 25).makeGraphic(870, 200, 0xFF000000);
		blackBG.alpha = 0.4;
		add(blackBG);

		grpNotes = new FlxTypedGroup<FlxSprite>();
		add(grpNotes);
		grpNumbers = new FlxTypedGroup<Alphabet>();
		add(grpNumbers);
		
		////
		for (i in 0...valuesArray.length) {
			var yPos:Float = (165 * i) + 35;
			for (j in 0...3) {
				var roundedValue:Int = Math.round(valuesArray[i][j]);

				var optionText:Alphabet = new Alphabet(0, yPos + 60, Std.string(roundedValue), true);
				optionText.x = posX + (225 * j) + 250;
				optionText.offset.x = (40 * (optionText.lettersArray.length - 1)) * 0.5;
				if (roundedValue < 0) optionText.offset.x += 10;
				
				grpNumbers.add(optionText);
			}

			var note:FlxSprite = new FlxSprite(posX, yPos);
			note.frames = noteFrames;
			note.animation.addByPrefix('idle', noteAnimations[i % 4]);
			note.animation.play('idle');
			note.antialiasing = ClientPrefs.globalAntialiasing;
			grpNotes.add(note);

			var txt:AttachedText = new AttachedText(namesArray[i], 0, 0, true);
			txt.sprTracker = note;
			txt.copyAlpha = true;
			add(txt);

			var newShader:HSLColorSwap = new HSLColorSwap();
			newShader.hue = valuesArray[i][0] / 360;
			newShader.saturation = valuesArray[i][1] / 100;
			newShader.lightness  = valuesArray[i][2] / 100;
			shaderArray.push(newShader);
			note.shader = newShader.shader;
		}

		hsbText = new Alphabet(0, 0, "Hue    Saturation  Luminosity", false, false, 0, 0.65);
		hsbText.x = posX + 240;
		add(hsbText);
		
		////
		changeSelection();
		super.create();
	}

	function menuUpdate(elapsed:Float) {
		if(changingNote) {
			if(holdTime < 0.5) {
				if(controls.UI_LEFT_P) {
					changeValue(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.UI_RIGHT_P) {
					changeValue(1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.RESET) {
					resetValue(curSelected, typeSelected);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					holdTime = 0;
				} else if(controls.UI_LEFT || controls.UI_RIGHT) {
					holdTime += elapsed;
				}
			} else {
				var add:Float = 90;
				switch(typeSelected) {
					case 1 | 2: add = 50;
				}
				if(controls.UI_LEFT) {
					changeValue(elapsed * -add);
				} else if(controls.UI_RIGHT) {
					changeValue(elapsed * add);
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					FlxG.sound.play(Paths.sound('scrollMenu'));
					holdTime = 0;
				}
			}
		} else {
			if (controls.UI_UP_P) {
				changeSelection(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_DOWN_P) {
				changeSelection(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_LEFT_P) {
				changeType(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_RIGHT_P) {
				changeType(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if(controls.RESET) {
				for (i in 0...3) {
					resetValue(curSelected, i);
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.ACCEPT && nextAccept <= 0) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changingNote = true;
				holdTime = 0;
				for (i in 0...grpNumbers.length) {
					var item = grpNumbers.members[i];
					item.alpha = 0;
					if ((curSelected * 3) + typeSelected == i) {
						item.alpha = 1;
					}
				}
				for (i in 0...grpNotes.length) {
					var item = grpNotes.members[i];
					item.alpha = 0;
					if (curSelected == i) {
						item.alpha = 1;
					}
				}
				return;
			}
		}

		if (controls.BACK || (changingNote && controls.ACCEPT)) {
			if(!changingNote) {
				close();
			} else {
				changeSelection();
			}
			changingNote = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}

		for (i in 0...grpNotes.length)
		{
			var yIndex = i;
			var item = grpNotes.members[i];
			if (curSelected > 2 && valuesArray.length > 4)
				yIndex -= curSelected - 2;

			var yPos:Float = (165 * yIndex) + 35;
			var lerpVal:Float = (1 - Math.exp(-48 * elapsed));

			item.y += (yPos - item.y) * lerpVal;

			if (i == curSelected){
				hsbText.y += (yPos-70 - hsbText.y) * lerpVal;
				blackBG.y += (yPos-20 - blackBG.y) * lerpVal;
			}
		}

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.y = grpNotes.members[Math.floor(i/3)].y + 60;
		}
	}

	override function update(elapsed:Float) {
		menuUpdate(elapsed);
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = valuesArray.length-1;
		if (curSelected > valuesArray.length-1)
			curSelected = 0;

		curValue = valuesArray[curSelected][typeSelected];
		changeValue();

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			item.alpha = 0.6;
			item.scale.set(0.75, 0.75);
			if (curSelected == i) {
				item.alpha = 1;
				item.scale.set(1, 1);
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeType(change:Int = 0) {
		typeSelected += change;
		if (typeSelected < 0)
			typeSelected = 2;
		if (typeSelected > 2)
			typeSelected = 0;

		curValue = valuesArray[curSelected][typeSelected];
		changeValue();

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}
	}

	function changeValue(change:Float = 0) {
		curValue += change;
		
		var max:Float = switch(typeSelected) {
			case 0: 180;
			default: 100;
		}

		if (curValue < -max)
			curValue = -max;
		if (curValue > max)
			curValue = max;

		updateValue(curSelected, typeSelected, curValue);
	}

	function updateValue(selected:Int, type:Int, value:Float) {
		var roundedValue = Math.round(value);

		var hsbArray = valuesArray[selected];
		hsbArray[type] = roundedValue;

		shaderArray[selected].hue = hsbArray[0] /360;
		shaderArray[selected].saturation = hsbArray[1] / 100;
		shaderArray[selected].lightness  = hsbArray[2] / 100;

		var item = grpNumbers.members[(selected * 3) + type];
		item.changeText(Std.string(roundedValue));
		item.offset.x = (40 * (item.lettersArray.length - 1)) / 2;
		if(roundedValue < 0) item.offset.x += 10;
	}

	function resetValue(selected:Int, type:Int) {
		curValue = defaults[selected][type];
		updateValue(selected, type, curValue);
	}
}
