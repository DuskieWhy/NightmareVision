package funkin.game.modchart.modifiers;

import math.Vector3;

import flixel.math.FlxPoint;

import funkin.game.modchart.Modifier.ModifierOrder;
import funkin.states.*;
import funkin.objects.*;

class ScaleModifier extends NoteModifier
{
	override function getName() return 'mini';
	
	override function getOrder() return PRE_REVERSE;
	
	inline function lerp(a:Float, b:Float, c:Float)
	{
		return a + (b - a) * c;
	}
	
	function getScale(sprite:Dynamic, scale:FlxPoint, data:Int, player:Int)
	{
		var y = scale.y;
		scale.x *= 1 - getValue(player);
		scale.y *= 1 - getValue(player);
		var miniX = getSubmodValue("miniX", player) + getSubmodValue('mini${data}X', player);
		var miniY = getSubmodValue("miniY", player) + getSubmodValue('mini${data}Y', player);
		
		scale.x *= 1 - miniX;
		scale.y *= 1 - miniY;
		var angle = 0;
		
		var stretch = getSubmodValue("stretch", player) + getSubmodValue('stretch${data}', player);
		var squish = getSubmodValue("squish", player) + getSubmodValue('squish${data}', player);
		
		var stretchX = lerp(1, 0.5, stretch);
		var stretchY = lerp(1, 2, stretch);
		
		var squishX = lerp(1, 2, squish);
		var squishY = lerp(1, 0.5, squish);
		
		scale.x *= (Math.sin(angle * Math.PI / 180) * squishY) + (Math.cos(angle * Math.PI / 180) * squishX);
		scale.x *= (Math.sin(angle * Math.PI / 180) * stretchY) + (Math.cos(angle * Math.PI / 180) * stretchX);
		
		scale.y *= (Math.cos(angle * Math.PI / 180) * stretchY) + (Math.sin(angle * Math.PI / 180) * stretchX);
		scale.y *= (Math.cos(angle * Math.PI / 180) * squishY) + (Math.sin(angle * Math.PI / 180) * squishX);
		if ((sprite is Note) && sprite.isSustainNote) scale.y = y;
		
		return scale;
	}
	
	override function shouldExecute(player:Int, val:Float) return true;
	
	override function ignorePos() return true;
	
	override function ignoreUpdateReceptor() return false;
	
	override function ignoreUpdateNote() return false;
	
	override function updateNote(beat:Float, note:Note, pos:Vector3, player:Int)
	{
		var scale:FlxPoint = null;
		if (getSubmodValue('noteScaleX', player) > 0 || getSubmodValue('noteScaleY', player) > 0)
		{
			var scaleX = getSubmodValue("noteScaleX", player);
			var scaleY = getSubmodValue("noteScaleY", player);
			if (scaleX == 0) scaleX = note.defScale.x;
			if (scaleY == 0) scaleY = note.defScale.y;
			scale = getScale(note, FlxPoint.weak(scaleX, scaleY), note.noteData, player);
		}
		else scale = getScale(note, FlxPoint.weak(note.defScale.x, note.defScale.y), note.noteData, player);
		
		if (note.isSustainNote) scale.y = note.defScale.y;
		
		note.scale.copyFrom(scale);
		scale.putWeak();
	}
	
	override function updateReceptor(beat:Float, receptor:StrumNote, pos:Vector3, player:Int)
	{
		var scale:FlxPoint = null;
		if (getSubmodValue('receptorScaleX', player) > 0 || getSubmodValue('receptorScaleY', player) > 0)
		{
			var scaleX = getSubmodValue("receptorScaleX", player);
			var scaleY = getSubmodValue("receptorScaleY", player);
			if (scaleX == 0) scaleX = receptor.defScale.x;
			if (scaleY == 0) scaleY = receptor.defScale.y;
			scale = getScale(receptor, FlxPoint.weak(scaleX, scaleY), receptor.noteData, player);
		}
		else scale = getScale(receptor, FlxPoint.weak(receptor.defScale.x, receptor.defScale.y), receptor.noteData, player);
		
		var scale = getScale(receptor, FlxPoint.weak(receptor.defScale.x, receptor.defScale.y), receptor.noteData, player);
		receptor.scale.copyFrom(scale);
		scale.putWeak();
	}
	
	override function getSubmods()
	{
		var subMods:Array<String> = [
			"squish",
			"stretch",
			"miniX",
			"miniY",
			"receptorScaleX",
			"receptorScaleY",
			"noteScaleX",
			"noteScaleY"
		];
		
		var receptors = modMgr.receptors[0];
		var kNum = receptors.length;
		for (i in 0...PlayState.SONG.keys)
		{
			subMods.push('mini${i}X');
			subMods.push('mini${i}Y');
			subMods.push('squish${i}');
			subMods.push('stretch${i}');
			subMods.push('receptor${i}ScaleX');
			subMods.push('receptor${i}ScaleY');
			subMods.push('note${i}ScaleX');
			subMods.push('note${i}ScaleY');
		}
		return subMods;
	}
}
