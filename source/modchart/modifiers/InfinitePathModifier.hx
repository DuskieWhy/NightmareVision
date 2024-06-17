package modchart.modifiers;

import flixel.math.FlxMath;
import flixel.FlxG;
import math.Vector3;
import meta.data.*;
import meta.states.*;
import meta.states.substate.*;
import gameObjects.*;

class InfinitePathModifier extends PathModifier {
    override function getName()return 'infinite';
	override function getMoveSpeed()
	{
		return 1850;
	}

	override function getPath():Array<Array<Vector3>>
	{
		var infPath:Array<Array<Vector3>> = [[], [], [], []];

		var r = 0;
		while (r < 360)
		{
			for (data in 0...infPath.length)
			{
				var rad = r * Math.PI / 180;
				infPath[data].push(new Vector3(FlxG.width* 0.5 + (FlxMath.fastSin(rad)) * 600,
					FlxG.height* 0.5 + (FlxMath.fastSin(rad) * FlxMath.fastCos(rad)) * 600, 0));
			}
			r += 15;
		}
		return infPath;
	}

}