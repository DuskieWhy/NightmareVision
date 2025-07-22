package funkin.data;

import funkin.data.Song.SwagSection;
import funkin.data.Song.SwagSong;
import funkin.data.StageData;

import haxe.Json;

// this is for later
enum abstract ChartFormat(String) to String
{
	var PSYCH = 'psych_1.0';
	var CNE = 'codename';
	var VSLICE = 'v-slice';
	var UNKNOWN;
}

class Chart
{
	public static function fromPath(path:String):SwagSong
	{
		path = Paths.formatToSongPath(path);
		if (!FunkinAssets.exists(path))
		{
			throw 'couldnt find chart at' + path;
		}
		
		var content = FunkinAssets.getContent(path);
		
		return fromData(Json.parse(content));
	}
	
	public static function fromData(data:Dynamic):SwagSong
	{
		if (data == null)
		{
			throw "data provided was null";
		}
		
		var format = checkFormat(data);
		if (format == PSYCH || format == VSLICE) throw "this is using a incompatible format"; // this isnt gonna stay btw
		
		if (!Reflect.hasField(data, 'song')) throw "invalid data struct";
		
		var json = data.song;
		StageData.loadDirectory(json); // i think actually we can kill this
		correctFormat(json);
		
		return cast json;
	}
	
	// public static function getSong(content:String) {}
	public static function checkFormat(json:Dynamic):ChartFormat
	{
		if (json == null) return UNKNOWN;
		if (Reflect.hasField(json, 'format'))
		{
			var format:String = Reflect.field(json, 'format');
			if (format.contains('psych_v1')) return PSYCH;
		}
		if (Reflect.hasField(json, 'version') && Reflect.hasField(json, 'scrollSpeed')) return VSLICE;
		return UNKNOWN;
	}
	
	static function correctFormat(songJson:Dynamic) // Convert old charts to newest format
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
}
