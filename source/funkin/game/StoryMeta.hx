package funkin.game;

/**
 * Contains information about Story Mode
 */
class StoryMeta
{
	/**
	 * The current week by 
	 */
	public var curWeek:Int = 0;
	
	/**
	 * The currently loaded songs in the week
	 */
	public var playlist:Array<String> = [];
	
	/**
	 * The Story Mode difficulty
	 */
	public var difficulty:Int = 1;
	
	/**
	 * The total score gained throughout a week
	 * 
	 * Only in Story Mode
	 */
	public var score:Int = 0;
	
	/**
	 * The total amount of misses throughout a week
	 * 
	 * Only in Story Mode
	 */
	public var misses:Int = 0;
	
	public function new() {}
}
