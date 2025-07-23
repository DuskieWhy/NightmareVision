package funkin.game;

@:nullSafety
class RatingInfo
{
	public var name:String;
	public var percent:Float;
	
	public function new(name:String, percent:Float)
	{
		this.name = name;
		this.percent = percent;
	}
}
