package funkin.states.editors;

import funkin.backend.Discord;
import funkin.backend.Discord.DiscordClient;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.ui.FlxButton;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileFilter;
import haxe.Json;
import funkin.data.*;
import funkin.data.scripts.*;
import funkin.objects.*;
import funkin.objects.MenuCharacter.MenuCharacterFile;
#if sys
import sys.io.File;
#end

class HScriptState extends MusicBeatState
{
    var script:FunkinHScript;
    public var instance:HScriptState;

    public function new(script){
        script.call('onLoad', []);
        script.set('script', script);

        this.script = script;

        super();
    }

	override function add(Object:FlxBasic):FlxBasic {
		return super.add(Object);
	}

    override function create()
    {
        instance = this;
        script.set('add', instance.add);

        script.call('create', []);

        super.create();

        script.call('onCreatePost', []);
    }

    override public function update(elapsed:Float)
    {
        script.call('update', [elapsed]);

        super.update(elapsed);

        script.call('onUpdatePost', [elapsed]);
    }

    override public function stepHit(){
        script.call('stepHit', [curStep, curDecStep]);

        super.stepHit();

        script.call('onStepHitPost', [curStep, curDecStep]);
    }

    override public function beatHit(){
        script.call('beatHit', [curBeat, curDecBeat]);

        super.beatHit();

        script.call('onBeatHitPost', [curBeat, curDecBeat]);
    }

    override function destroy() {
        script.call('onDestroy', []);
        script.stop();

        super.destroy();
    }
}