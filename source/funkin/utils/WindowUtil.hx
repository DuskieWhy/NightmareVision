package funkin.utils;

import flixel.util.FlxAxes;
import lime.app.Application;


//WIP 
//functions used to mess with some window properties for ease
class WindowUtil {

    public static var monitorResolutionWidth(get,never):Float;
    public static var monitorResolutionHeight(get,never):Float;
    static function get_monitorResolutionWidth():Float return openfl.system.Capabilities.screenResolutionX;
    static function get_monitorResolutionHeight():Float return openfl.system.Capabilities.screenResolutionY;

    public static var defaultAppTitle(get,never):String;
    static function get_defaultAppTitle():String return Application.current.meta['name'];
    
    public static function getWindow() 
    {
        return Application.current.window;
    }

    public static function setTitle(?arg:String,append:Bool = false) 
    {
        arg ??= defaultAppTitle;

        if (append)
            getWindow().title += arg;
        else 
            getWindow().title = arg;
        
    }



    static var _windowTween:FlxTween = null; 
    public static function tweenWindow(values:Dynamic,time:Float = 0.01,?options:TweenOptions,?fill = true) {
        _windowTween?.cancel();

        options ??= {}
        
		FlxG.scaleMode = new flixel.system.scaleModes.RatioScaleMode(fill);
		getWindow().resizable = !fill;

        _windowTween = FlxTween.tween(getWindow(),values,time,options);
    }

    public static function setWindowSize(width:Int,height:Int) {
        if (_windowTween !=null)
            FlxTween.cancelTweensOf(getWindow(),['width','height']);

        FlxG.resizeWindow(width,height);

    }


    // public static function getScreenCenterPos(axes:FlxAxes) {
    //     var x:Array<Float> = [];    //     if (axes.x && axes.y) return (x = [(monitorResolutionWidth/2) - (getWindow().width/2),(monitorResolutionHeight/2) - (getWindow().height/2)]);
    //     else if (axes.x) return (x = [(monitorResolutionWidth/2) - (getWindow().width/2)]); 
    //     else if (axes.y) return (x = [(monitorResolutionHeight/2) - (getWindow().height/2)]); 
    // }

    public static function TweenValueHelper(?x:Float, ?y:Float,?width:Float,?height:Float) {
        var values = {};
        return {'x': x, 'y': y, 'width': width, 'height': height};
    }

}
