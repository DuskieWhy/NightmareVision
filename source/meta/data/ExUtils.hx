package meta.data;

import flixel.system.FlxAssets.FlxShader;
import openfl.filters.ShaderFilter;

//imma be real i be bringing this into every mod i work on and calling it whatever the mod is but fuck it my util now
//stupid ass fuckign private access kill everyone 
@:access(flixel)
class ExUtils
{
	public static inline function distanceBetween(p1:FlxPoint, p2:FlxPoint):Float
    {
        var dx:Float = p1.x - p2.x;
        var dy:Float = p1.y - p2.y;
        return FlxMath.vectorLength(dx, dy);
    }

    //idk amybe i want this in the future but here inserting functionality to cameras
    public static function insertFlxCamera(idx:Int,camera:FlxCamera,defDraw:Bool = false) 
    {
        var cameras = [
            for (i in FlxG.cameras.list) {
                cam: i,
                defaultDraw: FlxG.cameras.defaults.contains(i)
            }
        ];

        for(i in cameras) FlxG.cameras.remove(i.cam, false);

        cameras.insert(idx, {cam: camera,defaultDraw: defDraw});

        for (i in cameras) FlxG.cameras.add(i.cam,i.defaultDraw);
    }

    public static function addShader(shader:FlxShader,?camera:FlxCamera)
    {
        //if (!ClientPrefs.data.shaders && !forced) return;
        if (camera == null) camera = FlxG.camera;
        var filter:ShaderFilter = new ShaderFilter(shader);
        if (camera._filters == null) camera._filters = [];
        camera._filters.push(filter);
    }

    public static function removeShader(shader:FlxShader,?camera:FlxCamera):Bool
    {
        if (camera == null) camera = FlxG.camera;
        if (camera._filters == null) return false;

        for (i in camera._filters) {
            if (i is ShaderFilter) {
                var filter:ShaderFilter = cast i;
                if (filter.shader == shader) {camera._filters.remove(i); return true;}
            }
        }
        return false;
    }

}