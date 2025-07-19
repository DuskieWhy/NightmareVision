package funkin.backend.plugins;

import openfl.display.BitmapData;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.transition.FlxTransitionableState;

/**
 * Plugin that shows debug content in game without the need of a console
 */
@:nullSafety
class DebugTextPlugin extends FlxTypedGroup<DebugText>
{
	static var instance:Null<DebugTextPlugin> = null;
	
	public static function init()
	{
		if (instance == null)
		{
			FlxG.plugins.addPlugin(instance = new DebugTextPlugin());
			FlxG.signals.postStateSwitch.add(clearTxt);
		}
	}
	
	public static function addText(message:String, colour:FlxColor = FlxColor.WHITE)
	{
		if (instance == null) return;
		
		var text = instance.recycle(DebugText, () -> new DebugText(message, colour));
		text.text = message;
		text.color = colour;
		text.disableTime = 6;
		text.alpha = 1;
		
		instance.insert(0, text);
		
		instance.forEachAlive((spr:DebugText) -> {
			spr.y += text.height;
		});
		text.y = 10;
		
		instance.camera = CameraUtil.lastCamera;
	}
	
	static function clearTxt()
	{
		if (instance == null) return;
		
		instance.forEachAlive(spr -> spr.kill());
	}
}

class DebugText extends FlxText
{
	public var disableTime:Float = 6;
	
	public function new(text:String, color:FlxColor = FlxColor.WHITE)
	{
		super(10, 10, FlxG.width, text, 16);
		setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scrollFactor.set();
		borderSize = 1;
		this.color = color;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		disableTime -= elapsed;
		if (y >= FlxG.height) kill();
		if (disableTime <= 0)
		{
			kill();
		}
		else if (disableTime < 1) alpha = disableTime;
	}
}
