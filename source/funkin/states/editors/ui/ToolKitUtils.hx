package funkin.states.editors.ui;

import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.containers.ListView;
import haxe.ui.core.Screen;

import flixel.util.typeLimit.OneOfTwo;
import flixel.FlxG;

import haxe.ui.components.DropDown;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.notifications.NotificationData;

class ToolKitUtils
{
	/**
	 * Clears a dropdown and refills with new items.
	 * @param dropDown 
	 * @param items 
	 */
	public static function populateList(container:Null<OneOfTwo<DropDown, ListView>>, items:Array<DropDownItem>)
	{
		if (container == null) return;
		
		if (container is DropDown)
		{
			var dropDown:DropDown = cast container;
			dropDown.dataSource.removeAll();
			
			for (i in items)
			{
				dropDown.dataSource.add(i);
			}
		}
		else if (container is ListView)
		{
			var list:ListView = cast container;
			list.dataSource.removeAll();
			
			for (i in items)
			{
				list.dataSource.add(i);
			}
		}
	}
	
	public static function addToList(container:Null<OneOfTwo<DropDown, ListView>>, ...items:DropDownItem)
	{
		if (container == null || items.length == 0) return;
		
		if (container is DropDown)
		{
			var dropDown:DropDown = cast container;
			
			for (i in items.toArray())
			{
				dropDown.dataSource.add(i);
			}
		}
		else if (container is ListView)
		{
			var list:ListView = cast container;
			for (i in items.toArray())
			{
				list.dataSource.add(i);
			}
		}
	}
	
	/**
	 * Binds the dialog to the screen size. prevents stupid people doing stupid things
	 * @param dialog 
	 */
	public static function bindDialogToView(dialog:Dialog)
	{
		if (dialog == null) return;
		dialog.onDragEnd = (ui) -> {
			var repositioned = false;
			if (dialog.top < 50)
			{
				dialog.y = 50;
				repositioned = true;
			}
			if ((dialog.top + dialog.dialogTitle.height) > FlxG.height)
			{
				dialog.y = FlxG.height - dialog.dialogTitle.height - 10;
				repositioned = true;
			}
			
			if (dialog.screenLeft < (-dialog.width * 0.5))
			{
				dialog.x = 10;
				repositioned = true;
			}
			
			if (dialog.screenRight > (FlxG.width + (dialog.width * 0.5)))
			{
				dialog.x = FlxG.width - dialog.dialogTitle.width - 10;
				repositioned = true;
			}
			
			if (repositioned) FlxG.sound.play(Paths.sound('ui/bong'));
		}
	}
	
	public static function makeSimpleDropDownItem(id:String):DropDownItem return {id: id, text: id};
	
	public static function isDropDownItem(data:Dynamic):Bool return (data != null && data.id != null && data.text != null); // is this even necessary tbh ?
	
	public static function makeNotification(title:String, body:String, type:NotificationType = Default)
	{
		var data:NotificationData = switch (type)
		{
			case Success:
				{title: title, body: body, icon: 'assets/images/editors/notification_success.png'};
			case Warning:
				{title: title, body: body, icon: 'assets/images/editors/notification_warn.png'};
			case Info:
				{title: title, body: body, icon: 'assets/images/editors/notification_neutral.png'};
				
			default: {title: title, body: body, type: type};
		}
		final noti = NotificationManager.instance.addNotification(data);
		
		switch (type)
		{
			case Success:
				noti.addClass('green-notification');
			case Warning:
				noti.addClass('yellow-notification');
			case Info:
				noti.addClass("blue-notification");
			default:
		}
	}
	
	public static function isHaxeUIHovered(camera:FlxCamera)
	{
		// ok just dont fucking work sure
		// trace(FocusManager.instance.focus);
		var mousePos = FlxG.mouse.getViewPosition(camera);
		return Screen.instance.hasSolidComponentUnderPoint(mousePos.x, mousePos.y);
	}
}

typedef DropDownItem =
{
	id:String,
	text:String
}
