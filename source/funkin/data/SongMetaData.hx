package funkin.data;

/**
 * 
 */
typedef SongMetaData =
{
	var ?composers:Array<String>;
	var ?charters:Array<String>;
	var ?artists:Array<String>;
	var ?coders:Array<String>;
	
	var ?displayName:String;
	var ?difficulties:Array<String>;
	
	var ?freeplayColor:String;
	var ?freeplayIcon:String;
}

class SongMeta
{
	/**
	 * returns a metadata from the playstate `Song`
	 */
	public static function getFromSong():Null<SongMetaData>
	{
		final formattedSong = Paths.sanitize(PlayState.SONG.song);
		
		var path = Paths.json('$formattedSong/meta');
		
		if (FunkinAssets.exists(path)) return FunkinAssets.parseJson5(FunkinAssets.getContent(path));
		
		return null;
	}
	
	/**
	 * returns a metadata from a provided path
	 */
	public static function getFromPath(filePath:String):Null<SongMetaData>
	{
		if (FunkinAssets.exists(filePath))
		{
			return FunkinAssets.parseJson5(FunkinAssets.getContent(filePath));
		}
		
		return null;
	}
}
