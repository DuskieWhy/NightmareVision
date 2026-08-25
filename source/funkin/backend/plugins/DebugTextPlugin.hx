package funkin.backend.plugins;

import funkin.backend.DebugDisplay.FpsDisplayMode;

import openfl.display.BitmapData;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.transition.FlxTransitionableState;

/**
 * Plugin that shows debug content in game without the need of a console
 */
@:nullSafety
class DebugTextPlugin extends FlxTypedGroup<DebugText>
{
	@:nullSafety(Off)
	public static var instance:DebugTextPlugin;
	
	public static function init()
	{
		if (instance == null)
		{
			FlxG.plugins.addPlugin(instance = new DebugTextPlugin());
			FlxG.signals.preStateSwitch.add(instance.clearTxt);
			#if debug
			FlxG.console.registerClass(DebugTextPlugin);
			#end
		}
	}
	
	public function repositionTexts()
	{
		if (instance == null) return;
		
		var startY:Float = 25;
		if (DebugDisplay.instance != null && DebugDisplay.instance.visible) startY += DebugDisplay.instance.textUnderlay.height + 5;
		
		var count:Int = 0;
		instance.forEachAlive((temp:DebugText) -> {
			temp.y = startY + (temp.height * count);
			count++;
		});
	}
	
	inline function grabText(str:String):DebugText
	{
		var text:Null<DebugText> = null;
		for (instance in members)
		{
			if (instance?.alive && instance._trace == str)
			{
				text = instance;
				break;
			}
		}
		return text ?? recycle(DebugText);
	}
	
	public function addText(message:String, colour:FlxColor = FlxColor.WHITE)
	{
		if (instance == null) return;
		
		final text = grabText(message);
		text.resetText();
		text.setText(message, colour);
		
		remove(text, true);
		insert(0, text);
		
		repositionTexts();
		
		camera = CameraUtil.lastCamera;
	}
	
	function clearTxt()
	{
		forEach(text -> {
			text = FlxDestroyUtil.destroy(text);
		});
		clear();
	}
}

class DebugText extends FlxText
{
	private final UNDERLAY_PADDING = 5;
	
	public var disableTime:Float = 4;
	public var traceCount:Int = 1;
	public var markupColor:FlxColor;
	
	public var _trace = '';
	
	private var _underlay:FlxSprite;
	
	var _dirtyText:Bool = false;
	
	public function new(text:String, color:FlxColor = FlxColor.WHITE)
	{
		super(10, 10, FlxG.width, text, 16);
		
		// embedded font because fuuck you
		setFormat(('assets/fonts/consolas.ttf'), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scrollFactor.set();
		borderSize = 1.25;
		this.color = color;
		
		this._trace = text;
		
		_underlay = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		_underlay.color = FlxColor.BLACK;
		_underlay.alpha = 0;
		_underlay.scrollFactor.set();
	}
	
	public inline function setText(input:String, colour:FlxColor = FlxColor.WHITE)
	{
		_trace = input;
		color = colour;
		_dirtyText = true;
	}
	
	public function resetText()
	{
		traceCount += 1;
		disableTime = 4;
		alpha = 1;
	}
	
	override function kill()
	{
		traceCount = 0;
		super.kill();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		disableTime -= elapsed;
		if (y >= FlxG.height) kill();
		
		if (disableTime <= 0) kill();
		else if (disableTime < 1) alpha = disableTime;
	}
	
	override function draw()
	{
		if (_underlay.exists)
		{
			_underlay.scale.set(this.textField.textWidth + (UNDERLAY_PADDING * 2), height);
			_underlay.updateHitbox();
			
			_underlay.setPosition(x - (UNDERLAY_PADDING / 2), y);
			_underlay.camera = this.camera;
			_underlay.alpha = this.alpha * 0.4;
			
			_underlay.draw();
		}
		
		if (_dirtyText)
		{
			text = '${traceCount > 1 ? '[$traceCount] - ' : ''}$_trace';
			_dirtyText = false;
		}
		
		super.draw();
	}
	
	override function destroy()
	{
		_underlay.destroy();
		super.destroy();
	}
}
