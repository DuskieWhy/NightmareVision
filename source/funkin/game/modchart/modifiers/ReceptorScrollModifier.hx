package funkin.game.modchart.modifiers;

import math.Vector3;

import flixel.FlxG;

import funkin.states.*;
import funkin.objects.note.*;
import funkin.game.modchart.*;

class ReceptorScrollModifier extends NoteModifier
{
	inline function lerp(a:Float, b:Float, c:Float)
	{
		return a + (b - a) * c;
	}
	
	// var moveSpeed:Float = 800;
	var moveSpeed:Float = Conductor.crotchet * 3; // gotta keep da sustain segments together so it doesnt look so shit
	
	override function getName() return 'receptorScroll';
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:flixel.FlxSprite)
	{
		var diff = timeDiff;
		var sPos = Conductor.songPosition;
		var vDiff = -(-diff - sPos) / moveSpeed;
		var reversed = Math.floor(vDiff) % 2 == 0;
		
		var startY = pos.y;
		var revPerc = reversed ? 1 - vDiff % 1 : vDiff % 1;
		// haha perc 30
		var upscrollOffset = 50;
		var downscrollOffset = FlxG.height - 150;
		
		var endY = upscrollOffset + ((downscrollOffset - Note.swagWidth / 2) * revPerc);
		
		pos.y = lerp(startY, endY, getValue(player));
		
		return pos;
	}
	
	override function updateNote(beat:Float, daNote:Note, pos:Vector3, player:Int)
	{
		if (getValue(player) == 0) return;
		var speed = PlayState.instance.songSpeed * daNote.multSpeed;
		
		var timeDiff = (daNote.strumTime - Conductor.songPosition);
		
		var diff = timeDiff;
		var sPos = Conductor.songPosition;
		
		var songPos = sPos / moveSpeed;
		var notePos = -(-diff - sPos) / moveSpeed;
		
		if (Math.floor(songPos) != Math.floor(notePos))
		{
			daNote.alphaMod *= .5;
			
			// i do not see this genuinely used anywhere?
			// daNote.zIndex++;
		}
		if (daNote.wasGoodHit) daNote.garbage = true;
	}
}
