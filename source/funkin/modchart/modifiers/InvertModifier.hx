package funkin.modchart.modifiers;

import flixel.FlxSprite;
import math.Vector3;
import funkin.data.*;
import funkin.states.*;
import funkin.states.substates.*;
import funkin.objects.*;

class InvertModifier extends NoteModifier
{
	override function getName() return 'invert';

	override function getPos(time:Float, diff:Float, tDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
		if (getValue(player) == 0) return pos;

		var distance = Note.swagWidth * ((data % 2 == 0) ? 1 : -1);
		pos.x += distance * getValue(player);
		return pos;
	}
}
