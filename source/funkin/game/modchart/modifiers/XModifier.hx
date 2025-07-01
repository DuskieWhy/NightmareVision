package funkin.game.modchart.modifiers;

import math.Vector3;

import funkin.states.*;
import funkin.objects.*;

class XModifier extends NoteModifier
{
	override function getName() return 'xmod';
	
	override function shouldExecute(player:Int, val:Float) return true;
	
	override function updateNote(beat:Float, daNote:Note, pos:Vector3, player:Int)
	{
		daNote.multSpeed = getValue(player) * getSubmodValue('xmod' + daNote.noteData, player);
	}
	
	override function getSubmods()
	{
		var subMods:Array<String> = [];
		for (i in 0...PlayState.SONG.keys)
			subMods.push('xmod$i');
			
		return subMods;
	}
}
