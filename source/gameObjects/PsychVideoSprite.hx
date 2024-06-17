package gameObjects;


//data play
class PsychVideoSprite extends FlxVideoSprite
{
    public static var heldVideos:Array<PsychVideoSprite> = [];

    //these are loading options that are just easier to understand lol
    public static final looping:String = ':input-repeat=65535';
    public static final muted:String = ':no-audio';

    public var destroyOnUse:Bool = false;

    var _heldVideoPath:String = '';

    public function new(destroyOnUse = true) {
        super();
        heldVideos.push(this);

        this.destroyOnUse = destroyOnUse;
        if (destroyOnUse) bitmap.onEndReached.add(() -> destroy());
    }

    public override function load(location:String, ?options:Array<String>):Bool
    {
        var b:Bool = super.load(location,options);
        if (!b) return b;

        _heldVideoPath = location;

        if (FlxG.autoPause) 
        {
            //we dont want these signals due to us using our own setup
            if (FlxG.signals.focusGained.has(resume)) FlxG.signals.focusGained.remove(resume);
            if (FlxG.signals.focusLost.has(pause)) FlxG.signals.focusLost.remove(pause);

            if (!FlxG.signals.focusGained.has(bitmap.resume)) FlxG.signals.focusGained.add(bitmap.resume);
            if (!FlxG.signals.focusLost.has(bitmap.pause)) FlxG.signals.focusLost.add(bitmap.pause);
        }
        
        return b;
    }

    public override function pause() {

        super.pause();
        if (FlxG.autoPause) 
        {
            if (FlxG.signals.focusGained.has(bitmap.resume)) FlxG.signals.focusGained.remove(bitmap.resume);
            if (FlxG.signals.focusLost.has(bitmap.pause)) FlxG.signals.focusLost.remove(bitmap.pause);
        }
    }

    public override function resume() {

        super.resume();
        if (FlxG.autoPause) 
        {
            if (!FlxG.signals.focusGained.has(bitmap.resume)) FlxG.signals.focusGained.add(bitmap.resume);
            if (!FlxG.signals.focusLost.has(bitmap.pause)) FlxG.signals.focusLost.add(bitmap.pause);
        }
    }

    //maybe temp?
    public function addCallback(vidCallBack:String,func:Void->Void) {
        switch (vidCallBack) {
            case 'onEnd':
                if (func != null) bitmap.onEndReached.add(func);
            case 'onStart':
                if (func != null) bitmap.onOpening.add(func);
            case 'onFormat':
                if (func != null) bitmap.onFormatSetup.add(func);
        }
    }

    public override function destroy() {
        
        heldVideos.remove(this);
        super.destroy();
    }

    public function restart(?options:Array<String>) 
    {
        load(_heldVideoPath, options);
        play();
    }

    //not done todo
    public function initializeSkip() {
        
    }

    public static function globalPause() {
        for (i in heldVideos) i.pause();
    }

    public static function globalResume() {
        for (i in heldVideos) i.resume();
    }

}


enum abstract VidCallbacks(String) to String from String {
    public var ONEND:String = 'onEnd';
    public var ONSTART:String = 'onStart';
    public var ONFORMAT:String = 'onFormat';
}