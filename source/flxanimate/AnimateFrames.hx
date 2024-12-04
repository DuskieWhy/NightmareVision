package flxanimate;

import flxanimate.frames.FlxAnimateFrames;
import flxanimate.data.SpriteMapData.AnimateAtlas;
import flxanimate.zip.Zip;
import haxe.io.Bytes;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
import openfl.Assets;

// made it have sys support
@:access(flxanimate.frames.FlxAnimateFrames)
class AnimateFrames
{
	static function pathExists(p:String)
	{
		if (Assets.exists(p)) return true;
		#if sys if (FileSystem.exists(p)) return true; #end
		return false;
	}

	static function getContent(p:String):String
	{
		if (Assets.exists(p)) return Assets.getText(p);
		#if sys if (FileSystem.exists(p)) return File.getContent(p); #end
		throw 'Cannot retrieve contents of "${p}"';
	}

	// needed sys first here cuz lime errors prevented the func from continuing in the case of null?
	static function getBitmapData(id:String)
	{
		var bitmapData:Null<BitmapData> = null;
		#if sys bitmapData = BitmapData.fromFile(id); #end
		if (bitmapData == null) bitmapData = Assets.getBitmapData(id);
		return bitmapData;
	}

	/**
	 * Parses the spritemaps into small sprites to use in the animation.
	 *
	 * @param Path          Where the Sprites are, normally you use it once when calling FlxAnimate already
	 * @return              new sliced limbs for you to use ;)
	 */
	public static function fromTextureAtlas(Path:String):FlxAtlasFrames
	{
		var frames:FlxAnimateFrames = null;

		function unpackZip(zip:Null<List<haxe.zip.Entry>>)
		{
			#if html5
			FlxG.log.error("Zip Stuff isn't supported on Html5 since it can't transform bytes into an image");
			return null;
			#end
			var imagemap:Map<String, Bytes> = new Map();
			var jsonMap:Map<String, AnimateAtlas> = new Map();
			var thing = (zip != null) ? zip : Zip.unzip(Zip.readZip(Assets.getBytes(Path)));
			for (list in thing)
			{
				if (haxe.io.Path.extension(list.fileName) == "json")
				{
					jsonMap.set(list.fileName, haxe.Json.parse(StringTools.replace(list.data.toString(), String.fromCharCode(0xFEFF), "")));
				}
				else if (haxe.io.Path.extension(list.fileName) == "png")
				{
					var name = list.fileName.split("/");
					imagemap.set(name[name.length - 1], list.data);
				}
			}
			// Assuming the json has the same stuff as the image stuff
			for (curJson in jsonMap)
			{
				var curImage = BitmapData.fromBytes(imagemap[curJson.meta.image]);
				if (curImage != null)
				{
					var graphic = FlxG.bitmap.add(curImage, '$Path/${curJson.meta.image}');
					if (frames == null) frames = new FlxAnimateFrames(graphic);
					for (sprites in curJson.ATLAS.SPRITES)
					{
						frames.buildLimb(curImage, sprites.SPRITE, curJson.meta, Path);
					}
				}
				else FlxG.log.error('the Image called "${curJson.meta.image}" isnt in this zip file!');
			}
			zip == null;
		}

		if (FlxAnimateFrames.zip != null || haxe.io.Path.extension(Path) == "zip") unpackZip(FlxAnimateFrames.zip);
		else if (pathExists('$Path/spritemap.json'))
		{
			var curJson:AnimateAtlas = haxe.Json.parse(StringTools.replace(getContent('$Path/spritemap.json'), String.fromCharCode(0xFEFF), ""));
			var curSpritemap = getBitmapData('$Path/${curJson.meta.image}');
			if (curSpritemap != null)
			{
				var graphic = FlxG.bitmap.add(curSpritemap, '$Path/${curJson.meta.image}');
				var spritemapFrames = FlxAnimateFrames.getExistingAnimateFrames(graphic);
				if (spritemapFrames == null)
				{
					spritemapFrames = new FlxAnimateFrames(graphic);
					for (curSprite in curJson.ATLAS.SPRITES)
					{
						spritemapFrames.buildLimb(graphic.bitmap, curSprite.SPRITE, curJson.meta, Path);
					}
				}
				graphic.addFrameCollection(spritemapFrames);
				if (frames == null) frames = new FlxAnimateFrames(graphic);
				frames.addAtlas(spritemapFrames);
			}
			else FlxG.log.error('the image called "${curJson.meta.image}" does not exist in Path $Path, maybe you changed the image Path somewhere else?');
		}
		var i = 1;
		while (pathExists('$Path/spritemap$i.json'))
		{
			var curJson:AnimateAtlas = haxe.Json.parse(StringTools.replace(getContent('$Path/spritemap$i.json'), String.fromCharCode(0xFEFF), ""));
			var curSpritemap = getBitmapData('$Path/${curJson.meta.image}');
			if (curSpritemap != null)
			{
				var graphic = FlxG.bitmap.add(curSpritemap, '$Path/${curJson.meta.image}');
				var spritemapFrames = FlxAnimateFrames.getExistingAnimateFrames(graphic);
				if (spritemapFrames == null)
				{
					spritemapFrames = new FlxAnimateFrames(graphic);
					for (curSprite in curJson.ATLAS.SPRITES)
					{
						spritemapFrames.buildLimb(graphic.bitmap, curSprite.SPRITE, curJson.meta, Path);
					}
				}
				graphic.addFrameCollection(spritemapFrames);
				if (frames == null) frames = new FlxAnimateFrames(graphic);
				frames.addAtlas(spritemapFrames);
			}
			else
			{
				FlxG.log.error('the image called "${curJson.meta.image}" does not exist in Path $Path, maybe you changed the image Path somewhere else?');
			}
			i++;
		}

		if (frames.frames == [])
		{
			FlxG.log.error("the Frames parsing couldn't parse any of the frames, it's completely empty! \n Maybe you misspelled the Path?");
			return null;
		}
		return frames;
	}
}
