package funkin.data;

import haxe.Json;

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	
	var keys:Int;
	var lanes:Int;
	
	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	
	var arrowSkin:String;
	var splashSkin:String;
	var validScore:Bool;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String = 'default';
	public var splashSkin:String;
	public var speed:Float = 1;
	public var stage:String;
	
	public var keys:Int = 4;
	public var lanes:Int = 2;
	
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';
	
	public static function convertFormat(songJson:Dynamic) // Convert old charts to newest format
	{
		if (songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}
		
		if (songJson.keys == null) songJson.keys = 4;
		if (songJson.lanes == null) songJson.lanes = 2;
		
		if (songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];
				
				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while (i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if (note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}
	}
	
	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		final formattedFolder:String = Paths.formatToSongPath(folder);
		final formattedSong:String = Paths.formatToSongPath(jsonInput);
		
		final path = Paths.json('$formattedFolder/$formattedSong');
		
		final rawJson = FunkinAssets.getContent(path).trim();
		
		final songJson:SwagSong = parseJSON(rawJson);
		if (jsonInput != 'events') StageData.loadDirectory(songJson);
		convertFormat(songJson);
		return songJson;
	}
	
	public static function parseJSON(rawJson:String):SwagSong
	{
		return cast Json.parse(rawJson).song;
	}
}
