package funkin.backend.math;

import flixel.util.FlxPool;

// modified from lime.math.Vector4
/**
	`Vector3` is a vector suitable for three-dimensional
	math, containing (x, y, z) components
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Vector3 implements IFlxPooled
{
	static final _pool = new FlxPool<Vector3>(() -> new Vector3());
	
	public static function get(x:Float = 0, y:Float = 0, z:Float = 0):Vector3
	{
		return _pool.get().setTo(x, y, z);
	}
	
	public static inline function recycle(x:Float = 0, y:Float = 0, z:Float = 0):Vector3
	{
		return _pool.get().setTo(x, y, z);
	}
	
	public inline function put():Void
	{
		setTo(0, 0, 0);
		_pool.put(this);
	}
	
	// should set this up weak vecs later
	var _weak:Bool = false;
	
	public inline function putWeak() {}
	
	public function destroy():Void {}
	
	/**
		A constant representing the x axis (1, 0, 0)
	**/
	public static var X_AXIS(get, never):Vector3;
	
	/**
		A constant representing the y axis (0, 1, 0)
	**/
	public static var Y_AXIS(get, never):Vector3;
	
	/**
		A constant representing the z axis (0, 0, 1)
	**/
	public static var Z_AXIS(get, never):Vector3;
	
	/**
		Get the length of this vector
	**/
	public var length(get, never):Float;
	
	/**
		Get the squared length of this vector
		(avoiding the use of `Math.sqrt` for faster
		performance)
	**/
	public var lengthSquared(get, never):Float;
	
	/**
		The x component value
	**/
	public var x:Float;
	
	/**
		The y component value
	**/
	public var y:Float;
	
	/**
		The z component value
	**/
	public var z:Float;
	
	/**
		Creates a new `Vector3` instance
		@param	x	(Optional) An initial x value (default is 0)
		@param	y	(Optional) An initial y value (default is 0)
		@param	z	(Optional) An initial z value (default is 0)
	**/
	public function new(x:Float = 0.0, y:Float = 0.0, z:Float = 0.0)
	{
		setTo(x, y, z);
	}
	
	/**
		Adds two `Vector3` instances together and returns the result
		@param	a	A `Vector3` instance to add to the current one
		@param	result	(Optional) A `Vector3` instance to store the result
		@return	A `Vector3` instance with the added value
	**/
	public inline function add(a:Vector3, result:Vector3 = null):Vector3
	{
	    result ??= Vector3.get();
		result.setTo(this.x + a.x, this.y + a.y, this.z + a.z);
		return result;
	}
	
	/**
		Calculates the angle between two `Vector3` coordinates
		@param	a	A `Vector3` instance
		@param	b	A second `Vector3` instance
		@return	The calculated angle
	**/
	public static inline function angleBetween(a:Vector3, b:Vector3):Float
	{
		var a0 = a.clone();
		a0.normalize();
		var b0 = b.clone();
		b0.normalize();
		
		return Math.acos(a0.dotProduct(b0));
	}
	
	/**
		Creates a new `Vector3` instance with the same values as the current one
		@return	A new `Vector3` instance with the same values
	**/
	public inline function clone():Vector3
	{
		return Vector3.get(x, y, z);
	}
	
	/**
		Creates a new `Vector3` instance linearly interpolated between this Vector3 and the given goal by the given alpha
		@param goal A `Vector3` instance to interpolate towards
		@param alpha How far the interpolation is
		@return A `Vector3 instance linearly interpolated`
	**/
	// https://gamedev.stackexchange.com/questions/18615/how-do-i-linearly-interpolate-between-two-vectors
	public function lerp(goal:Vector3, alpha:Float):Vector3
	{
		return Vector3.get(alpha * goal.x + x * (1 - alpha), alpha * goal.y + y * (1 - alpha), alpha * goal.z + z * (1 - alpha));
	}
	
	/**
		Copies the x, y and z component values of another `Vector3` instance
		@param	sourceVector3	A `Vector3` instance to copy from
	**/
	public inline function copyFrom(sourceVector3:Vector3):Void
	{
		x = sourceVector3.x;
		y = sourceVector3.y;
		z = sourceVector3.z;
	}
	
	/**
		Performs vector multiplication between this vector and another `Vector3` instance
		@param	A `Vector3` instance to multiply by
		@param	result(Optional) A `Vector3` to use for the result
		@return	A `Vector3` instance with the result
		@see https://en.wikipedia.org/wiki/Cross_product
	**/
	public inline function crossProduct(a:Vector3, result:Vector3 = null):Vector3
	{
	    result ??= Vector3.get();
		result.setTo(y * a.z - z * a.y, z * a.x - x * a.z, x * a.y - y * a.x);
		return result;
	}
	
	/**
		Decrements the x, y and z component values by those in another `Vector3` instance
		@param	a	A `Vector3` instance to decrement the current vector by
	**/
	public inline function decrementBy(a:Vector3):Void
	{
		x -= a.x;
		y -= a.y;
		z -= a.z;
	}
	
	/**
		Calculates the distance between two vectors
		@param	pt1	A `Vector3` instance
		@param	pt2	A second `Vector3` instance
		@return	The distance between each vector
	**/
	public inline static function distance(pt1:Vector3, pt2:Vector3):Float
	{
		var x = pt2.x - pt1.x;
		var y = pt2.y - pt1.y;
		var z = pt2.z - pt1.z;
		
		return Math.sqrt(x * x + y * y + z * z);
	}
	
	/**
		Calculates the squared distance between two vectors,
		(avoids the use of `Math.sqrt` for faster performance)
		@param	pt1	A `Vector3` instance
		@param	pt2	A second `Vector3` instance
		@return	The square of the distance between each vector
	**/
	public inline static function distanceSquared(pt1:Vector3, pt2:Vector3):Float
	{
		var x = pt2.x - pt1.x;
		var y = pt2.y - pt1.y;
		var z = pt2.z - pt1.z;
		
		return x * x + y * y + z * z;
	}
	
	/**
		Calculates the dot product of the current vector with another `Vector3` instance
		@param	a	A `Vector3` instance to use in the dot product
		@return	The calculated dot product value
		@see https://en.wikipedia.org/wiki/Dot_product
	**/
	public inline function dotProduct(a:Vector3):Float
	{
		return x * a.x + y * a.y + z * a.z;
	}
	
	/**
		Whether two `Vector3` instances have equal component values.

		Comparing the w component value is optional.
		@param	toCompare	A `Vector3` instance to compare against
		@return	Whether both instances have equal values
	**/
	public inline function equals(toCompare:Vector3):Bool
	{
		return x == toCompare.x && y == toCompare.y && z == toCompare.z;
	}
	
	/**
		Increments the x, y and z component values by those in a second `Vector3` instance
		@param	a	A `Vector3` instance to increment the current vector by
	**/
	public inline function incrementBy(a:Vector3):Void
	{
		x += a.x;
		y += a.y;
		z += a.z;
	}
	
	/**
		Whether two `Vector3` instances have nearly equal component values.
		Comparison is performed within a given tolerance value.
		@param	toCompare	A `Vector3` instance to compare against
		@param	tolerance	A floating point value determining how near the values must be to be considered near equal
		@return	Whether both instances have equal values, within the given tolerance
	**/
	public inline function nearEquals(toCompare:Vector3, tolerance:Float):Bool
	{
		return Math.abs(x - toCompare.x) < tolerance && Math.abs(y - toCompare.y) < tolerance && Math.abs(z - toCompare.z) < tolerance;
	}
	
	/**
		Negates the x, y and z values of the current vector
		(multiplying each value by -1)
	**/
	public inline function negate():Void
	{
		x *= -1;
		y *= -1;
		z *= -1;
	}
	
	/**
		Divides the x, y and z component values by the
		length of the vector
	**/
	public inline function normalize():Float
	{
		var l = length;
		
		if (l != 0)
		{
			x /= l;
			y /= l;
			z /= l;
		}
		
		return l;
	}

	/**
	    Projects this vector onto another `Vector3` instance
	    @param onto A `Vector3` instance to project onto
	    @param result (Optional) A `Vector3` instance to store the result
	    @return A `Vector3` instance containing the projected vector
		@see https://en.wikipedia.org/wiki/Vector_projection
	**/
	public inline function project(onto:Vector3, result:Vector3 = null):Vector3
	{
	    result ??= Vector3.get();
	    var scalar = dotProduct(onto) / onto.lengthSquared;
	    result.setTo(onto.x * scalar, onto.y * scalar, onto.z * scalar);
	    return result;
	}	

	/**
		Projects this vector onto a plane defined by a normal `Vector3`
		@param normal A `Vector3` instance representing the plane's normal (should be normalized)
		@param result (Optional) A `Vector3` instance to store the result
		@return A `Vector3` instance containing the projected vector
		@see https://en.wikipedia.org/wiki/Vector_projection
	**/
	public inline function projectOntoPlane(normal:Vector3, result:Vector3 = null):Vector3
	{
	    result ??= Vector3.get();
	    var projected = project(normal, Vector3.get());
	    result.setTo(x - projected.x, y - projected.y, z - projected.z);
	    projected.put();
	    return result;
	}
	/**
		Puts this vector's values on an Absolute Value.
		@param result (Optional) A `Vector3` instance to store the result
		@return A `Vector` instance containing the value in absolute.
	**/
	public inline function abs(result:Vector3 = null):Vector3
	{
		result ??= Vector3.get();
		result.setTo(Math.abs(x), Math.abs(y), Math.abs(z));
		return result;
	}
	/**
		Scales the x, y and z component values by a scale value
		@param	s	The amount of scale to apply
	**/
	public inline function scaleBy(s:Float):Void
	{
		x *= s;
		y *= s;
		z *= s;
	}
	
	/**
		Sets the x, y and z component values
		@param	xa	An x value
		@param	ya	A y value
		@param	za	A z value

		@return returns `this` vector3
	**/
	public inline function setTo(xa:Float, ya:Float, za:Float):Vector3
	{
		x = xa;
		y = ya;
		z = za;
		
		return this;
	}
	/**
		Subtracts the values of a second `Vector3` instance
		from the current one
		@param	a	A second `Vector3` instance to substract
		@param	result	(Optional) A `Vector3` instance to store the result
		@return	A `Vector3` instance containing the subtracted value
	**/
	public inline function subtract(a:Vector3, result:Vector3 = null):Vector3
	{
	    result ??= Vector3.get();
		result.setTo(x - a.x, y - a.y, z - a.z);
		return result;
	}
	
	/**
	    Creates a `Vector3` from spherical coordinates
	    @param theta The polar angle in radians (from the z axis)
	    @param phi The azimuthal angle in radians (from the x axis)
	    @return A normalized `Vector3` instance
		@see https://en.wikipedia.org/wiki/Spherical_coordinate_system
	**/
	public static inline function fromAngle(theta:Float, phi:Float):Vector3
	{
	    var sinTheta = Math.sin(theta);
	    return Vector3.get(sinTheta * Math.cos(phi), sinTheta * Math.sin(phi), Math.cos(theta));
	}
	
	/**
	    Returns a component-wise minimum of two `Vector3` instances
	    @param a A `Vector3` instance
	    @param b A second `Vector3` instance
	    @param result (Optional) A `Vector3` instance to store the result
	    @return A `Vector3` instance with the minimum values
	**/
	public static inline function min(a:Vector3, b:Vector3, result:Vector3 = null):Vector3
	{
	    result ??= Vector3.get();
	    result.setTo(Math.min(a.x, b.x), Math.min(a.y, b.y), Math.min(a.z, b.z));
	    return result;
	}
	
	/**
	    Returns a component-wise maximum of two `Vector3` instances
	    @param a A `Vector3` instance
	    @param b A second `Vector3` instance
	    @param result (Optional) A `Vector3` instance to store the result
	    @return A `Vector3` instance with the maximum values
	**/
	public static inline function max(a:Vector3, b:Vector3, result:Vector3 = null):Vector3
	{
	    result ??= Vector3.get();
	    result.setTo(Math.max(a.x, b.x), Math.max(a.y, b.y), Math.max(a.z, b.z));
	    return result;
	}
	
	
	@:dox(hide) public inline function toString():String
	{
		return "Vector3(" + x + ", " + y + ", " + z + ")";
	}
	
	// Getters & Setters
	@:noCompletion private inline function get_length():Float
	{
		return Math.sqrt(x * x + y * y + z * z);
	}
	
	@:noCompletion private inline function get_lengthSquared():Float
	{
		return x * x + y * y + z * z;
	}
	
	private inline static function get_X_AXIS():Vector3
	{
		return Vector3.get(1, 0, 0);
	}
	
	private inline static function get_Y_AXIS():Vector3
	{
		return Vector3.get(0, 1, 0);
	}
	
	private inline static function get_Z_AXIS():Vector3
	{
		return Vector3.get(0, 0, 1);
	}
}
