package funkin.objects.video;

class FunkinVideo extends FlxVideo
{
	// this was gonna be more elaborate but i decided not to
	function decipherLocation(local:funkin.objects.video.FunkinVideoSprite.Location)
	{
		if (local != null && !(local is Int) && !(local is haxe.io.Bytes) && (local is String))
		{
			var local:String = cast(local, String);

			var modPath:String = Paths.modFolders('videos/$local');
			var assetPath:String = 'assets/videos/$local';

			// found bytes. return em
			if (openfl.utils.Assets.exists(modPath, BINARY)) return cast openfl.utils.Assets.getBytes(modPath);
			else if (openfl.utils.Assets.exists(assetPath, BINARY)) return cast openfl.utils.Assets.getBytes(assetPath);

			#if sys
			if (FileSystem.exists(modPath)) return cast modPath;
			else if (FileSystem.exists(assetPath)) return cast assetPath;
			#end
		}

		return local;
	}

	override function load(location:funkin.objects.video.FunkinVideoSprite.Location, ?options:Array<String>):Bool
	{
		return super.load(decipherLocation(location), options);
	}
}
