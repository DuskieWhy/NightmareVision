package funkin.utils;

@:nullSafety
class ArrayUtil
{
	/**
	 * Clears this array in place.
	 * @param array
	 * @return Array<T>
	 */
	public static function clear<T>(array:Array<T>):Array<T>
	{
		while (array.length > 0)
			array.pop();
		return array;
	}
	
	/**
	 * Shuffles this array in place using Fisher-Yates.
	 * @param array
	 * @return Array<T>
	 */
	public static function shuffle<T>(array:Array<T>):Array<T>
	{
		var i = array.length;
		while (i > 1)
		{
			var j = Std.int(Math.random() * i--);
			swap(array, i, j);
		}
		return array;
	}
	
	/**
	 * Returns the last element, or null if empty.
	 * @param array
	 * @return Null<T>
	 */
	public static function last<T>(array:Array<T>):Null<T>
	{
		return array.length > 0 ? array[array.length - 1] : null;
	}
	
	/**
	 * Removes duplicate values from this array in place.
	 * @param array
	 * @return Array<T>
	 */
	public static function unique<T>(array:Array<T>):Array<T>
	{
		var seen:Array<T> = [];
		var i = 0;
		while (i < array.length)
		{
			if (seen.indexOf(array[i]) != -1) array.splice(i, 1);
			else seen.push(array[i++]);
		}
		return array;
	}
	
	/**
	 * Returns a new array with all elements from both arrays, without duplicates.
	 * @param a
	 * @param b
	 * @return Array<T>
	 */
	public static function union<T>(a:Array<T>, b:Array<T>):Array<T>
	{
		var result = a.copy();
		for (item in b)
			if (result.indexOf(item) == -1) result.push(item);
		return result;
	}
	
	/**
	 * Swaps two elements in place by index.
	 * @param array
	 * @param i
	 * @param j
	 */
	public static function swap<T>(array:Array<T>, i:Int, j:Int):Void
	{
		var tmp = array[i];
		array[i] = array[j];
		array[j] = tmp;
	}
	
	/**
	 * Splits the array into sub-arrays of the given size.
	 * @param array
	 * @param size
	 * @return Array<Array<T>>
	 */
	public static function chunk<T>(array:Array<T>, size:Int):Array<Array<T>>
	{
		var result:Array<Array<T>> = [];
		var i = 0;
		while (i < array.length)
		{
			result.push(array.slice(i, i + size));
			i += size;
		}
		return result;
	}
}
