package funkin.backend;

import funkin.states.PlayState;

// do more wuith this
class Difficulty
{
	/**
	 * Constant list of the default Difficulties used by the game
	 */
	public static final defaultDifficulties:Array<String> = ['Easy', 'Normal', 'Hard'];
	
	/**
	 * Resets the currently loaded difficulties back to default
	 */
	public static function reset() return (difficulties = defaultDifficulties.copy());
	
	/**
	 * The considered default difficulty. Used to determine which difficulties chart shouldnt have a suffix
	 */
	public static var defaultDifficulty:String = 'Normal';
	
	/**
	 * Currently loaded list of difficulties 
	 */
	public static var difficulties:Array<String> = reset();
	
	/**
	 * Returns the difficulty suffix from `num`
	 * @param num 
	 */
	public static function getDifficultyFilePath(?number:Int)
	{
		number ??= PlayState.storyDifficulty;
		
		var fileSuffix:String = difficulties[number];
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
