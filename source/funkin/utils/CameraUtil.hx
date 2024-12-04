package funkin.utils;

import flixel.system.FlxAssets.FlxShader;
import openfl.filters.ShaderFilter;

// by me data thx
@:access(flixel.FlxCamera)
@:access(flixel.system.frontEnds.CameraFrontEnd)
class CameraUtil
{
	/**
		gets the last camera in the stack
	**/
	public static var lastCamera(get, never):FlxCamera;

	static function get_lastCamera():FlxCamera return FlxG.cameras.list[FlxG.cameras.list.length - 1];

	public static inline function quickCreateCam(add:Bool = true):FlxCamera
	{
		var cam = new FlxCamera();
		cam.bgColor = 0x0;

		if (add) FlxG.cameras.add(cam, false);

		return cam;
	}

	public static function addShader(shader:FlxShader, ?camera:FlxCamera, forced:Bool = false)
	{
		// if (!ClientPrefs.shaders && !forced) return;
		if (camera == null) camera = FlxG.camera;

		var filter:ShaderFilter = new ShaderFilter(shader);
		if (camera.filters == null) camera.filters = [];
		camera.filters.push(filter);
	}

	public static function removeShader(shader:FlxShader, ?camera:FlxCamera):Bool
	{
		if (camera == null) camera = FlxG.camera;
		if (camera.filters == null) return false;

		for (i in camera.filters)
		{
			if (i is ShaderFilter)
			{
				var filter:ShaderFilter = cast i;
				if (filter.shader == shader)
				{
					camera.filters.remove(i);
					return true;
				}
			}
		}
		return false;
	}

	public static function insertFlxCamera(idx:Int, camera:FlxCamera, defDraw:Bool = false)
	{
		var cameras = [
			for (i in FlxG.cameras.list)
				{
					cam: i,
					defaultDraw: FlxG.cameras.defaults.contains(i)
				}
		];

		for (i in cameras)
			FlxG.cameras.remove(i.cam, false);

		cameras.insert(idx, {cam: camera, defaultDraw: defDraw});

		for (i in cameras)
			FlxG.cameras.add(i.cam, i.defaultDraw);
	}
}
