package funkin.data;

import funkin.data.Song.SwagSection;
import funkin.data.Song.SwagSong;
import funkin.data.StageData;

import haxe.Json;

// this is for later
enum abstract ChartFormat(String) to String
{
	var PSYCH = 'Psych_1.0';
	var CNE = 'Codename Engine';
	var VSLICE = 'V-Slice';
	var UNKNOWN; // this isnt final dw
}

class Chart
{
	/**
	 * Attempts to get a songs data from a given path
	 * @param path 
	 * @return SwagSong
	 */
	public static function fromPath(path:String):SwagSong
	{
		path = Paths.formatToSongPath(path);
		if (!FunkinAssets.exists(path))
		{
			throw 'couldnt find chart at ($path)';
		}
		
		return fromData(Json.parse(FunkinAssets.getContent(path)));
	}
	
	public static function fromSong(songName:String) {}
	
	public static function fromData(data:Dynamic):SwagSong
	{
		if (data == null)
		{
			throw "data provided was null";
		}
		
		var format = checkFormat(data);
		if (format != UNKNOWN) throw 'this is using a incompatible format\n($format)'; // this isnt gonna stay btw
		
		if (!Reflect.hasField(data, 'song')) throw "data provided is invalid";
		
		var json = data.song;
		correctFormat(json);
		
		return cast json;
	}
	
	/**
	 * Checks a structures fields to find out if its using a knwon format
	 */
	public static function checkFormat(json:Dynamic):ChartFormat
	{
		if (json == null) return UNKNOWN;
		
		if (Reflect.hasField(json, 'format'))
		{
			var format:String = Reflect.field(json, 'format');
			if (format.contains('psych_v1')) return PSYCH;
		}
		
		if (Reflect.hasField(json, 'version') && Reflect.hasField(json, 'scrollSpeed')) return VSLICE;
		
		if (Reflect.hasField(json, 'codenameChart')) return CNE;
		
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
