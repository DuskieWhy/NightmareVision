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
		if (instance == null) FlxG.plugins.addPlugin(instance = new DebugTextPlugin());
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
	
	// overriden to modify its key
	override function regenGraphic():Void
	{
		if (textField == null || !_regen) return;
		
		final oldWidth:Int = graphic != null ? graphic.width : 0;
		final oldHeight:Int = graphic != null ? graphic.height : FlxText.VERTICAL_GUTTER;
		
		final newWidthFloat:Float = textField.width;
		final newHeightFloat:Float = _autoHeight ? textField.textHeight + FlxText.VERTICAL_GUTTER : textField.height;
		
		var borderWidth:Float = 0;
		var borderHeight:Float = 0;
		switch (borderStyle)
		{
			case SHADOW if (_shadowOffset.x != 1 || _shadowOffset.y != 1):
				borderWidth += Math.abs(_shadowOffset.x);
				borderHeight += Math.abs(_shadowOffset.y);
				
			case SHADOW: // With the default shadowOffset value
				borderWidth += Math.abs(borderSize);
				borderHeight += Math.abs(borderSize);
				
			case SHADOW_XY(offsetX, offsetY):
				borderWidth += Math.abs(offsetX);
				borderHeight += Math.abs(offsetY);
				
			case OUTLINE_FAST | OUTLINE:
				borderWidth += Math.abs(borderSize) * 2;
				borderHeight += Math.abs(borderSize) * 2;
				
			case NONE:
		}
		
		final newWidth:Int = Math.ceil(newWidthFloat + borderWidth);
		final newHeight:Int = Math.ceil(newHeightFloat + borderHeight);
		
		// prevent text height from shrinking on flash if text == ""
		if (textField.textHeight != 0 && (oldWidth != newWidth || oldHeight != newHeight))
		{
			// Need to generate a new buffer to store the text graphic
			final key:String = FlxG.bitmap.getUniqueKey("NMV_DEBUGtext");
			makeGraphic(newWidth, newHeight, FlxColor.TRANSPARENT, false, key);
			width = Math.ceil(newWidthFloat);
			height = Math.ceil(newHeightFloat);
			
			#if FLX_TRACK_GRAPHICS
			graphic.trackingInfo = 'text($ID, $text)';
			#end
			
			if (_hasBorderAlpha) _borderPixels = graphic.bitmap.clone();
			
			if (_autoHeight) textField.height = newHeight;
			
			_flashRect.x = 0;
			_flashRect.y = 0;
			_flashRect.width = newWidth;
			_flashRect.height = newHeight;
		}
		else // Else just clear the old buffer before redrawing the text
		{
			graphic.bitmap.fillRect(_flashRect, FlxColor.TRANSPARENT);
			if (_hasBorderAlpha)
			{
				if (_borderPixels == null) _borderPixels = new BitmapData(frameWidth, frameHeight, true);
				else _borderPixels.fillRect(_flashRect, FlxColor.TRANSPARENT);
			}
		}
		
		if (textField != null && textField.text != null)
		{
			// Now that we've cleared a buffer, we need to actually render the text to it
			copyTextFormat(_defaultFormat, _formatAdjusted);
			
			_matrix.identity();
			
			applyBorderStyle();
			applyBorderTransparency();
			applyFormats(_formatAdjusted, false);
			
			drawTextFieldTo(graphic.bitmap);
		}
		
		_regen = false;
		resetFrame();
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
