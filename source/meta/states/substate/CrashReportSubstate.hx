package meta.states.substate;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import meta.data.*;
import meta.states.*;
import gameObjects.Alphabet;
import meta.data.*;

class CrashReportSubstate extends FlxState {
	var underText:FlxText;
    public var error:String;
    public var errorName:String;

	public function new(prevState:FlxState, error:String, errorName:String):Void {
        this.error = error;
        this.errorName = errorName;
        super();
	}

    override public function create(){
        super.create();

        FlxG.state.persistentUpdate = false;
		FlxG.state.persistentDraw = true;
		
        var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
		bg.scrollFactor.set();
		bg.alpha = 0;
		bg.loadGraphic(Paths.image("uhoh"));
		bg.setGraphicSize(1280, 720);
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		var coolText:Alphabet = new Alphabet(0, 32, "UNCATCHABLE ERROR", true);
		coolText.screenCenter(X);
		coolText.color = flixel.util.FlxColor.RED;
		add(coolText);

		var formattedErrorMessage:String = 'Your game has crashed! \nError caught: ${errorName}\n\n${error}\n\nPlease report this error to duskiewhy on discord (if unmodified hit single use)';

		var report:FlxText = new FlxText(0, 0, FlxG.width / 1.5, formattedErrorMessage);
		report.setFormat(Paths.font('vcr.ttf'), 32, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		report.screenCenter(XY);
		report.borderSize = 1.5;
		add(report);

		underText = new FlxText(0, FlxG.height - 64, FlxG.width, "Press SPACE to return to the Menu Screen.");
		underText.setFormat(Paths.font('vcr.ttf'), 24, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		underText.y = FlxG.height - underText.height - 16;
		underText.borderSize = 1;
		underText.screenCenter(X);
		add(underText);

		FlxTween.tween(bg, {alpha: 0.6}, 0.6, {ease: FlxEase.cubeOut});

		this.camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
    }

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE){
			Init.SwitchToPrimaryMenu();
        }
	}
}