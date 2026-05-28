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
			FlxG.signals.preStateSwitch.add(clearTxt);
		}
	}
	
	static inline function posText()
	{
		if (instance == null) return;
		
		var count = 0;
		instance.forEachAlive((temp:DebugText) -> {
			temp.y = 25 + (temp.height * count);
			count++;
		});
	}
	
	static function grabText(message:String, colour:FlxColor):DebugText
	{
		final sanitized = message.substring(0, message.indexOf(']') + 1);
		
		if (!DebugText.map.exists(sanitized) && instance != null)
		{
			final ret = instance.recycle(DebugText, () -> new DebugText(message, colour));
			return ret;
		}
		else
		{
			var ret = DebugText.map.get(sanitized);
			ret?.resetValues();
			
			return ret ?? new DebugText(message, colour);
		}
	}
	
	public static function addText(message:String, colour:FlxColor = FlxColor.WHITE)
	{
		if (instance == null) return;
		
		final text = grabText(message, colour);
		text.setText(message);
		text.disableTime = 4;
		text.alpha = 1;
		
		posText();
		
		instance.insert(0, text);
		
		instance.camera = CameraUtil.lastCamera;
	}
	
	static function clearTxt()
	{
		if (instance == null) return;
		
		instance.clear();
		DebugText.clearMap();
	}
}

class DebugText extends FlxText
{
	public static var map:Map<String, DebugText> = new Map<String, DebugText>();
	
	public var disableTime:Float = 4;
	public var traceCount:Int = 1;
	public var markupColor:FlxColor;
	
	private var _trace = 'No trace exists';
	
	public function new(text:String, color:FlxColor = FlxColor.WHITE)
	{
		super(10, 10, FlxG.width, text, 16);
		
		// embedded font because fuuck you
		setFormat(('assets/fonts/consolas.ttf'), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scrollFactor.set();
		borderSize = 1.25;
		this.color = color;
		
		this._trace = text;
		
		final sanitized = text.substring(0, text.indexOf(']') + 1);
		
		if (!map.exists(sanitized)) map.set(sanitized, this);
	}
	
	public function setText(input:String)
	{
		this._trace = input;
	}
	
	public function resetValues()
	{
		this.traceCount += 1;
		this.disableTime = 4;
		this.alpha = 1;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (this != null)
		{
			this.text = '${traceCount > 1 ? '[$traceCount] - ' : ''}$_trace';
		}
		
		disableTime -= elapsed;
		if (y >= FlxG.height) kill();
		
		if (disableTime <= 0)
		{
			map.remove(_trace);
			kill();
		}
		else if (disableTime < 1) alpha = disableTime;
	}
	
	public static function clearMap()
	{
		for (i in map)
			i?.destroy();
			
		map.clear();
	}
}
