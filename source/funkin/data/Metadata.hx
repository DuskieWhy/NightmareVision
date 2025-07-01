package funkin.data;

import openfl.Assets;

// debating rn should we rework songs to have a general global meta
// that decides the stage, chars

typedef MetaVariables =
{
	?composers:Array<String>,
	?charters:Array<String>,
	?artists:Array<String>,
	?coders:Array<String>
}

// if u want to do to it hardcoded u can just fuckin go var meta:Metadata = {composers: 'penis'}; //blalblalbla
// otherwise if u have a json use getSong to have it look through the currently loaded song or getDirect to give a directpath
@:structInit class Metadata
{
	public static var seperator:String = ',';
	
	public var composers:String = null;
	public var charters:String = null;
	public var artists:String = null;
	public var coders:String = null;
	
	/**
	 * returns a metadata from the loaded playstate
	 */
	public static function getSong():Null<Metadata>
	{
		var json:MetaVariables = null;
		final formattedSong = Paths.formatToSongPath(PlayState.SONG.song);
		
		var jsonExists:Bool = false;
		var path:String = Paths.modsJson('$formattedSong/meta');
		if (FileSystem.exists(path))
		{
			jsonExists = true;
			json = haxe.Json.parse(File.getContent(path));
		}
		
		// try asset dir
		if (!jsonExists)
		{
			path = Paths.json('$formattedSong/meta');
			if (FileSystem.exists(path)) json = haxe.Json.parse(File.getContent(path));
			else if (Assets.exists(path, TEXT)) json = haxe.Json.parse(Assets.getText(path));
		}
		
		if (json != null)
		{
			var data:Metadata = {};
			data.populate(json);
			return data;
		}
		
		return null;
	}
	
	/**
	 * returns a metadata from your provided path
	 */
	public static function getDirect(filePath:String):Null<Metadata>
	{
		var json:MetaVariables = null;
		
		var jsonExists:Bool = false;
		var path:String = Paths.modFolders('$filePath.json');
		if (FileSystem.exists(path))
		{
			jsonExists = true;
			json = haxe.Json.parse(File.getContent(path));
		}
		
		// try asset dir
		if (!jsonExists)
		{
			path = Paths.getPath('$filePath.json', TEXT);
			if (FileSystem.exists(path)) json = haxe.Json.parse(File.getContent(path));
			else if (Assets.exists(path, TEXT)) json = haxe.Json.parse(Assets.getText(path));
		}
		
		if (json != null)
		{
			var data:Metadata = {};
			data.populate(json);
			return data;
		}
		
		return null;
	}
	
	/**
	 * converts and sets the json vars to the metadata
	 * 
	 * used by the static functions but can be used manually ig
	 */
	function populate(vars:MetaVariables)
	{
		for (field in Reflect.fields(vars))
		{
			if (Type.getInstanceFields(Type.getClass(this)).contains(field))
			{
				final metaProp:String = join(Reflect.getProperty(vars, field));
				Reflect.setProperty(this, field, metaProp);
			}
		}
	}
	
	// specific functions to maintain consistency
	public static function join(arg:Array<String>):String return arg.join('$seperator ');
	
	public static function seperate(arg:String):Array<String> return arg.split('$seperator ');
}
