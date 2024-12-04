package flxanimate;

import openfl.Assets;
import flxanimate.frames.FlxAnimateFrames;
import flxanimate.zip.Zip;
import flxanimate.data.AnimationData.AnimAtlas;
import flxanimate.FlxAnimate.Settings;
import openfl.errors.Error;

class AnimateSprite extends FlxAnimate
{
	public function new(X:Float = 0, Y:Float = 0, ?Path:String, ?Settings:Settings)
	{
		if (Path == null) throw new Error('please provide a path.');
		super(X, Y, Path, Settings);
	}

	override function loadAtlas(Path:String)
	{
		trace('loading... ' + Path);

		if ((!Assets.exists('$Path/Animation.json') #if sys && !FileSystem.exists('$Path/Animation.json') #end)
			&& haxe.io.Path.extension(Path) != "zip")
		{
			FlxG.log.error('Animation file not found in specified path: "$Path", have you written the correct path?');
			return;
		}
		anim._loadAtlas(atlasSetting(Path));
		frames = AnimateFrames.fromTextureAtlas(Path);
	}

	override function draw()
	{
		if (anim.curInstance == null || anim.curSymbol == null) return;
		super.draw();
	}

	override function atlasSetting(Path:String):AnimAtlas
	{
		var jsontxt:AnimAtlas = null;
		if (haxe.io.Path.extension(Path) == "zip")
		{
			var thing = Zip.readZip(Assets.getBytes(Path));

			for (list in Zip.unzip(thing))
			{
				if (list.fileName.indexOf("Animation.json") != -1)
				{
					jsontxt = haxe.Json.parse(list.data.toString());
					thing.remove(list);
					continue;
				}
			}
			@:privateAccess
			FlxAnimateFrames.zip = thing;
		}
		else
		{
			var jsonPath:String = '$Path/Animation.json';
			#if sys if (FileSystem.exists(jsonPath)) jsontxt = haxe.Json.parse(File.getContent(jsonPath));
			else #end jsontxt = haxe.Json.parse(openfl.Assets.getText(jsonPath));
		}

		return jsontxt;
	}
}
