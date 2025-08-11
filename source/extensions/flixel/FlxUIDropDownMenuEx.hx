package extensions.flixel;

import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.FlxG;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.StrNameLabel;

/*
	The differences are the following:
	* Support to scrolling up/down with mouse wheel or arrow keys
	* THe default drop direction is "Down" instead of "Automatic"

 */
class FlxUIDropDownMenuEx extends FlxUIDropDownMenu
{
	var currentScroll:Int = 0; // Handles the scrolling
	
	public var canScroll:Bool = true;
	
	public function new(X:Float = 0, Y:Float = 0, DataList:Array<StrNameLabel>, ?Callback:String->Void, ?Header:FlxUIDropDownHeader, ?DropPanel:FlxUI9SliceSprite, ?ButtonList:Array<FlxUIButton>,
			?UIControlCallback:Bool->FlxUIDropDownMenu->Void)
	{
		super(X, Y, DataList, Callback, Header, DropPanel, ButtonList, UIControlCallback);
		dropDirection = Down;
	}
	
	override function updateButtonPositions():Void
	{
		var buttonHeight = header.background.height;
		dropPanel.y = header.background.y;
		if (dropsUp()) dropPanel.y -= getPanelHeight();
		else dropPanel.y += buttonHeight;
		
		var offset = dropPanel.y;
		for (i in 0...currentScroll)
		{ // Hides buttons that goes before the current scroll
			var button:FlxUIButton = list[i];
			if (button != null)
			{
				button.y = -99999;
			}
		}
		for (i in currentScroll...list.length)
		{
			var button:FlxUIButton = list[i];
			if (button != null)
			{
				button.y = offset;
				offset += buttonHeight;
			}
		}
	}
	
	override function checkClickOff()
	{
		if (dropPanel.visible)
		{
			if (list.length > 1 && canScroll)
			{
				if (FlxG.mouse.wheel > 0 || FlxG.keys.justPressed.UP)
				{
					// Go up
					--currentScroll;
					if (currentScroll < 0) currentScroll = 0;
					updateButtonPositions();
				}
				else if (FlxG.mouse.wheel < 0 || FlxG.keys.justPressed.DOWN)
				{
					// Go down
					currentScroll++;
					if (currentScroll >= list.length) currentScroll = list.length - 1;
					updateButtonPositions();
				}
			}
			
			if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(this, getDefaultCamera()))
			{
				showList(false);
			}
		}
	}
	
	override function showList(b:Bool)
	{
		super.showList(b);
		if (currentScroll != 0)
		{
			currentScroll = 0;
			updateButtonPositions();
		}
	}
}
