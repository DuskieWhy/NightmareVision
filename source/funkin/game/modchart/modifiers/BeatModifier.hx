package funkin.game.modchart.modifiers;

import math.Vector3;

import flixel.FlxSprite;
import flixel.math.FlxMath;

import funkin.states.*;
import funkin.game.modchart.*;

class BeatModifier extends NoteModifier
{
	override function getName() return 'beat';
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
		if (getValue(player) == 0) return pos;
		var accelTime:Float = 0.3;
		var totalTime:Float = 0.7;
		@:privateAccess
		var beat = PlayState.instance.curDecBeat + accelTime;
		var evenBeat = beat % 2 != 0;
		
		if (beat < 0) return pos;
		
		beat -= Math.floor(beat);
		beat += 1;
		beat -= Math.floor(beat);
		if (beat >= totalTime) return pos;
		
		var amount:Float = 0;
		if (beat < accelTime)
		{
			amount = MathUtil.scale(beat, 0, accelTime, 0, 1);
			amount *= amount;
		}
		else
		{
			amount = MathUtil.scale(beat, accelTime, totalTime, 1, 0);
			amount = 1 - (1 - amount) * (1 - amount);
		}
		if (evenBeat) amount *= -1;
		
		var shift = 40 * amount * FlxMath.fastSin((visualDiff / 30) + Math.PI / 2);
		pos.x += getValue(player) * shift;
		return pos;
	}
}
