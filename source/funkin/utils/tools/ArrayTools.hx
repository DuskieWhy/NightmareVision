package funkin.utils.tools;

class ArrayTools
{
	/**
	 * Clears this array in place
	 * @param array 
	 * @return Array<T>
	 */
	public static function clear<T>(array:Array<T>):Array<T>
	{
		while (array.length > 0)
			array.pop();
		return array;
	}
}
