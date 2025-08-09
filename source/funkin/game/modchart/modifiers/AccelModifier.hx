package funkin.game.modchart.modifiers;

import math.Vector3;

import flixel.FlxSprite;
import flixel.math.FlxMath;

import funkin.game.modchart.*;

class AccelModifier extends NoteModifier
{ // this'll be boost in ModManager
	inline function lerp(a:Float, b:Float, c:Float)
	{
		return a + (b - a) * c;
	}
	
	override function getName() return 'boost';
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:flixel.FlxSprite)
	{
		var wave = getSubmodValue("wave", player);
		var brake = getSubmodValue("brake", player);
		var boost = getValue(player);
		var effectHeight = 500;
		
		var yAdjust:Float = 0;
		var reverse:Dynamic = modMgr.register.get("reverse");
		var reversePercent = reverse.getReverseValue(data, player);
		var mult = MathUtil.scale(reversePercent, 0, 1, 1, -1);
		
		if (brake != 0)
		{
			var scale = MathUtil.scale(visualDiff, 0, effectHeight, 0, 1);
			var off = visualDiff * scale;
			yAdjust += MathUtil.clamp(brake * (off - visualDiff), -400, 400);
		}
		
		if (boost != 0)
		{
			// ((fYOffset+fEffectHeight/1.2f)/fEffectHeight);
			var off = visualDiff * 1.5 / ((visualDiff + effectHeight / 1.2) / effectHeight);
			yAdjust += MathUtil.clamp(boost * (off - visualDiff), -400, 400);
		}
		
		yAdjust += wave * 20 * FlxMath.fastSin(visualDiff / 38);
		
		pos.y += yAdjust * mult;
		return pos;
	}
	
	override function getSubmods()
	{
		var subMods:Array<String> = ["brake", "wave"];
		return subMods;
	}
}
