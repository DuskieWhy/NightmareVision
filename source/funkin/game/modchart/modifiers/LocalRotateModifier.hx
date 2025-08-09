package funkin.game.modchart.modifiers;

import math.Vector3;

import flixel.FlxSprite;
import flixel.FlxG;

import funkin.objects.note.*;
import funkin.game.modchart.*;

class LocalRotateModifier extends NoteModifier
{ // this'll be rotateX in ModManager
	override function getName() return '${prefix}rotateX';
	
	override function getOrder() return Modifier.ModifierOrder.POST_REVERSE;
	
	inline function lerp(a:Float, b:Float, c:Float)
	{
		return a + (b - a) * c;
	}
	
	var prefix:String;
	
	public function new(modMgr:ModManager, ?prefix:String = '', ?parent:Modifier)
	{
		this.prefix = prefix;
		super(modMgr, parent);
	}
	
	// thanks schmoovin'
	function rotateV3(vec:Vector3, xA:Float, yA:Float, zA:Float):Vector3
	{
		var rotateZ = MathUtil.rotate(vec.x, vec.y, zA);
		var offZ = new Vector3(rotateZ.x, rotateZ.y, vec.z);
		
		var rotateX = MathUtil.rotate(offZ.z, offZ.y, xA);
		var offX = new Vector3(offZ.x, rotateX.y, rotateX.x);
		
		var rotateY = MathUtil.rotate(offX.x, offX.z, yA);
		var offY = new Vector3(rotateY.x, offX.y, rotateY.y);
		
		rotateZ.putWeak();
		rotateX.putWeak();
		rotateY.putWeak();
		
		return offY;
	}
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
		var x:Float = (FlxG.width * 0.5) - Note.swagWidth - 54 + Note.swagWidth * 1.5;
		switch (player)
		{
			case 0:
				x += FlxG.width * 0.5 - Note.swagWidth * 2 - 100;
			case 1:
				x -= FlxG.width * 0.5 - Note.swagWidth * 2 - 100;
		}
		
		x -= 56;
		
		var origin:Vector3 = new Vector3(x, FlxG.height * 0.5 - Note.swagWidth * 0.5);
		
		var diff = pos.subtract(origin);
		var scale = FlxG.height;
		diff.z *= scale;
		var out = rotateV3(diff, getValue(player), getSubmodValue('${prefix}rotateY', player), getSubmodValue('${prefix}rotateZ', player));
		out.z /= scale;
		return origin.add(out);
	}
	
	override function getSubmods()
	{
		return ['${prefix}rotateY', '${prefix}rotateZ'];
	}
}
