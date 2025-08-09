package funkin.data;

import funkin.backend.Difficulty;
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

/**
 * General utility class to load Chart data
 */
@:nullSafety
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
		
		return fromData(FunkinAssets.parseJson(FunkinAssets.getContent(path)));
	}
	
	/**
	 * Attempts to get a songs data from song name
	 * @param songName 
	 * @param difficulty 
	 * @return SwagSong
	 */
	public static function fromSong(songName:String, difficulty:Int = -1):SwagSong
	{
		var diff = Difficulty.getDifficultyFilePath(difficulty);
		
		songName = Paths.formatToSongPath(songName);
		
		var path = Paths.formatToSongPath(Paths.json('$songName/$songName$diff'));
		if (!FunkinAssets.exists(path))
		{
			throw 'couldnt find chart at ($path)';
		}
		
		return fromData(FunkinAssets.parseJson(FunkinAssets.getContent(path)));
	}
	
	public static function fromData(data:Dynamic):SwagSong
	{
		if (data == null)
		{
			throw "data provided was null";
		}
		
		final format = checkFormat(data);
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
	
	static function correctFormat(songJson:Dynamic) // cleanup chart format
	{
		if (songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			
			if (Reflect.hasField(songJson, 'player3')) Reflect.deleteField(songJson, 'player3');
		}
		
		if (songJson.keys == null) songJson.keys = 4;
		if (songJson.lanes == null) songJson.lanes = 2;
		
		final sectionsData:Array<SwagSection> = songJson.notes;
		
		if (songJson.events == null)
		{
			var events:Array<Dynamic> = [];
			
			if (sectionsData != null)
			{
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
							// why are events stored like this?
							final time:Float = note[0];
							final evName:String = note[2];
							final value1:String = note[3];
							final value2:String = note[4];
							
							events.push([time, [[evName, value1, value2]]]);
							
							notes.remove(note);
							len = notes.length;
						}
						else i++;
					}
				}
			}
			
			songJson.events = events;
		}
		
		if (sectionsData == null) return;
		
		for (section in sectionsData)
		{
			final beats:Null<Float> = section.sectionBeats;
			if (beats == null || Math.isNaN(beats))
			{
				section.sectionBeats = 4;
				if (Reflect.hasField(section, 'lengthInSteps')) Reflect.deleteField(section, 'lengthInSteps');
			}
		}
	}
}
