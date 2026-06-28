package funkin.objects;

import flixel.util.FlxAxes;

import flixel.math.FlxMath;

class FlxTextAlphabet extends FlxText 
{
    public var forceX:Float = Math.NEGATIVE_INFINITY;
	public var targetY:Float = 0;
    public var isMenuItem:Bool = false;

    public var changeAxis:FlxAxes = XY;

    public var distancePerItem:FlxPoint = new FlxPoint(20, 120);
	public var startPosition:FlxPoint = new FlxPoint(0, 0); //for the calculations

    public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
    {
        super(X, Y, FieldWidth, Text, Size, EmbeddedFont);

        this.startPosition.x = X;
        this.startPosition.y = Y;
    }

    public function snapToTarget()
    {
        if (isMenuItem)
        {
			if (forceX != Math.NEGATIVE_INFINITY) x = forceX;
			else x = (targetY * distancePerItem.x) + startPosition.x;

            y = (targetY * 1.3 * distancePerItem.y) + startPosition.y;
        }
    }

    public var changeLerp:Bool = false;
    public var lerpVal:Float = 0;
    override function update(elapsed:Float)
    {
        if (!changeLerp) lerpVal = FlxMath.bound(elapsed * 9.6, 0, 1);

        if (isMenuItem)
        {
            if (changeAxis.x) x = FlxMath.lerp(x, (targetY * distancePerItem.x) + startPosition.x, lerpVal);
            if (changeAxis.y) y = FlxMath.lerp(y, (targetY * 1.3 * distancePerItem.y) + startPosition.y, lerpVal);
        }

        if (isMenuItem)
		{
			final lerpRate = FlxMath.getElapsedLerp(0.16, elapsed);
			
			if (changeAxis.y) y = FlxMath.lerp(y, (targetY * 1.3 * distancePerItem.y) + startPosition.y, lerpVal);

			if (forceX != Math.NEGATIVE_INFINITY) if (changeAxis.x) x = forceX;
			else if (changeAxis.x) x = FlxMath.lerp(x, (targetY * distancePerItem.x) + startPosition.x, lerpVal);
		}

        super.update(elapsed);
    }
}