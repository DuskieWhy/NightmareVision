package funkin.utils;



//do more wuith this
class DifficultyUtil 
{
	public static final defaultDifficulties:Array<String> = ['Easy', 'Normal', 'Hard'];

	public static function reset() difficulties = defaultDifficulties.copy();

	public static var defaultDifficulty:String = 'Normal'; // The chart that has no suffix and starting difficulty on Freeplay/Story Mode

	public static var difficulties:Array<String> = [];

	public static function getDifficultyFilePath(num:Null<Int> = null)
	{
		if (num == null) num = PlayState.storyDifficulty;

		var fileSuffix:String = difficulties[num];
		if (fileSuffix != defaultDifficulty)
		{
			fileSuffix = '-' + fileSuffix;
		}
		else
		{
			fileSuffix = '';
		}
		return Paths.formatToSongPath(fileSuffix);
	}

	public static function getCurDifficulty():String
	{
		return difficulties[PlayState.storyDifficulty].toUpperCase();
	}
}