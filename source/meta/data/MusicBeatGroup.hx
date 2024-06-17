package meta.data;

import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;

class MusicBeatGroup<T> extends FlxTypedGroup<FlxBasic> {

    private var curSection:Int = 0;

    private var stepsToDo:Int = 0;

    private var curStep:Int = 0;
    private var curBeat:Int = 0;

    private var curDecStep:Float = 0.0;
    private var curDecBeat:Float = 0.0;

    private var controls(get, never):Controls;

    inline function get_controls():Controls
        return PlayerSettings.player1.controls;

    override function new() {
        super();
    }

    override function update(elapsed:Float) {
        var oldStep = curStep; //$type(oldStep) == Int;

        updateStep();
        updateBeat();

        if (oldStep != curStep) {
            if (curStep > 0) stepHit();
        }

        super.update(elapsed);
    }

    private function updateBeat():Void {
        curBeat = Math.floor(curStep / 4);
        curDecBeat = curDecStep/4;
    }
    
    private function updateStep():Void {
        var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
    
        var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrotchet;
        curDecStep = lastChange.stepTime + shit;
        curStep = lastChange.stepTime + Math.floor(shit);
    }

    public function stepHit():Void {
        if (curStep % 4 == 0)
            beatHit();
    }
    
    public function beatHit():Void { }

    override function add(v:FlxBasic):FlxBasic {
        if (Std.isOfType(v, FlxSprite)) cast(v, FlxSprite).antialiasing = ClientPrefs.globalAntialiasing;
        return super.add(v);
    }
}