package funkin.states.editors;

import funkin.Mods;

import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.dialogs.CollapsibleDialog;

using funkin.states.editors.ui.ToolKitUtils;

@:build(haxe.ui.ComponentBuilder.build("assets/excluded/ui/modMetaEditor.xml"))
class ModMetaDialog extends CollapsibleDialog {}

class ModMetaEditorState extends UIState
{
	var dialog:ModMetaDialog;

	var bg:FlxSprite;
	var box:FlxSprite;
	var description:FlxText;
	var checkbox:FlxSprite;
	var name:FlxText;
	var icon:FlxSprite;

	var _pack:ModMeta;

	public function new(modPack:String)
	{
		super();
		
		_pack = Mods.getPack(modPack);
	}
	
	override function create()
	{
		super.create();
		
		FlxG.mouse.visible = true;

		bg = new FlxSprite().loadGraphic(Paths.image("menus/menuDesat"));
		add(bg);
		
		box = new FlxSprite().loadGraphic(Paths.image("menus/mods/menubox"));
		// box.scale.set(1.3, 1.3);
		box.updateHitbox();
		box.screenCenter().x += 135;
		add(box);
		
		var text = (_pack == null || _pack.description == null) ? "No description provided." : _pack.description;

		description = new FlxText();
		description.setFormat(Paths.DEFAULT_FONT, 28, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		description.fieldWidth = box.width - 20;
		description.text = text;
		description.setPosition(box.x + 10, box.y + 65);
		add(description);
		
		
		var iPath = _pack == null ? Paths.image("branding/icon/fallback") : Paths.image(_pack.iconFile);
		if (iPath == null) iPath = Paths.image("branding/icon/fallback");

		icon = new FlxSprite();
		icon.loadGraphic(iPath);
		icon.setGraphicSize(45);
		icon.updateHitbox();
		icon.setPosition(box.x + 15, box.y);
		add(icon);

		name = new FlxText();
		name.setFormat(Paths.DEFAULT_FONT, 40, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		name.text = (_pack == null ? Mods.currentModDirectory : _pack.name);
		name.setPosition(icon.x + icon.width + 10, icon.y + (icon.height - name.height) / 2);
		add(name);
		
		add(new FlxSprite().loadGraphic(Paths.image("menus/mods/menuborder1")));
		add(new FlxSprite(685, 645).loadGraphic(Paths.image("menus/mods/menuborder2")));

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42).makeGraphic(FlxG.width, 42, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);
		
		var directoryTxt:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, 'Loaded Mod Directory: ${Mods.currentModDirectory}', 32);
		directoryTxt.setFormat(Paths.DEFAULT_FONT, 32, FlxColor.WHITE, CENTER);
		directoryTxt.scrollFactor.set();
		directoryTxt.text = directoryTxt.text.toUpperCase();
		add(directoryTxt);
		
		dialog = new ModMetaDialog();
		dialog.showDialog(false);
		add(dialog);

		dialog.x = 10;
		dialog.y = 50;
		dialog.bindDialogToView(50);

		bindDialog();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		ToolKitUtils.update();
		
		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(() -> {
				new funkin.states.ModsState();
			});
		}
	}

	function bindDialog()
	{
		dialog.modNameTextField.value = _pack.name;
		dialog.descTextField.value = (_pack.description == null) ? "No description provided." : _pack.description;
		dialog.iconFileTextField.value = (_pack.iconFile != null ? _pack.iconFile : 'branding/icon/icon64');
		dialog.globalCheckbox.selected = _pack.global;
		
		dialog.modNameTextField.onChange = function(event) {
			name.text = dialog.modNameTextField.value;
		}

		dialog.descTextField.onChange = function(event) {
			description.text = dialog.descTextField.value;
		}

		dialog.iconFileTextField.onChange = function(event) {
			var iPath;
			if ((Paths.fileExists('images/' + dialog.iconFileTextField.value + '.png'))) iPath = Paths.image(dialog.iconFileTextField.value);
			else iPath = Paths.image("branding/icon/fallback");
			icon.loadGraphic(iPath);

			icon.setGraphicSize(45);
			icon.updateHitbox();
			icon.setPosition(box.x + 15, box.y);
		}
	}
}
