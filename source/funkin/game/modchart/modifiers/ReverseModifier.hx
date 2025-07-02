package funkin.game.modchart.modifiers;

import math.Vector3;

import flixel.math.FlxRect;
import flixel.FlxSprite;
import flixel.FlxG;

import funkin.game.modchart.*;
import funkin.states.*;
import funkin.objects.*;
import funkin.game.modchart.Modifier.ModifierOrder;

class ReverseModifier extends NoteModifier
{
	inline function lerp(a:Float, b:Float, c:Float)
	{
		return a + (b - a) * c;
	}
	
	override function getOrder() return REVERSE;
	
	override function getName() return 'reverse';
	
	public function getReverseValue(dir:Int, player:Int, ?scrolling = false)
	{
		var suffix = '';
		if (scrolling == true) suffix = 'Scroll';
		var receptors = modMgr.receptors[player];
		var kNum = receptors.length;
		var val:Float = 0;
		if (dir >= kNum / 2) val += getSubmodValue("split" + suffix, player);
		
		if ((dir % 2) == 1) val += getSubmodValue("alternate" + suffix, player);
		
		var first = kNum / 4;
		var last = kNum - 1 - first;
		
		if (dir >= first && dir <= last) val += getSubmodValue("cross" + suffix, player);
		
		if (suffix == '') val += getValue(player) + getSubmodValue("reverse" + Std.string(dir), player);
		else val += getSubmodValue("reverse" + suffix, player);
		
		if (getSubmodValue("unboundedReverse", player) == 0)
		{
			val %= 2;
			if (val > 1) val = 2 - val;
		}
		
		if (ClientPrefs.downScroll) val = 1 - val;
		
		return val;
	}
	
	public function getScrollReversePerc(dir:Int, player:Int) return getReverseValue(dir, player) * 100;
	
	override function shouldExecute(player:Int, val:Float) return true;
	
	override function ignoreUpdateNote() return false;
	
	override function updateNote(beat:Float, daNote:Note, pos:Vector3, player:Int)
	{
		if (daNote.isSustainNote)
		{
			var y = pos.y + daNote.offsetY;
			var revPerc = getReverseValue(daNote.noteData, player);
			var strumLine = modMgr.receptors[player][daNote.noteData];
			var shitGotHit = (strumLine.sustainReduce
				&& daNote.isSustainNote
				&& (daNote.mustPress || !daNote.ignoreNote)
				&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))));
			if (shitGotHit)
			{
				var center:Float = strumLine.y + Note.swagWidth * 0.5;
				if (revPerc >= 0.5)
				{
					if (y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
					{
						var swagRect = getNoteRect(daNote);
						swagRect.height = (center - y) / daNote.scale.y;
						swagRect.y = daNote.frameHeight - swagRect.height;
						
						daNote.clipRect = swagRect;
					}
				}
				else
				{
					if (y + daNote.offset.y * daNote.scale.y <= center)
					{
						var swagRect = getNoteRect(daNote);
						swagRect.y = (center - y) / daNote.scale.y;
						swagRect.height -= swagRect.y;
						
						daNote.clipRect = swagRect;
					}
				}
			}
		}
	}
	
	inline function getNoteRect(note:Note)
	{
		final rect = note.clipRect ?? new FlxRect();
		rect.x = 0;
		rect.y = 0;
		rect.width = note.frameWidth;
		rect.height = note.frameHeight;
		return rect;
	}
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
		var perc = getReverseValue(data, player);
		var shift = CoolUtil.scale(perc, 0, 1, 50, FlxG.height - 150);
		var mult = CoolUtil.scale(perc, 0, 1, 1, -1);
		shift = CoolUtil.scale(getSubmodValue("centered", player), 0, 1, shift, (FlxG.height / 2) - 56);
		
		pos.y = shift + (visualDiff * mult);
		
		// TODO: rewrite this, I don't like this and I feel it could be solved better by changing the note's origin instead -neb
		// also move it to Reverse modifier
		if ((obj is Note))
		{
			var note:Note = cast obj;
			if (note.isSustainNote && perc > 0)
			{
				var daY = pos.y;
				var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
				var songSpeed:Float = PlayState.instance.songSpeed * note.multSpeed;
				if (note.animation.curAnim.name.endsWith('end${note.noteData}'))
				{
					daY += 10.5 * (fakeCrochet * 0.0025) * 1.5 * songSpeed + (46 * (songSpeed - 1));
					daY -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
					/*if (PlayState.isPixelStage)
							daY += 8;
						else */
					daY -= 19;
				}
				daY += (Note.swagWidth * 0.5) - (60.5 * (songSpeed - 1));
				daY += 27.5 * ((PlayState.SONG.bpm * 0.01) - 1) * (songSpeed - 1);
				
				pos.y = lerp(pos.y, daY, perc);
			}
		}
		
		return pos;
	}
	
	override function getSubmods()
	{
		var subMods:Array<String> = [
			"cross",
			"split",
			"alternate",
			"reverseScroll",
			"crossScroll",
			"splitScroll",
			"alternateScroll",
			"centered",
			"unboundedReverse"
		];
		
		var receptors = modMgr.receptors[0];
		for (i in 0...PlayState.SONG.keys)
		{
			subMods.push('reverse${i}');
		}
		return subMods;
	}
}
