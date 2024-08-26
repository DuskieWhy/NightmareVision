package funkin.huds;


import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.FlxBasic;

@:access(funkin.states.PlayState)
class BaseHUD extends FlxTypedContainer<FlxBasic>
{
    public var parent:PlayState;

    public var curStep(get,never):Int;
    function get_curStep():Int return parent.curStep;

    public var curBeat(get,never):Int; 
    function get_curBeat():Int return parent.curBeat;

    public var curSection(get,never):Int;
    function get_curSection():Int return parent.curSection;
    
    //ignore this 
    public function new(parent:PlayState) {
        this.parent = parent;
        super();
        init();
    }


    public function init():Void {}
    public function onSongStart():Void {}

    public function stepHit():Void {}
    public function beatHit():Void {}
    public function sectionHit():Void {}

    public function onUpdateScore(data:ScoreData,missed:Bool = false):Void {}
    public function onEvent(ev:String,v1:String,v2:String,strumTime:Float):Void {}

    public function onCharacterChange() {}
    public function onHealthChange(health:Float) {}


    public function getVar(obj:String):Dynamic {
        return Reflect.getProperty(this,obj);
    }

    


}

//only used for huds so its here
typedef ScoreData = {
    score:Float,
    accuracy:Float,
    misses:Float,
} 