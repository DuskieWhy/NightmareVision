package extensions;

import lime.system.Clipboard;

import openfl.events.KeyboardEvent;

import flixel.addons.ui.FlxUI;
import flixel.text.FlxInputText;
import flixel.input.keyboard.FlxKey;
import flixel.addons.ui.FlxUIInputText;

/**
 * Modified to contain CUT, COPY, PASTE functions @:author PlankDev
 * 
 * Modified to fix mouse overlap checks on different cameras
 */
class FlxUIInputTextEx extends FlxUIInputText
{
	public static inline var COPY_ACTION:String = "copy"; // text copy
	public static inline var PASTE_ACTION:String = "paste"; // text paste
	public static inline var CUT_ACTION:String = "cut"; // text copy
	
	public static inline var COPY_EVENT:String = "copy_input_text"; // copy text in this text field
	public static inline var PASTE_EVENT:String = "paste_input_text"; // paste text in this text field
	public static inline var CUT_EVENT:String = "cut_input_text"; // cut text in this text field
	
	override function onChange(action:String):Void
	{
		super.onChange(action);
		if (broadcastToFlxUI)
		{
			switch (action)
			{
				case COPY_ACTION: // text was copied
					FlxUI.event(COPY_EVENT, this, text, params);
				case PASTE_ACTION: // text was pasted
					FlxUI.event(PASTE_EVENT, this, text, params);
					FlxUI.event(FlxUIInputText.CHANGE_EVENT, this, text, params);
				case CUT_ACTION: // text was cut
					FlxUI.event(CUT_EVENT, this, text, params);
					FlxUI.event(FlxUIInputText.CHANGE_EVENT, this, text, params);
			}
		}
	}
	
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		#if FLX_MOUSE
		// Set focus and caretIndex as a response to mouse press
		
		if (FlxG.mouse.justPressed)
		{
			var hadFocus:Bool = hasFocus;
			if (FlxG.mouse.overlaps(this, getDefaultCamera()))
			{
				caretIndex = getCaretIndex();
				hasFocus = true;
				if (!hadFocus && focusGained != null) focusGained();
			}
			else
			{
				hasFocus = false;
				if (hadFocus && focusLost != null) focusLost();
			}
		}
		#end
	}
	
	override function onKeyDown(e:KeyboardEvent):Void
	{
		final key:FlxKey = e.keyCode;
		
		if (hasFocus)
		{
			// MODIFICATIONS START
			final ctrlPressed:Bool = #if macos e.commandKey #else e.ctrlKey #end;
			
			if (ctrlPressed)
			{
				switch (key)
				{
					case C: // copy func
						Clipboard.text = text;
						onChange(COPY_ACTION);
						return;
						
					case V: // paste func
						var newText:String = filter(Clipboard.text);
					
						if (newText.length > 0 && (maxLength == 0 || (text.length + newText.length) < maxLength))
						{
							text = insertSubstring(text, newText, caretIndex);
							caretIndex += newText.length;
							onChange(INPUT_ACTION);
							onChange(PASTE_ACTION);
						}
					
						return;
					case X: // cut func
						Clipboard.text = text;
						text = '';
						caretIndex = 0;
						onChange(INPUT_ACTION);
						onChange(CUT_ACTION);
						
						return;
						
					default:
				}
			}
			// MODIFICATIONS END
			
			switch (key)
			{
				case SHIFT | CONTROL | BACKSLASH | ESCAPE:
					return;
				case LEFT:
					if (caretIndex > 0)
					{
						caretIndex--;
						text = text; // forces scroll update
					}
				case RIGHT:
					if (caretIndex < text.length)
					{
						caretIndex++;
						text = text; // forces scroll update
					}
				case END:
					caretIndex = text.length;
					text = text; // forces scroll update
				case HOME:
					caretIndex = 0;
					text = text;
				case BACKSPACE:
					if (caretIndex > 0)
					{
						caretIndex--;
						text = text.substring(0, caretIndex) + text.substring(caretIndex + 1);
						onChange(BACKSPACE_ACTION);
					}
				case DELETE:
					if (text.length > 0 && caretIndex < text.length)
					{
						text = text.substring(0, caretIndex) + text.substring(caretIndex + 1);
						onChange(DELETE_ACTION);
					}
				case ENTER:
					onChange('enter');
				// case V if (e.ctrlKey):
				// 	// Reapply focus  when tabbing back into the window and selecting the field
				// 	#if (js && html5)
				// 	FlxG.stage.window.textInputEnabled = true;
				// 	#else
				// 	var clipboardText:String = Clipboard.text;
				// 	if (clipboardText != null) pasteClipboardText(clipboardText);
				// 	#end
				default:
					// Actually add some text
					if (e.charCode == 0) // non-printable characters crash String.fromCharCode
					{
						return;
					}
					final newText = filter(String.fromCharCode(e.charCode));
					
					if (newText.length > 0 && (maxLength == 0 || (text.length + newText.length) <= maxLength))
					{
						text = insertSubstring(text, newText, caretIndex);
						caretIndex++;
						onChange(INPUT_ACTION);
					}
			}
		}
	}
}
