package funkin.utils;

import flixel.system.FlxAssets.FlxShader;
import openfl.filters.ShaderFilter;

// by me data thx
@:access(flixel.FlxCamera)
@:access(flixel.system.frontEnds.CameraFrontEnd)
class CameraUtil
{
	/**
		returns the last camera in the list
	**/
	public static var lastCamera(get, never):FlxCamera;

	static function get_lastCamera():FlxCamera return FlxG.cameras.list[FlxG.cameras.list.length - 1];

	/**
		convenient function to making a camera and adding it to the stack as well
		* @param	add	whether it should be automatically added to the stack
		* @return	The new Camera
	**/
	public static inline function quickCreateCam(add:Bool = true):FlxCamera
	{
		var cam = new FlxCamera();
		cam.bgColor = 0x0;

		if (add) FlxG.cameras.add(cam, false);

		return cam;
	}

	/**
		function to easily apply a shader to a camera
		* @param	shader	the shader to be applied
		* @param	camera	the camera to apply the filter to. default is the first camera
	**/
	public static function addShader(shader:FlxShader, ?camera:FlxCamera)
	{
		if (camera == null) camera = FlxG.camera;

		var filter:ShaderFilter = new ShaderFilter(shader);
		if (camera.filters == null) camera.filters = [];
		camera.filters.push(filter);
	}

	/**
		function to easily remove a shader to a camera
		* @param	shader	the shader to be removed
		* @param	camera	the camera to remove the filter from. default is the first camera
		* @return	whether the camera removal was successful
	**/
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

	/**
		inserts the camera to a specific index in the stack
		* @param	idx	the position to insert the camera in
		* @param	camera	the camera to insert
		* @param	defDraw	whether it should be set as a default draw target
		* @return	whether the camera removal was successful
	**/
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

		return camera;
	}
}
