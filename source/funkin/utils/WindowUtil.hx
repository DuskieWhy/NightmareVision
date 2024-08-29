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




}
