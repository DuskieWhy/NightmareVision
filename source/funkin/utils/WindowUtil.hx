package funkin.utils;

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
        if (arg == null) arg = defaultAppTitle;

        if (append)
            getWindow().title += arg;
        else 
            getWindow().title = arg;
        
    }

    static var _windowTween:FlxTween = null; 
    public static function tweenWindow(values:Dynamic,time:Float = 0.01,?options:TweenOptions,?fill = true) {
        if (_windowTween != null) _windowTween.cancel();

       // options ??= {}
        
		FlxG.scaleMode = new flixel.system.scaleModes.RatioScaleMode(fill);
		getWindow().resizable = !fill;

        _windowTween = FlxTween.tween(getWindow(),values,time,options);
    }

    public static function setWindowSize(width:Int,height:Int) {
        if (_windowTween !=null)
            FlxTween.cancelTweensOf(getWindow(),['width','height']);

        FlxG.resizeWindow(width,height);

    }

    public static function setGameDimensions(width:Int,height:Int, cameras:Array<FlxCamera>) {
        if (_windowTween !=null)
            FlxTween.cancelTweensOf(getWindow(),['width','height']);

        var newWidth:Int = width;
        var newHeight:Int = height; 
        var scaledHeight:Int = height;

        for(camera in cameras){
            camera.width = FlxG.width;
            if(newHeight <= FlxG.height){
                camera.height = Std.int(FlxG.height * (FlxG.width / newHeight));
                scaledHeight = camera.height;
            }
            // if(newWidth == newHeight){
            //     camera.y 
            // }
        }
        if(!FlxG.fullscreen){
            FlxG.resizeWindow(newWidth, newHeight);
            FlxG.stage.window.x = Std.int((monitorResolutionWidth - newWidth) / 2);
            FlxG.stage.window.y = Std.int((monitorResolutionHeight - newHeight) / 2);
        } 

        // else {
        //     FlxG.stage.window.onResize = ()->{
        //         FlxG.resizeWindow(newWidth, newHeight);
        //     }
        // }
        var s = new funkin.backend.FunkinRatioScaleMode();
        s.height = scaledHeight;
        FlxG.scaleMode = s;
    }

}
