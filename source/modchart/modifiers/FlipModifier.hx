package modchart.modifiers;

import flixel.FlxSprite;
import math.Vector3;
import meta.data.*;
import meta.states.*;
import meta.states.substate.*;
import gameObjects.*;

class FlipModifier extends NoteModifier {
	override function getName()return 'flip';

	override function getPos(time:Float, diff:Float, tDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite){
		if (getValue(player) == 0)
			return pos;

		var receptors = modMgr.receptors[player];

		var distance = Note.swagWidth * (receptors.length* 0.5) * (1.5 - data);
		pos.x += distance * getValue(player);
        return pos;
    }
}