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

@:build(haxe.ui.ComponentBuilder.build("assets/excluded/ui/charEditor/CharacterSettings.xml"))
class CharacterDialog extends CollapsibleDialog {}

@:build(haxe.ui.ComponentBuilder.build("assets/excluded/ui/charEditor/ToolBar.xml"))
class ToolBar extends MenuBar {}

@:build(haxe.ui.ComponentBuilder.build("assets/excluded/ui/charEditor/characterAnimsList.xml"))
class CharacterAnimList extends Panel {}

@:xml('
<panel id="theVBox" height="50" width="150">

    <vbox id="weener" width="100%">
        <label text="Zoom: 1x" horizontalAlign="center" verticalAlign="center" id="zoomText"/>
        <label text="Animation Frames: ()" horizontalAlign="center" verticalAlign="center" id="animationFramesText"/>
    </vbox>

</panel>
')
class MiscInfo extends Panel {}

// kinda pointless for legend to be extended ngl but well its here

@:xml('
<window title="Information" width="300" height="200" minimizable="false" collapsable="false" >

    <label text="" id="desc" width="100%" height="100%"/>
</window>
')
class LegendWindow extends Window {}

class CharEditorUI extends FlxTypedSpriteContainer<FlxSprite>
{
	// the primary components
	public var characterDialogBox:CharacterDialog;
	public var toolBar:ToolBar;
	public var animationList:CharacterAnimList; // should be fuckign called a panel
	public var miscInfo:MiscInfo;
	
	public function new()
	{
		super();
		
		toolBar = new ToolBar();
		add(toolBar);
		
		toolBar.findComponent('stageBGCheckbox', CheckBox).value = true;
		
		animationList = new CharacterAnimList();
		add(animationList);
		animationList.x = 20;
		animationList.y = toolBar.height + 20;
		
		miscInfo = new MiscInfo();
		add(miscInfo);
		miscInfo.y = toolBar.height + 20;
		miscInfo.x = (FlxG.width - miscInfo.actualComponentWidth) / 2;
		
		characterDialogBox = new CharacterDialog();
		add(characterDialogBox);
		characterDialogBox.showDialog(false);
		
		characterDialogBox.x = FlxG.width - characterDialogBox.actualComponentWidth - 20;
		characterDialogBox.y = toolBar.height + 20;
		
		characterDialogBox.characterTabs.selectedPage = characterDialogBox.characterTabs.getPageById('charSettings');
		
		characterDialogBox.findComponent('iconDisplay', Button).remainPressed = false;
	}
	
	override function destroy()
	{
		super.destroy();
	}
	
	public function setHealthIcon(frame:FlxFrame)
	{
		characterDialogBox.findComponent('iconDisplay', Button).icon = Variant.fromImageData(frame);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (legendWindow != null)
		{
			if (legendWindow.height < 51)
			{
				legendWindow.height = 51;
			}
			if (legendWindow.width < 76)
			{
				legendWindow.width = 76;
			}
		}
	}
	
	public var legendWindow:Null<LegendWindow> = null;
	
	public function spawnLegend()
	{
		legendWindow = new LegendWindow(); // dont drag this over the character settings dialog???
		legendWindow.left = 200;
		legendWindow.top = 50;
		
		legendWindow.findComponent('desc', Label).value = _legend;
		legendWindow.findComponent('desc', Label).fontSize = 12;
		
		FlxG.sound.play(Paths.sound('ui/openPopup'), 0.5);
		
		WindowManager.instance.addWindow(legendWindow);
	}
	
	// i didnt really need to do this but i also didnt want this like
	// annoying big ass line so its jhust like suire dude
	final _legend = MacroUtil.getPrecompliedContent('assets/excluded/ui/charEditor/legend.txt');
}
