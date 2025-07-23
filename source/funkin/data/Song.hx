package funkin.data;

import haxe.Json;

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var mustHitSection:Bool;
	
	var ?sectionBeats:Float;
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
}
