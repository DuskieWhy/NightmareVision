package funkin.game.modchart;

@:structInit class SpeedEvent
{
	public var position:Float = 0; // the y position where the change happens (modManager.getVisPos(songTime))
	public var startTime:Float = 0; // the song position (conductor.songTime) where the change starts
	public var songTime:Float = 0; // the song position (conductor.songTime) when the change ends
	@:optional public var startSpeed:Null<Float> = 1; // the starting speed
	public var speed:Float = 1; // speed mult after the change
}
