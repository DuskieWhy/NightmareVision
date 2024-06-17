package meta.data.options;

#if desktop
import meta.data.Discord.DiscordClient;
#end
import openfl.text.TextField;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import openfl.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import openfl.Lib;
import meta.data.*;

using StringTools;

class NoteSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Notes';
		rpcTitle = 'Note Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Note Skin', //Name
			'Changes how notes look. Quants change colour depending on the beat it\'s at, while vanilla is normal FNF', //Description
			'noteSkin', //Save data variable name
			'string', //Variable type
			'Vanilla',
			['Vanilla','Quants', 'QuantStep']
		); //Default value
		addOption(option);

		var option:Option = new Option('Customize',
			'Change your note colours\n[Press Enter]',
			'',
			'button',
			true);
		option.callback = function(){
			switch(ClientPrefs.noteSkin){
				case 'Quants':
					openSubState(new QuantNotesSubState());
				case 'QuantStep':
					openSubState(new QuantNotesSubState());
				default:
					openSubState(new NotesSubState());
			}
		}
		addOption(option);

		/*
		var option:Option = new Option('Persistent Cached Data',
			'If checked, images loaded will stay in memory\nuntil the game is closed, this increases memory usage,\nbut basically makes reloading times instant.',
			'imagesPersist',
			'bool',
			false);
		option.onChange = onChangePersistentData; //Persistent Cached Data changes FlxGraphic.defaultPersist
		addOption(option);
		*/

		super();
	}

}
