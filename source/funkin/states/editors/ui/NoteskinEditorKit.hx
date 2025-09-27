package funkin.states.editors.ui;

import haxe.ui.containers.dialogs.Dialogs.FileDialogTypes;
import haxe.ui.containers.dialogs.SaveFileDialog;
import haxe.ui.backend.SaveFileDialogBase;
import haxe.ui.components.Label;
import haxe.ui.containers.windows.WindowManager;
import haxe.ui.containers.windows.Window;
import haxe.ui.components.Button;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxImageFrame;

import haxe.ui.util.Variant;
import haxe.ui.components.Image;
import haxe.ui.core.ItemRenderer;
import haxe.ui.components.CheckBox;

import flixel.group.FlxSpriteContainer.FlxTypedSpriteContainer;

import haxe.ui.containers.HBox;
import haxe.ui.containers.Panel;
import haxe.ui.containers.VBox;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;

@:build(haxe.ui.ComponentBuilder.build('assets/excluded/ui/noteskinEditor/settings.xml'))
class Settings extends CollapsibleDialog {}

@:build(haxe.ui.ComponentBuilder.build("assets/excluded/ui/noteskinEditor/ToolBar.xml"))
class NToolBar extends MenuBar {}

class NoteEditorUI extends FlxTypedSpriteContainer<FlxSprite>
{
	public var settingsBox:Settings;
	public var toolBar:NToolBar;
	
	public function new()
	{
		super();
		
		toolBar = new NToolBar();
		add(toolBar);
		
		settingsBox = new Settings();
		settingsBox.showDialog(false);
		settingsBox.x = 665;
		settingsBox.y = toolBar.height + 20;
		add(settingsBox);
	}
	
	override function destroy()
	{
		super.destroy();
	}
}
