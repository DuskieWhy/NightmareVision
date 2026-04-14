package funkin.states.editors;

import haxe.Json;
import haxe.ui.util.Variant;
import haxe.ui.backend.flixel.UISubState;
import haxe.ui.containers.dialogs.Dialog;

import openfl.net.FileFilter;

import flixel.graphics.frames.FlxFrame;

import funkin.data.SongMetaData.SongMeta;
import funkin.objects.HealthIcon;
import funkin.data.SongMetaData;

using funkin.states.editors.ui.ToolKitUtils;

@:build(haxe.ui.ComponentBuilder.build("assets/excluded/ui/metaEditor.xml"))
class MetaDialog extends Dialog {}

class SongMetaEditor extends UISubState
{
	var dialog:MetaDialog;
	var iconDummy:HealthIcon;
	
	var _song:Null<String> = null;
	
	public function new(?file:String)
	{
		super();
		_song = file;
	}
	
	override function create()
	{
		super.create();
		
		FlxG.mouse.visible = true;
		
		root.camera = CameraUtil.lastCamera;
		
		iconDummy = new HealthIcon().changeIcon('face');
		add(iconDummy);
		iconDummy.visible = false;
		
		dialog = new MetaDialog();
		dialog.showDialog(true);
		add(dialog);
		
		dialog.onDialogClosed = (ev) -> close();
		
		ToolKitUtils.bindDialogToView(dialog);
		
		dialog.iconField.onChange = (ev) -> {
			iconDummy.changeIcon(dialog.iconField.value);
			setIcon(iconDummy.frame);
		}
		
		dialog.iconColourButton.onClick = (ev) -> {
			updateColour(CoolUtil.dominantColor(iconDummy), true);
		}
		
		dialog.colourPicker.onChange = (ev) -> {
			final col = FlxColor.fromString(ev.value.toString());
			updateColour(col);
		}
		
		dialog.loadButton.onClick = (ev) -> {
			FileUtil.browseForFile({typeFilter: [new FileFilter('json', 'json')]}, (str) -> {
				loadMeta(str);
				_song = null;
			});
		}
		
		dialog.clearButton.onClick = (ev) -> clearMeta();
		
		dialog.saveButton.onClick = (ev) -> saveMeta();
		
		setIcon(iconDummy.frame);
		
		if (_song != null)
		{
			_song = Paths.sanitize(_song);
			var songPath = Paths.getPath('songs/$_song/meta.json', null, true);
			loadMeta(songPath);
		}
	}
	
	function clearMeta()
	{
		dialog.displayNameField.value = '';
		
		dialog.iconField.changeSilent('');
		
		dialog.difficultyField.value = '';
		
		iconDummy.changeIcon('face');
		setIcon(iconDummy.frame);
		
		updateColour(FlxColor.BLACK, true);
		
		dialog.artistField.value = '';
		dialog.composerField.value = '';
		dialog.charterfield.value = '';
		dialog.coderField.value = '';
		
		dialog.title = 'Metadata Editor';
	}
	
	function saveMeta()
	{
		ToolKitUtils.playSfx(CONFIRM);
		
		FileUtil.saveFile(getEncodedMeta(), 'meta.json');
	}
	
	function getEncodedMeta()
	{
		inline function valToStringArray(v:Dynamic, trimToo:Bool = false)
		{
			var str:String = cast v;
			if (str.trim().length < 1) return [];
			
			return [for (value in str.split(',')) trimToo ? value.trim() : value];
		}
		
		var colour:Int = dialog.colourPicker.value;
		
		final meta:SongMetaData =
			{
				displayName: dialog.displayNameField.value,
				difficulties: valToStringArray(dialog.difficultyField.value, true),
				
				freeplayColor: '0x' + colour.hex(),
				freeplayIcon: dialog.iconField.value,
				
				composers: valToStringArray(dialog.composerField.value),
				charters: valToStringArray(dialog.charterfield.value),
				artists: valToStringArray(dialog.artistField.value),
				coders: valToStringArray(dialog.coderField.value),
			}
		return Json.stringify(meta, '\t');
	}
	
	function loadMeta(file:String)
	{
		if (!FunkinAssets.exists(file)) return;
		
		var meta = SongMeta.getFromPath(file);
		
		if (meta == null) return;
		
		ToolKitUtils.playSfx(CONFIRM);
		
		dialog.displayNameField.value = meta.displayName ?? '';
		
		dialog.iconField.changeSilent(meta.freeplayIcon ?? '');
		
		var diffs = '';
		if (meta.difficulties != null) diffs = meta.difficulties.join(',');
		dialog.difficultyField.value = diffs;
		
		// icon business
		final icon = meta.freeplayIcon ?? '';
		
		iconDummy.changeIcon(icon);
		
		final colour = FlxColor.fromString(meta.freeplayColor ?? '');
		
		setIcon(iconDummy.frame, colour);
		
		dialog.colourPicker.value = cast colour ?? FlxColor.WHITE;
		
		dialog.artistField.value = meta.artists?.join(',') ?? '';
		dialog.composerField.value = meta.composers?.join(',') ?? '';
		dialog.charterfield.value = meta.charters?.join(',') ?? '';
		dialog.coderField.value = meta.coders?.join(',') ?? '';
		
		var title =
			{
				var str = 'Editing (';
				if (meta.displayName != null) str += meta.displayName + ') Metadata';
				else str += file.normalize() + ')';
				
				str;
			}
			
		dialog.title = title;
	}
	
	function setIcon(frame:FlxFrame, ?rawColour:FlxColor)
	{
		dialog.iconDisplay.icon = Variant.fromImageData(frame);
		
		if (rawColour != null) updateColour(rawColour);
	}
	
	function updateColour(colour:FlxColor, changeFieldsToo:Bool = false)
	{
		dialog.iconDisplay.backgroundColor = cast FlxColor.interpolate(0xFF3D3F41, colour, 0.1);
		
		if (changeFieldsToo)
		{
			dialog.colourPicker.value = colour;
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		ToolKitUtils.update();
		
		if (ToolKitUtils.currentFocus == null && FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
		{
			if (_song != null)
			{
				//
				
				final file = Paths.getPath('songs/$_song/meta.json', null, true);
				if (FunkinAssets.exists(file))
				{
					FileUtil.saveFileToPath(getEncodedMeta(), file);
					ToolKitUtils.playSfx(CONFIRM);
				}
			}
		}
	}
}
